/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// SectionHeader32 represents real PE COFF section header.
struct SectionHeader32 {
  name : FixedArray[Byte] // [8]uint8
  virtual_size : Int64
  virtual_address : Int64
  size_of_raw_data : Int64
  pointer_to_raw_data : Int64
  pointer_to_relocations : Int64
  pointer_to_line_numbers : Int64
  number_of_relocations : Int
  number_of_line_numbers : Int
  characteristics : Int64
} derive(Show, Eq, ToJson)

///|
/// fullName finds real name of section sh. Normally name is stored
/// in sh.Name, but if it is longer then 8 characters, it is stored
/// in COFF string table st instead.
fn SectionHeader32::full_name(
  self : SectionHeader32,
  st : StringTable,
) -> String {
  if self.name[0] != ('/' : Byte) {
    cstring(@slice.array(self.name))
  } else {
    // Parse the number after '/'
    let name_slice = @slice.array(self.name)
    let name_tail = name_slice[1:]
    let name_str = cstring(name_tail)
    // FIXME: Implement proper string to int conversion
    // For now, just return the string as is
    string_table_string(st, 0)
  }
}

///|
/// Reloc represents a PE COFF relocation.
/// Each section contains its own relocation list.
pub struct Reloc {
  virtual_address : Int64
  symbol_table_index : Int64
  type_ : Int
} derive(Show, Eq, ToJson)

///|
fn read_relocs(sh : SectionHeader, r : &@io.ReadSeeker) -> Array[Reloc] {
  // FIXME: Implement proper relocation reading
  // For now, return empty array as placeholder
  ignore(sh)
  ignore(r)
  []
}

///|
/// SectionHeader is similar to [SectionHeader32] with Name
/// field replaced by Go string.
pub(all) struct SectionHeader {
  name : String
  virtual_size : Int64
  virtual_address : Int64
  size : Int64
  offset : Int64
  pointer_to_relocations : Int64
  pointer_to_line_numbers : Int64
  number_of_relocations : Int
  number_of_line_numbers : Int
  characteristics : Int64
} derive(Show, Eq, ToJson)

///|
/// Section provides access to PE COFF section.
pub struct Section {
  section_header : SectionHeader
  relocs : Array[Reloc]
  // Embed ReaderAt for ReadAt method.
  // Do not embed SectionReader directly
  // to avoid having Read and Seek.
  // If a client wants Read and Seek it must use
  // Open() to avoid fighting over the seek offset
  // with other clients.
  // FIXME: Use proper reader types once available
} derive(Show, ToJson)

///|
/// Data reads and returns the contents of the PE section s.
///
/// If s.Offset is 0, the section has no contents,
/// and Data will always return a non-nil error.
pub fn Section::data(self : Section) -> @slice.Slice[Byte] {
  // FIXME: Implement proper section data reading using saferio
  // For now, return empty slice as placeholder
  ignore(self)
  @slice.new()
}

///|
/// Open returns a new ReadSeeker reading the PE section s.
///
/// If s.Offset is 0, the section has no contents, and all calls
/// to the returned reader will return a non-nil error.
pub fn Section::open(self : Section) -> String {
  // FIXME: Implement proper section reader that returns ReadSeeker
  // For now, return a placeholder string
  ignore(self)
  "FIXME: Section reader not implemented"
}

///|
/// Section characteristics flags.
pub const IMAGE_SCN_CNT_CODE : Int64 = 0x00000020

///|
pub const IMAGE_SCN_CNT_INITIALIZED_DATA : Int64 = 0x00000040

///|
pub const IMAGE_SCN_CNT_UNINITIALIZED_DATA : Int64 = 0x00000080

///|
pub const IMAGE_SCN_LNK_COMDAT : Int64 = 0x00001000

///|
pub const IMAGE_SCN_MEM_DISCARDABLE : Int64 = 0x02000000

///|
pub const IMAGE_SCN_MEM_EXECUTE : Int64 = 0x20000000

///|
pub const IMAGE_SCN_MEM_READ : Int64 = 0x40000000

///|
pub const IMAGE_SCN_MEM_WRITE : Int64 = 0x80000000
