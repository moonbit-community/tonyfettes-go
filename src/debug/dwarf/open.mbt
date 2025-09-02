/// Simplified DWARF Data structure implementation
/// This is a minimal working version focusing on the core data structures

///|
/// Data represents the DWARF debugging information
/// loaded from an executable file (for example, an ELF or Mach-O executable).
struct Data {
  // raw data
  abbrev : @slice.Slice[Byte]
  aranges : Bytes
  frame : Bytes
  info : Bytes
  line : Bytes
  pubnames : Bytes
  ranges : Bytes
  str : Bytes

  // New sections added in DWARF 5
  mut addr : Bytes
  mut line_str : Bytes
  mut str_offsets : Bytes
  mut rng_lists : Bytes

  // parsed data
  abbrev_cache : Map[UInt64, AbbrevTable]
  big_endian : Bool
  order : ByteOrder
  type_cache : Map[Offset, &Type]
  // type_sigs : Map[UInt64, &Type]
  unit : Array[Unit_]
}

///|
/// Check if data is big endian
pub fn Data::is_big_endian(self : Data) -> Bool {
  self.big_endian
}

///|
/// Add a DWARF 5 section
pub fn Data::add_section_simple(
  self : Data,
  name : Bytes,
  contents : Bytes,
) -> Bool {
  match name {
    ".debug_addr" => {
      self.addr = contents
      true
    }
    ".debug_line_str" => {
      self.line_str = contents
      true
    }
    ".debug_str_offsets" => {
      self.str_offsets = contents
      true
    }
    ".debug_rnglists" => {
      self.rng_lists = contents
      true
    }
    _ => false // Unknown section
  }
}

///|
/// Get a section by name
pub fn Data::get_section(self : Data, name : Bytes) -> Bytes {
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
    _ => b"" // Unknown section
  }
}

///|
/// Simple unit structure for parsing
pub struct SimpleUnit {
  base : Offset
  off : Offset
  data : Bytes
  asize : Int
  vers : Int
  is64 : Bool
} derive(Show)

///|
/// Create a new SimpleUnit
pub fn SimpleUnit::new(
  base : Offset,
  off : Offset,
  data : Bytes,
  asize : Int,
  vers : Int,
  is64 : Bool,
) -> SimpleUnit {
  { base, off, data, asize, vers, is64 }
}

///|
/// Get version
pub fn SimpleUnit::version(self : SimpleUnit) -> Int {
  self.vers
}

///|
/// Get address size
pub fn SimpleUnit::addrsize(self : SimpleUnit) -> Int {
  self.asize
}

///|
/// Check if 64-bit DWARF
pub fn SimpleUnit::is_dwarf64(self : SimpleUnit) -> Bool {
  self.is64
}

/// Abbrev types are defined in abbrev.mbt

///|
/// Get from abbreviation cache
pub fn Data::get_abbrev_cache(self : Data, off : UInt64) -> AbbrevTable? {
  self.abbrev_cache.get(off)
}

///|
/// Set in abbreviation cache
pub fn Data::set_abbrev_cache(
  self : Data,
  off : UInt64,
  table : AbbrevTable,
) -> Unit {
  self.abbrev_cache.set(off, table)
}
