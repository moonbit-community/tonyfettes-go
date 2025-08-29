/// Simplified DWARF Data structure implementation
/// This is a minimal working version focusing on the core data structures

///|
/// Data represents the DWARF debugging information
/// loaded from an executable file
pub struct Data {
  // Raw data sections
  abbrev : Bytes
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

  // Metadata
  big_endian : Bool
  order : ByteOrder
} derive(Show)

///|
/// Create a new minimal Data object
pub fn Data::new_minimal(abbrev : Bytes, info : Bytes, str : Bytes) -> Data? {
  // Sniff .debug_info to figure out byte order
  if info.length() < 6 {
    return None
  }
  let mut offset = 4
  if info[0] == 0xff && info[1] == 0xff && info[2] == 0xff && info[3] == 0xff {
    if info.length() < 14 {
      return None
    }
    offset = 12
  }

  // Fetch the version bytes
  let x = info[offset]
  let y = info[offset + 1]
  let (big_endian, order) = match (x, y) {
    (0, 0) => return None // unsupported version 0
    (0, _) => (true, BigEndian)
    (_, 0) => (false, LittleEndian)
    _ => return None // cannot determine byte order
  }
  Some({
    abbrev,
    aranges: b"",
    frame: b"",
    info,
    line: b"",
    pubnames: b"",
    ranges: b"",
    str,
    addr: b"",
    line_str: b"",
    str_offsets: b"",
    rng_lists: b"",
    big_endian,
    order,
  })
}

///|
/// Get the byte order
pub fn Data::get_byte_order(self : Data) -> ByteOrder {
  self.order
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
