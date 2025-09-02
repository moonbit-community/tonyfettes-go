/// DWARF compilation unit parsing and management
/// Ported from Go's debug/dwarf package

///|
/// Full compilation unit structure with all DWARF features
pub struct DwarfUnit {
  base : Offset // byte offset of header within the aggregate info
  off : Offset // byte offset of data within the aggregate info
  data : Bytes
  atable : AbbrevTable
  mut unit5 : Unit5? // info specific to DWARF 5 units
  asize : Int // address size
  vers : Int // DWARF version
  is64 : Bool // True for 64-bit DWARF format
  utype : UInt // DWARF 5 unit type
} derive(Show)

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
pub fn DwarfUnit::new(
  base : Offset,
  off : Offset,
  data : Bytes,
  atable : AbbrevTable,
  asize : Int,
  vers : Int,
  is64 : Bool,
  utype : UInt,
) -> DwarfUnit {
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
pub fn DwarfUnit::version(self : DwarfUnit) -> Int {
  self.vers
}

///|
/// Get DWARF64 format info
pub fn DwarfUnit::dwarf64(self : DwarfUnit) -> (Bool, Bool) {
  (self.is64, true)
}

///|
/// Get address size
pub fn DwarfUnit::addrsize(self : DwarfUnit) -> Int {
  self.asize
}

///|
/// Get address base (DWARF 5)
pub fn DwarfUnit::addr_base(self : DwarfUnit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.addr_base
    None => 0UL
  }
}

///|
/// Get string offsets base (DWARF 5)
pub fn DwarfUnit::str_offsets_base(self : DwarfUnit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.str_offsets_base
    None => 0UL
  }
}

///|
/// Get range lists base (DWARF 5)
pub fn DwarfUnit::rng_lists_base(self : DwarfUnit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.rng_lists_base
    None => 0UL
  }
}

///|
/// Get location lists base (DWARF 5)
pub fn DwarfUnit::loc_lists_base(self : DwarfUnit) -> UInt64 {
  match self.unit5 {
    Some(u5) => u5.loc_lists_base
    None => 0UL
  }
}

///|
/// Get abbreviation table
pub fn DwarfUnit::atable(self : DwarfUnit) -> AbbrevTable {
  self.atable
}

///|
/// Get unit type
pub fn DwarfUnit::utype(self : DwarfUnit) -> UInt {
  self.utype
}

///|
/// Check if 64-bit DWARF
pub fn DwarfUnit::is_dwarf64(self : DwarfUnit) -> Bool {
  self.is64
}

///|
/// Get unit data
pub fn DwarfUnit::data(self : DwarfUnit) -> Bytes {
  self.data
}

///|
/// Get base offset
pub fn DwarfUnit::base(self : DwarfUnit) -> Offset {
  self.base
}

///|
/// Get data offset
pub fn DwarfUnit::off(self : DwarfUnit) -> Offset {
  self.off
}

///|
/// Implement DataFormat for Unit
impl DataFormat for DwarfUnit with version(self) {
  self.vers
}

///|
impl DataFormat for DwarfUnit with dwarf64(self) {
  (self.is64, true)
}

///|
impl DataFormat for DwarfUnit with addrsize(self) {
  self.asize
}

///|
/// Parse compilation units from the .debug_info section
pub fn parse_units(data : Data) -> Result[Array[DwarfUnit], String] {
  // Count units first
  let mut nunit = 0
  let info_data = data.get_section(".debug_info")
  let mut b = make_buf(
    Some(data),
    UnknownFormatRef(UnknownFormat::new()),
    "info",
    0L,
    info_data,
  )
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
  b = make_buf(
    Some(data),
    UnknownFormatRef(UnknownFormat::new()),
    "info",
    0L,
    info_data,
  )
  let units : Array[DwarfUnit] = []
  for _i = 0; _i < nunit; _i = _i + 1 {
    match parse_single_unit(data, b) {
      Ok(unit) => units.push(unit)
      Err(err) => return Err(err)
    }
  }
  Ok(units)
}

