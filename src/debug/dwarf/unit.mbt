/// DWARF compilation unit parsing and management
/// Ported from Go's debug/dwarf package

///|
/// Full compilation unit structure with all DWARF features
priv struct Unit_ {
  base : Offset // byte offset of header within the aggregate info
  off : Offset // byte offset of data within the aggregate info
  data : @slice.Slice[Byte]
  atable : AbbrevTable
  mut unit5 : Unit5? // info specific to DWARF 5 units
  asize : Int // address size
  vers : Int // DWARF version
  is64 : Bool // True for 64-bit DWARF format
  utype : UInt // DWARF 5 unit type
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
fn parse_units(data : Data) -> Result[Array[Unit_], String] {
  // Count units first
  let mut nunit = 0
  let info_data = data.get_section(".debug_info")
  let mut b = make_buf(Some(data), UnknownFormat::new(), "info", 0L, info_data)
  while b.length() > 0 {
    let (len, _) = b.unit_length()
    if len < 0L {
      return Err("unit length overflow")
    }
    b.skip(len.to_int())
    if len > 0L {
      nunit = nunit + 1
    }
  }
  if b.has_error() {
    match b.get_error() {
      Some(err) => return Err(err.to_string())
      None => return Err("unknown error parsing units")
    }
  }

  // Parse the units
  b = make_buf(Some(data), UnknownFormat::new(), "info", 0L, info_data)
  let units : Array[Unit_] = []
  for _i = 0; _i < nunit; _i = _i + 1 {
    match parse_single_unit(data, b) {
      Ok(unit) => units.push(unit)
      Err(err) => return Err(err)
    }
  }
  Ok(units)
}

///|
/// Collect DWARF 5 base offsets from compilation unit
fn collect_dwarf5_base_offsets(d : Data, u : Unit_) -> Unit raise {
  if u.unit5 is None {
    abort("expected unit5 to be set up already")
  }
  let b = make_buf(Some(d), u, "info", u.off, u.data)
  let cu = b.entry(None, u)
  if cu is None && b.err is Some(err) {
    // Unknown abbreviation table entry or some other fatal
    // problem; bail early on the assumption that this will be
    // detected at some later point.
    raise err
  }
  match cu {
    Some(entry) => {
      match updated_unit.unit5 {
        Some(u5) => {
          // Extract base offsets from compilation unit attributes
          match entry.val(AttrAddrBase) {
            Some(VInt64(addr_base)) => u5.addr_base = addr_base.to_uint64()
            _ => ()
          }
          match entry.val(AttrStrOffsetsBase) {
            Some(VInt64(str_base)) => u5.str_offsets_base = str_base.to_uint64()
            _ => ()
          }
          match entry.val(AttrRnglistsBase) {
            Some(VInt64(rng_base)) => u5.rng_lists_base = rng_base.to_uint64()
            _ => ()
          }
          match entry.val(AttrLoclistsBase) {
            Some(VInt64(loc_base)) => u5.loc_lists_base = loc_base.to_uint64()
            _ => ()
          }
        }
        None => () // Should not happen
      }
      Ok(updated_unit)
    }
    None => Err("failed to parse compilation unit entry")
  }
}
