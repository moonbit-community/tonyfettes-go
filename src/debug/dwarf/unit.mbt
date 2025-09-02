/// DWARF compilation unit parsing and management
/// Ported from Go's debug/dwarf package

///|
/// Full compilation unit structure with all DWARF features
priv struct Unit_ {
  mut base : Offset // byte offset of header within the aggregate info
  mut off : Offset // byte offset of data within the aggregate info
  mut data : @slice.Slice[Byte]
  mut atable : AbbrevTable
  unit5 : Unit5? // info specific to DWARF 5 units
  mut asize : Int // address size
  mut vers : Int // DWARF version
  mut is64 : Bool // True for 64-bit DWARF format
  mut utype : UInt // DWARF 5 unit type
}

///|
impl Default for Unit_ with default() -> Unit_ {
  Unit_::new(0L, 0L, @slice.new(), AbbrevTable::new(), 0, 0, false, 0U)
}

///|
/// DWARF 5 specific unit information
pub struct Unit5 {
  mut addr_base : UInt64
  mut str_offsets_base : UInt64
  mut rng_lists_base : UInt64
  mut loc_lists_base : UInt64
} derive(Show)

///|
/// Create a new Unit
fn Unit_::new(
  base : Offset,
  off : Offset,
  data : @slice.Slice[Byte],
  atable : AbbrevTable,
  asize : Int,
  vers : Int,
  is64 : Bool,
  utype : UInt,
) -> Unit_ {
  { base, off, data, atable, unit5: None, asize, vers, is64, utype }
}

///|
/// Create a new Unit5
pub fn Unit5::new() -> Unit5 {
  {
    addr_base: 0UL,
    str_offsets_base: 0UL,
    rng_lists_base: 0UL,
    loc_lists_base: 0UL,
  }
}

///|
/// Get the DWARF version
fn Unit_::version(self : Unit_) -> Int {
  self.vers
}

///|
/// Get DWARF64 format info
fn Unit_::dwarf64(self : Unit_) -> (Bool, Bool) {
  (self.is64, true)
}

///|
/// Get address size
fn Unit_::addrsize(self : Unit_) -> Int {
  self.asize
}

///|
/// Get address base (DWARF 5)
fn Unit_::addr_base(self : Unit_) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.addr_base
    None => 0UL
  }
}

///|
/// Get string offsets base (DWARF 5)
fn Unit_::str_offsets_base(self : Unit_) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.str_offsets_base
    None => 0UL
  }
}

///|
/// Get range lists base (DWARF 5)
fn Unit_::rng_lists_base(self : Unit_) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.rng_lists_base
    None => 0UL
  }
}

///|
/// Get location lists base (DWARF 5)
fn Unit_::loc_lists_base(self : Unit_) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.loc_lists_base
    None => 0UL
  }
}

///|
/// Get abbreviation table
fn Unit_::atable(self : Unit_) -> AbbrevTable {
  self.atable
}

///|
/// Get unit type
fn Unit_::utype(self : Unit_) -> UInt {
  self.utype
}

///|
/// Check if 64-bit DWARF
fn Unit_::is_dwarf64(self : Unit_) -> Bool {
  self.is64
}

///|
/// Implement DataFormat for Unit
impl DataFormat for Unit_ with version(self) {
  self.vers
}

///|
impl DataFormat for Unit_ with dwarf64(self) {
  (self.is64, true)
}

///|
impl DataFormat for Unit_ with addrsize(self) {
  self.asize
}

///|
/// Parse compilation units from the .debug_info section
fn Data::parse_units(d : Data) -> FixedArray[Unit_] raise {
  // Count units first
  let mut nunit = 0
  let mut b = make_buf(Some(d), UnknownFormat::new(), "info", 0L, d.info)
  while b.length() > 0 {
    let (len, _) = b.unit_length()
    if len < 0L {
      raise b.error("unit length overflow")
    }
    b.skip(len.to_int())
    if len > 0L {
      nunit += 1
    }
  }
  if b.err is Some(err) {
    raise err
  }

  // Again, this time writing them down.
  b = make_buf(Some(d), UnknownFormat::new(), "info", 0L, d.info)
  let units = FixedArray::makei(nunit, _ => Unit_::default())
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
      raise b.error("unsupported DWARF version \{vers}")
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
    u.data = b.bytes((n - (b.off - data_off)).to_int())
  }
  units
}

///|
/// Collect DWARF 5 base offsets from compilation unit
fn collect_dwarf5_base_offsets(d : Data, u : Unit_) -> Unit raise {
  guard u.unit5 is Some(u5) else {
    abort("expected unit5 to be set up already")
  }
  let b = make_buf(Some(d), u, "info", u.off, u.data)
  let cu = b.entry(None, u)
  guard cu is Some(cu) else {
    // Unknown abbreviation table entry or some other fatal
    // problem; bail early on the assumption that this will be
    // detected at some later point.
    raise b.error("failed to parse compilation unit entry")
  }
  // Extract base offsets from compilation unit attributes
  if cu.val(AttrAddrBase) is Some(VInt64(addr_base)) {
    u5.addr_base = addr_base.reinterpret_as_uint64()
  }
  if cu.val(AttrStrOffsetsBase) is Some(VInt64(str_base)) {
    u5.str_offsets_base = str_base.reinterpret_as_uint64()
  }
  if cu.val(AttrRnglistsBase) is Some(VInt64(rng_base)) {
    u5.rng_lists_base = rng_base.reinterpret_as_uint64()
  }
  if cu.val(AttrLoclistsBase) is Some(VInt64(loc_base)) {
    u5.loc_lists_base = loc_base.reinterpret_as_uint64()
  }
}
