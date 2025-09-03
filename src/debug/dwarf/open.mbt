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
priv suberror SegmentSelectorError String

///|
pub impl Default for Data with default() -> Data {
  Data::{
    abbrev: @slice.new(),
    aranges: @slice.new(),
    frame: @slice.new(),
    info: @slice.new(),
    line: @slice.new(),
    pubnames: @slice.new(),
    ranges: @slice.new(),
    str: @slice.new(),
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
    (0, 0) => raise DecodeError::new("info", 4, "unsupported version 0")
    (0, _) => {
      d.big_endian = true
      d.order = BigEndian
    }
    (_, 0) => {
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
  d : Data,
  name : String,
  types : @slice.Slice[Byte],
) -> @unit.T raise {
  d.parse_types(name, types)
}

///|
/// AddSection adds another DWARF section by name. The name should be a
/// DWARF section name such as ".debug_addr", ".debug_str_offsets", and
/// so forth. This approach is used for new DWARF sections added in
/// DWARF 5 and later.
pub fn Data::add_section(
  d : Data,
  name : String,
  contents : @slice.Slice[Byte],
) -> @unit.T {
  match name {
    ".debug_addr" => d.addr = contents
    ".debug_line_str" => d.line_str = contents
    ".debug_str_offsets" => d.str_offsets = contents
    ".debug_rnglists" => d.rng_lists = contents
    _ => () // Just ignore names that we don't yet support.
  }
}
