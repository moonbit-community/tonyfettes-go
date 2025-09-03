/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// DWARF debug info is split into a sequence of compilation units.
/// Each unit has its own abbreviation table and address size.

///|
priv struct Unit {
  mut base : Offset // byte offset of header within the aggregate info
  mut off : Offset // byte offset of data within the aggregate info
  mut data : @slice.Slice[Byte]
  mut atable : AbbrevTable
  mut unit5 : Unit5? // info specific to DWARF 5 units
  mut asize : Int
  mut vers : Int
  mut is64 : Bool // True for 64-bit DWARF format
  mut utype : UInt // DWARF 5 unit type
}

///|
impl Default for Unit with default() -> Unit {
  Unit::new(0, 0, @slice.new(), AbbrevTable::new(), 0, 0, false, 0U)
}

///|
priv struct Unit5 {
  mut addr_base : UInt64
  mut str_offsets_base : UInt64
  mut rng_lists_base : UInt64
  mut loc_lists_base : UInt64
}

///|
impl Default for Unit5 with default() -> Unit5 {
  Unit5::{
    addr_base: 0,
    str_offsets_base: 0,
    rng_lists_base: 0,
    loc_lists_base: 0,
  }
}

///|
fn Unit::new(
  base : Offset,
  off : Offset,
  data : @slice.Slice[Byte],
  atable : AbbrevTable,
  asize : Int,
  vers : Int,
  is64 : Bool,
  utype : UInt,
) -> Unit {
  { base, off, data, atable, unit5: None, asize, vers, is64, utype }
}

///|
fn Unit::addr_base(u : Unit) -> UInt64 {
  match u.unit5 {
    Some(u5) => u5.addr_base
    None => 0
  }
}

///|
/// Get string offsets base (DWARF 5)
fn Unit::str_offsets_base(self : Unit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.str_offsets_base
    None => 0
  }
}

///|
/// Get range lists base (DWARF 5)
fn Unit::rng_lists_base(self : Unit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.rng_lists_base
    None => 0
  }
}

///|
/// Get location lists base (DWARF 5)
fn Unit::loc_lists_base(self : Unit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.loc_lists_base
    None => 0
  }
}

///|
impl DataFormat for Unit with version(self) {
  self.vers
}

///|
impl DataFormat for Unit with dwarf64(self) {
  (self.is64, true)
}

///|
impl DataFormat for Unit with addrsize(self) {
  self.asize
}

///|
priv suberror UnsupportedDwarfVersion UInt

///|
/// Parse compilation units from the .debug_info section
fn Data::parse_units(d : Data) -> FixedArray[Unit] raise {
  // Count units first
  let mut nunit = 0
  let mut b = make_buf(d, UnknownFormat::new(), "info", 0, d.info)
  while b.length() > 0 {
    let (len, _) = b.unit_length()
    if len < 0 {
      raise b.error("unit length overflow")
    }
    b.skip(len.reinterpret_as_int())
    if len > 0 {
      nunit += 1
    }
  }
  if b.err is Some(err) {
    raise err
  }

  // Again, this time writing them down.
  b = make_buf(d, UnknownFormat::new(), "info", 0, d.info)
  let units = FixedArray::makei(nunit, _ => Unit::default())
  for i in 0..<nunit {
    let u = units[i]
    u.base = b.off
    if b.err is Some(err) {
      raise err
    }
    let mut n : Offset = 0
    while n == 0 {
      let (n_n, n_is64) = b.unit_length()
      n = n_n
      u.is64 = n_is64
    }
    let data_off = b.off
    let vers = b.uint16()
    if vers < 2 || vers > 5 {
      raise UnsupportedDwarfVersion(vers)
    }
    u.vers = vers.reinterpret_as_int()
    if vers >= 5 {
      u.utype = b.uint8()
      u.asize = b.uint8().reinterpret_as_int()
    }
    let mut abbrev_off : UInt64 = 0
    if u.is64 {
      abbrev_off = b.uint64()
    } else {
      abbrev_off = b.uint32().to_uint64()
    }
    u.atable = d.parse_abbrev(abbrev_off, u.vers)
    if vers < 5 {
      u.asize = b.uint8().reinterpret_as_int()
    }
    match u.utype {
      UtSkeleton | UtSplitCompile => ignore(b.uint64())
      UtType | UtSplitType => {
        ignore(b.uint64())
        if u.is64 {
          ignore(b.uint64())
        } else {
          ignore(b.uint32())
        }
      }
      _ => ()
    }
    u.off = b.off
    u.data = b.bytes((n - (b.off - data_off)).reinterpret_as_int())
  }
  units
}

///|
/// offsetToUnit returns the index of the unit containing offset off.
/// It returns -1 if no unit contains this offset.
fn Data::offset_to_unit(self : Data, off : Offset) -> Int {
  // Find the unit after off using binary search
  let mut left = 0
  let mut right = self.unit.length()
  while left < right {
    let mid = (left + right) / 2
    if self.unit[mid].off > off {
      right = mid
    } else {
      left = mid + 1
    }
  }
  if left == 0 {
    return -1
  }
  let u = self.unit[left - 1]
  if u.off <= off && off < u.off + u.data.length().reinterpret_as_uint() {
    return left - 1
  }
  -1
}

///|
/// Collect DWARF 5 base offsets from compilation unit
fn Data::collect_dwarf5_base_offsets(d : Data, u : Unit) -> @unit.T raise {
  guard u.unit5 is Some(u5) else {
    abort("expected unit5 to be set up already")
  }
  let b = make_buf(d, u, "info", u.off, u.data)
  let cu = b.entry(None, u)
  guard cu is Some(cu) else {
    // Unknown abbreviation table entry or some other fatal
    // problem; bail early on the assumption that this will be
    // detected at some later point.
    raise b.error("failed to parse compilation unit entry")
  }
  // Extract base offsets from compilation unit attributes
  if cu.val(AttrAddrBase) is Some(Int64(addr_base)) {
    u5.addr_base = addr_base.reinterpret_as_uint64()
  }
  if cu.val(AttrStrOffsetsBase) is Some(Int64(str_base)) {
    u5.str_offsets_base = str_base.reinterpret_as_uint64()
  }
  if cu.val(AttrRnglistsBase) is Some(Int64(rng_base)) {
    u5.rng_lists_base = rng_base.reinterpret_as_uint64()
  }
  if cu.val(AttrLoclistsBase) is Some(Int64(loc_base)) {
    u5.loc_lists_base = loc_base.reinterpret_as_uint64()
  }
}
