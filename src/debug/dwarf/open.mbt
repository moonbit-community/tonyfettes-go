/// Simplified DWARF Data structure implementation
/// This is a minimal working version focusing on the core data structures

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
  contents : @slice.Slice[Byte],
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
pub fn Data::get_section(self : Data, name : Bytes) -> @slice.Slice[Byte] {
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
