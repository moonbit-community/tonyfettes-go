/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// Package dwarf provides access to DWARF debugging information loaded from
/// executable files, as defined in the DWARF 2.0 Standard at
/// http://dwarfstd.org/doc/dwarf-2.0.0.pdf.
///
/// Security
///
/// This package is not designed to be hardened against adversarial inputs, and is
/// outside the scope of https://go.dev/security/policy. In particular, only basic
/// validation is done when parsing object files. As such, care should be taken when
/// parsing untrusted inputs, as parsing malformed files may consume significant
/// resources, or cause panics.

///|
priv suberror SegmentSelectorError String

///|
/// Data represents the DWARF debugging information
/// loaded from an executable file (for example, an ELF or Mach-O executable).
struct Data {
  // raw data
  abbrev : @slice.Slice[Byte]
  aranges : @slice.Slice[Byte]
  frame : @slice.Slice[Byte]
  info : @slice.Slice[Byte]
  line : @slice.Slice[Byte]
  pubnames : @slice.Slice[Byte]
  ranges : @slice.Slice[Byte]
  str : @slice.Slice[Byte]

  // New sections added in DWARF 5
  mut addr : @slice.Slice[Byte]
  mut line_str : @slice.Slice[Byte]
  mut str_offsets : @slice.Slice[Byte]
  mut rng_lists : @slice.Slice[Byte]

  // parsed data
  abbrev_cache : Map[UInt64, AbbrevTable]
  mut big_endian : Bool
  mut order : ByteOrder
  type_cache : Map[Offset, Type]
  type_sigs : Map[UInt64, TypeUnit]
  mut unit : FixedArray[Unit]
}

///|
/// New returns a new Data object initialized from the given parameters.
/// Rather than calling this function directly, clients should typically use
/// the DWARF method of the File type of the appropriate package debug/elf,
/// debug/macho, or debug/pe.
///
/// The @slice.Slice[Byte] arguments are the data from the corresponding debug section
/// in the object file; for example, for an ELF object, abbrev is the contents of
/// the ".debug_abbrev" section.
pub fn new(
  abbrev~ : @slice.Slice[Byte],
  aranges~ : @slice.Slice[Byte],
  frame~ : @slice.Slice[Byte],
  info~ : @slice.Slice[Byte],
  line~ : @slice.Slice[Byte],
  pubnames~ : @slice.Slice[Byte],
  ranges~ : @slice.Slice[Byte],
  str~ : @slice.Slice[Byte],
) -> Data raise {
  let d = Data::{
    abbrev,
    aranges,
    frame,
    info,
    line,
    pubnames,
    ranges,
    str,
    addr: @slice.new(),
    line_str: @slice.new(),
    str_offsets: @slice.new(),
    rng_lists: @slice.new(),
    abbrev_cache: {},
    big_endian: false,
    order: LittleEndian,
    type_cache: {},
    type_sigs: {},
    unit: [],
  }

  // Sniff .debug_info to figure out byte order.
  // 32-bit DWARF: 4 byte length, 2 byte version.
  // 64-bit DWARF: 4 bytes of 0xff, 8 byte length, 2 byte version.
  if d.info.length() < 6 {
    raise DecodeError::new(
      "info",
      d.info.length().reinterpret_as_uint(),
      "too short",
    )
  }
  let mut offset = 4
  if d.info[0].to_uint() == 0xffU &&
    d.info[1].to_uint() == 0xffU &&
    d.info[2].to_uint() == 0xffU &&
    d.info[3].to_uint() == 0xffU {
    if d.info.length() < 14 {
      raise DecodeError::new(
        "info",
        d.info.length().reinterpret_as_uint(),
        "too short",
      )
    }
    offset = 12
  }

  // Fetch the version, a tiny 16-bit number (1, 2, 3, 4, 5).
  let x = d.info[offset]
  let y = d.info[offset + 1]
  match (x.to_uint(), y.to_uint()) {
    (0U, 0U) => raise DecodeError::new("info", 4, "unsupported version 0")
    (0U, _) => {
      d.big_endian = true
      d.order = BigEndian
    }
    (_, 0U) => {
      d.big_endian = false
      d.order = LittleEndian
    }
    _ => raise DecodeError::new("info", 4, "cannot determine byte order")
  }
  let u = d.parse_units()
  d.unit = u
  d
}

///|
/// AddTypes will add one .debug_types section to the DWARF data. A
/// typical object with DWARF version 4 debug info will have multiple
/// .debug_types sections. The name is used for error reporting only,
/// and serves to distinguish one .debug_types section from another.
pub fn Data::add_types(
  self : Data,
  name : String,
  types : @slice.Slice[Byte],
) -> @unit.T {
  self.parse_types(name, types)
}

///|
/// AddSection adds another DWARF section by name. The name should be a
/// DWARF section name such as ".debug_addr", ".debug_str_offsets", and
/// so forth. This approach is used for new DWARF sections added in
/// DWARF 5 and later.
pub fn Data::add_section(
  self : Data,
  name : String,
  contents : @slice.Slice[Byte],
) -> @unit.T {
  match name {
    ".debug_addr" => self.addr = contents
    ".debug_line_str" => self.line_str = contents
    ".debug_str_offsets" => self.str_offsets = contents
    ".debug_rnglists" => self.rng_lists = contents
    _ => () // Just ignore names that we don't yet support.
  }
}

