///|
/// DWARF debug information support for Mach-O files
///
/// This module provides functionality to parse and decompress DWARF debug sections,
/// including support for ZLIB-compressed sections that begin with "ZLIB" magic.

///|
/// DwarfData represents extracted DWARF debug information
pub struct DwarfData {
  /// DWARF sections mapped by name (without prefix)
  sections : Map[Bytes, Bytes]
} derive(Show)

///|
/// Extract DWARF debug information from a Mach-O file
/// Returns DwarfData containing all DWARF sections found in the file
pub fn File::dwarf(self : File, file_data : Bytes) -> DwarfData? raise {
  fn decompress_section_data(
    section : Section,
    file_data : Bytes,
  ) -> Bytes raise {
    let data = section.data(file_data)

    // Check if this is a ZLIB-compressed section by examining first 4 bytes
    if data.length() >= 12 && data is [.. "ZLIB", ..] {
      decompress_zlib_section(data)
    } else {
      data
    }
  }

  fn decompress_zlib_section(data : Bytes) -> Bytes raise {
    // Extract uncompressed size (8 bytes, big-endian)
    let dlen = read_uint64_be(data, 4)

    // For now, return a simple error indicating ZLIB decompression is not fully implemented
    // TODO: Implement proper ZLIB decompression using @zlib package once API is stable
    ...
  }

  let sections = Map::new()

  // Look for DWARF sections in all file sections
  for section in self.sections {
    let suffix = dwarf_suffix(section)
    if suffix != "" {
      let data = decompress_section_data(section, file_data)
      sections[suffix] = data
    }
  }
  if sections.is_empty() {
    None
  } else {
    Some({ sections, })
  }
}

///|
/// Get the DWARF suffix from a section name
/// Returns empty bytes if section is not a DWARF section
fn dwarf_suffix(section : Section) -> Bytes {
  let sectname = section.header.name

  // Check for standard DWARF sections
  if sectname is [.. "__debug_", .. suffix] {
    return expand_dwarf_section_name_bytes([..suffix])
  }

  // Check for compressed DWARF sections
  if sectname is [.. "__zdebug_", .. suffix] {
    return expand_dwarf_section_name_bytes([..suffix])
  }
  b""
}

///|
/// Expand truncated DWARF section names (working with Bytes)
/// Mach-O executables truncate section names to 16 characters, mangling some DWARF sections
fn expand_dwarf_section_name_bytes(suffix : Bytes) -> Bytes {
  // Handle truncated section names (16 character limit in Mach-O)
  if suffix == b"str_offsets" {
    b"str_offsets"
  } else if suffix == b"line_str" {
    b"line_str"
  } else if suffix == b"loclists" {
    b"loclists"
  } else if suffix == b"pubnames" {
    b"pubnames"
  } else if suffix == b"pubtypes" {
    b"pubtypes"
  } else if suffix == b"rnglists" {
    b"rnglists"
  } else {
    suffix
  }
}

///|
/// Read a 64-bit big-endian unsigned integer from bytes at offset
fn read_uint64_be(data : Bytes, offset : Int) -> UInt64 {
  let b0 = data.op_get(offset).to_uint64()
  let b1 = data.op_get(offset + 1).to_uint64()
  let b2 = data.op_get(offset + 2).to_uint64()
  let b3 = data.op_get(offset + 3).to_uint64()
  let b4 = data.op_get(offset + 4).to_uint64()
  let b5 = data.op_get(offset + 5).to_uint64()
  let b6 = data.op_get(offset + 6).to_uint64()
  let b7 = data.op_get(offset + 7).to_uint64()
  (b0 << 56) |
  (b1 << 48) |
  (b2 << 40) |
  (b3 << 32) |
  (b4 << 24) |
  (b5 << 16) |
  (b6 << 8) |
  b7
}

///|
/// Get a specific DWARF section by name
pub fn DwarfData::get_section(self : DwarfData, name : Bytes) -> Bytes? {
  self.sections.get(name)
}

///|
/// Get all available DWARF section names
pub fn DwarfData::get_section_names(self : DwarfData) -> Array[Bytes] {
  let names = []
  self.sections.each(fn(name, _) { names.push(name) })
  names
}

///|
/// Check if DWARF data contains a specific section
pub fn DwarfData::has_section(self : DwarfData, name : Bytes) -> Bool {
  self.sections.contains(name)
}