///|
/// Parse a single compilation unit
fn parse_single_unit(data : Data, buf : Buf) -> Result[DwarfUnit, String] {
  let u_base = buf.offset()
  let (n, is64) = buf.unit_length()
  if buf.has_error() {
    match buf.get_error() {
      Some(err) => return Err(err.to_string())
      None => return Err("error reading unit length")
    }
  }
  let data_off = buf.offset()
  let vers = buf.uint16().to_int()
  if vers < 2 || vers > 5 {
    return Err("unsupported DWARF version \{vers}")
  }
  let mut utype = 0U
  let mut asize = 0
  if vers >= 5 {
    utype = buf.uint8()
    asize = buf.uint8().reinterpret_as_int()
  }
  let abbrev_off = if is64 { buf.uint64() } else { buf.uint32().to_uint64() }

  // Parse abbreviation table
  let atable = match parse_abbrev(data, abbrev_off, vers) {
    Ok(table) => table
    Err(err) => return Err(err)
  }
  if vers < 5 {
    asize = buf.uint8().reinterpret_as_int()
  }

  // Handle DWARF 5 unit types
  match utype {
    0x04U | 0x05U => { // utSkeleton, utSplitCompile
      let _unit_id = buf.uint64()
      // unit ID
    }
    0x02U | 0x06U => { // utType, utSplitType
      let _type_sig = buf.uint64() // type signature
      if is64 {
        let _type_off = buf.uint64()
        // type offset
      } else {
        let _type_off = buf.uint32()
        // type offset
      }
    }
    _ => () // other types don't need special handling
  }
  let u_off = buf.offset()
  let u_data = buf.bytes((n - (buf.offset() - data_off)).to_int())
  if buf.has_error() {
    match buf.get_error() {
      Some(err) => return Err(err.to_string())
      None => return Err("error reading unit data")
    }
  }
  let unit = DwarfUnit::new(
    u_base, u_off, u_data, atable, asize, vers, is64, utype,
  )

  // Collect DWARF 5 base offsets if needed
  if vers >= 5 {
    match collect_dwarf5_base_offsets(data, unit) {
      Ok(updated_unit) => Ok(updated_unit)
      Err(err) => Err(err)
    }
  } else {
    Ok(unit)
  }
}

///|
/// Collect DWARF 5 base offsets from compilation unit
fn collect_dwarf5_base_offsets(
  data : Data,
  unit : DwarfUnit,
) -> Result[DwarfUnit, String] {
  if unit.vers < 5 {
    return Ok(unit)
  }
  let updated_unit = unit
  updated_unit.unit5 = Some(Unit5::new())
  let b = make_buf(
    Some(data),
    DataFormatRefFromUnit(UnitFormat(updated_unit)),
    "info",
    updated_unit.off,
    updated_unit.data,
  )

  // Parse the compilation unit entry to get base offsets
  let cu = parse_entry(
    b,
    None,
    SimpleUnit::from_unit(updated_unit),
    updated_unit.atable,
  )
  if b.has_error() {
    match b.get_error() {
      Some(err) => return Err(err.to_string())
      None => return Err("error parsing compilation unit entry")
    }
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

///|
/// Create DataFormatRef from Unit
pub enum DataFormatRefFromUnit {
  UnitFormat(DwarfUnit)
} derive(Show)

///|
/// Implement DataFormat for DataFormatRefFromUnit
impl DataFormat for DataFormatRefFromUnit with version(self) {
  match self {
    UnitFormat(unit) => unit.vers
  }
}

///|
impl DataFormat for DataFormatRefFromUnit with dwarf64(self) {
  match self {
    UnitFormat(unit) => (unit.is64, true)
  }
}

///|
impl DataFormat for DataFormatRefFromUnit with addrsize(self) {
  match self {
    UnitFormat(unit) => unit.asize
  }
}

///|
/// Convert Unit to SimpleUnit (for compatibility)
pub fn SimpleUnit::from_unit(unit : DwarfUnit) -> SimpleUnit {
  SimpleUnit::new(
    unit.base,
    unit.off,
    unit.data,
    unit.asize,
    unit.vers,
    unit.is64,
  )
}

///|
/// Find the unit that contains the given offset
pub fn find_unit_by_offset(units : Array[DwarfUnit], off : Offset) -> Int {
  // Find the unit after off
  let mut next = units.length()
  for i = 0; i < units.length(); i = i + 1 {
    if units[i].off > off {
      next = i
      break
    }
  }
  if next == 0 {
    return -1
  }
  let u = units[next - 1]
  if u.off <= off && off < u.off + Int64::from_int(u.data.length()) {
    next - 1
  } else {
    -1
  }
}

///|
/// Update Data with parsed units
pub fn Data::set_units(self : Data, units : Array[DwarfUnit]) -> Unit {
  // For now this is a no-op since we don't store units in Data
  // In a full implementation, we'd add a units field to Data
}

///|
/// Create a reader with fully parsed units
pub fn Data::reader_with_parsed_units(self : Data) -> Result[Reader, String] {
  match parse_units(self) {
    Ok(units) => {
      // Convert Units to SimpleUnits for Reader
      let simple_units : Array[SimpleUnit] = []
      for unit in units {
        simple_units.push(SimpleUnit::from_unit(unit))
      }
      Ok(Reader::new(self, simple_units))
    }
    Err(err) => Err(err)
  }
}