///|
/// Check if data is big endian
pub fn Data::is_big_endian(self : Data) -> Bool {
  self.big_endian
}

///|
/// Get a section by name
pub fn Data::get_section(self : Data, name : String) -> @slice.Slice[Byte] {
  match name {
    ".debug_abbrev" => self.abbrev
    ".debug_aranges" => self.aranges
    ".debug_frame" => self.frame
    ".debug_info" => self.info
    ".debug_line" => self.line
    ".debug_pubnames" => self.pubnames
    ".debug_ranges" => self.ranges
    ".debug_str" => self.str
    ".debug_addr" => self.addr
    ".debug_line_str" => self.line_str
    ".debug_str_offsets" => self.str_offsets
    ".debug_rnglists" => self.rng_lists
    _ => @slice.new() // Unknown section
  }
}

///|
/// Parse type units from debug_types section
fn Data::parse_types(
  self : Data,
  name : String,
  types : @slice.Slice[Byte],
) -> @unit.T {
  // For now, this is a placeholder implementation
  // TODO: Implement proper type unit parsing
}

///|
/// Ranges returns the PC ranges covered by e, a slice of [low,high) pairs.
/// Only some entry types, such as TagCompileUnit or TagSubprogram, have PC
/// ranges; for others, this will return nil with no error.
pub fn Data::ranges(d : Data, e : Entry) -> Array[(UInt64, UInt64)] raise {
  let ret : Array[(UInt64, UInt64)] = []
  let low_ok = match e.val(AttrLowpc) {
    Some(UInt64(low)) => Some(low)
    _ => None
  }
  let mut high_ok : UInt64? = None
  match e.attr_field(AttrHighpc) {
    Some(high_field) =>
      match high_field.class {
        ClassAddress =>
          match high_field.val {
            UInt64(high) => high_ok = Some(high)
            _ => ()
          }
        ClassConstant =>
          match (low_ok, high_field.val) {
            (Some(low), Int64(off)) =>
              if off >= 0L {
                high_ok = Some(low + off.reinterpret_as_uint64())
              }
            _ => ()
          }
        _ => ()
      }
    None => ()
  }
  match (low_ok, high_ok) {
    (Some(low), Some(high)) => ret.push((low, high))
    _ => ()
  }
  let mut u : Unit? = None
  let uidx = d.offset_to_unit(e.offset)
  if uidx >= 0 && uidx < d.unit.length() {
    u = Some(d.unit[uidx])
  }
  match u {
    Some(unit) =>
      if unit.vers >= 5 && d.rng_lists.length() > 0 {
        // DWARF version 5 and later
        match e.attr_field(AttrRanges) {
          Some(field) =>
            match field.class {
              ClassRangeListPtr =>
                match field.val {
                  Int64(ranges) => {
                    let (cu, base) = d.base_address_for_entry(e)
                    let dwarf5_ranges = d.dwarf5_ranges(unit, cu, base, ranges)
                    for range in dwarf5_ranges {
                      ret.push(range)
                    }
                  }
                  _ => ()
                }
              ClassRngList =>
                match field.val {
                  UInt64(rnglist) => {
                    let (cu, base) = d.base_address_for_entry(e)
                    let dwarf5_ranges = d.dwarf5_ranges(
                      unit,
                      cu,
                      base,
                      rnglist.reinterpret_as_int64(),
                    )
                    for range in dwarf5_ranges {
                      ret.push(range)
                    }
                  }
                  _ => ()
                }
              _ => ()
            }
          None => ()
        }
      } else {
        // DWARF version 2 through 4
        match e.val(AttrRanges) {
          Some(Int64(ranges)) =>
            if d.ranges.length() > 0 {
              let (_, base) = d.base_address_for_entry(e)
              let dwarf2_ranges = d.dwarf2_ranges(unit, base, ranges)
              for range in dwarf2_ranges {
                ret.push(range)
              }
            }
          _ => ()
        }
      }
    None => ()
  }
  ret
}

///|
/// Get a new reader for this Data
pub fn Data::reader(self : Data) -> Reader raise {
  let r = Reader::{
    b: Buf::{
      dwarf: None,
      order: LittleEndian,
      format: UnknownFormat::new(),
      name: "",
      off: 0,
      data: @slice.new(),
      err: None,
    },
    d: self,
    err: None,
    unit: 0,
    last_unit: false,
    last_children: false,
    last_sibling: 0,
    cu: None,
  }
  r.seek(0)
  r
}

///|
/// baseAddressForEntry returns the initial base address to be used when
/// looking up the range list of entry e.
/// DWARF specifies that this should be the lowpc attribute of the enclosing
/// compilation unit, however comments in gdb/dwarf2read.c say that some
/// versions of GCC use the entrypc attribute, so we check that too.
fn Data::base_address_for_entry(d : Data, e : Entry) -> (Entry?, UInt64) raise {
  let mut cu : Entry? = None
  if e.tag == TagCompileUnit {
    cu = Some(e)
  } else {
    let i = d.offset_to_unit(e.offset)
    if i == -1 {
      raise DecodeError::new("ranges", e.offset, "no unit for entry")
    }
    let u = d.unit[i]
    let b = make_buf(Some(d), u, "info", u.off, u.data)
    match b.entry(None, u) {
      Some(entry) => cu = Some(entry)
      None =>
        match b.err {
          Some(err) => raise err
          None =>
            raise DecodeError::new("ranges", e.offset, "failed to parse CU")
        }
    }
  }
  match cu {
    Some(cu_entry) =>
      match cu_entry.val(AttrEntrypc) {
        Some(UInt64(entry_pc)) => (Some(cu_entry), entry_pc)
        _ =>
          match cu_entry.val(AttrLowpc) {
            Some(UInt64(low_pc)) => (Some(cu_entry), low_pc)
            _ => (Some(cu_entry), 0UL)
          }
      }
    None => (None, 0UL)
  }
}

///|
/// DWARF 2-4 ranges parsing
fn Data::dwarf2_ranges(
  d : Data,
  u : Unit,
  base : UInt64,
  ranges : Int64,
) -> Array[(UInt64, UInt64)] raise {
  if ranges < 0L || ranges.to_int() > d.ranges.length() {
    raise DecodeError::new(
      "ranges",
      ranges.to_int().reinterpret_as_uint(),
      "invalid range offset \{ranges} (max \{d.ranges.length()})",
    )
  }
  let buf = make_buf(
    Some(d),
    u,
    "ranges",
    ranges.to_int().reinterpret_as_uint(),
    d.ranges[ranges.to_int():],
  )
  let ret : Array[(UInt64, UInt64)] = []
  let mut current_base = base
  while buf.length() > 0 {
    let low = buf.addr()
    let high = buf.addr()
    if low == 0UL && high == 0UL {
      break
    }

    // Check for base address selection entry
    let mask = (1UL << (u.asize * 8)) - 1UL
    if low == mask {
      current_base = high
    } else {
      ret.push((current_base + low, current_base + high))
    }
  }
  ret
}

///|
/// DWARF 5 ranges parsing
fn Data::dwarf5_ranges(
  d : Data,
  u : Unit,
  cu : Entry?,
  base : UInt64,
  ranges : Int64,
) -> Array[(UInt64, UInt64)] raise {
  if ranges < 0L || ranges.to_int() > d.rng_lists.length() {
    raise DecodeError::new(
      "rnglists",
      ranges.to_int().reinterpret_as_uint(),
      "invalid rnglist offset \{ranges} (max \{d.rng_lists.length()})",
    )
  }
  let mut addr_base : Int64 = 0L
  match cu {
    Some(cu_entry) =>
      match cu_entry.val(AttrAddrBase) {
        Some(Int64(ab)) => addr_base = ab
        _ => ()
      }
    None => ()
  }
  let buf = make_buf(Some(d), u, "rnglists", 0, d.rng_lists)
  buf.skip(ranges.to_int())
  let ret : Array[(UInt64, UInt64)] = []
  let mut current_base = base
  while true {
    let opcode = buf.uint8()
    match opcode {
      0U => break // RleEndOfList
      1U => { // RleBaseAddressx
        let base_idx = buf.uint()
        current_base = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          base_idx,
        )
      }
      2U => { // RleStartxEndx
        let start_idx = buf.uint()
        let end_idx = buf.uint()
        let start = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          start_idx,
        )
        let end = d.debug_addr(u, addr_base.reinterpret_as_uint64(), end_idx)
        ret.push((start, end))
      }
      3U => { // RleStartxLength
        let start_idx = buf.uint()
        let len = buf.uint()
        let start = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          start_idx,
        )
        ret.push((start, start + len))
      }
      4U => { // RleOffsetPair
        let off1 = buf.uint()
        let off2 = buf.uint()
        ret.push((current_base + off1, current_base + off2))
      }
      5U => // RleBaseAddress
        current_base = buf.addr()
      6U => { // RleStartEnd
        let start = buf.addr()
        let end = buf.addr()
        ret.push((start, end))
      }
      7U => { // RleStartLength
        let start = buf.addr()
        let len = buf.uint()
        ret.push((start, start + len))
      }
      _ => break // Unknown opcode
    }
  }
  ret
}

///|
/// debugAddr returns the address at idx in debug_addr
fn Data::debug_addr(
  d : Data,
  format : Unit,
  addr_base : UInt64,
  idx : UInt64,
) -> UInt64 raise {
  let off = idx * format.asize.to_uint64() + addr_base
  if off.to_int() < 0 {
    raise DecodeError::new("addr", 0, "offset out of range")
  }
  let b = make_buf(Some(d), format, "addr", 0, d.addr)
  b.skip(off.to_int())
  let val = b.addr()
  match b.err {
    Some(err) => raise err
    None => val
  }
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
