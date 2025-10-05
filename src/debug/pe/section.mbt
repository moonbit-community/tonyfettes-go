/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// SectionHeader32 represents real PE COFF section header.
struct SectionHeader32 {
  name : FixedArray[Byte] // [8]uint8
  virtual_size : UInt
  virtual_address : UInt
  size_of_raw_data : UInt
  pointer_to_raw_data : UInt
  pointer_to_relocations : UInt
  pointer_to_line_numbers : UInt
  number_of_relocations : UInt16
  number_of_line_numbers : UInt16
  characteristics : UInt
} derive(Show, Eq, ToJson, Default)

///|
pub impl @binary.Readable for SectionHeader32 with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> SectionHeader32 raise {
  SectionHeader32::{
    name: @binary.read_n(r, order, 8),
    virtual_size: @binary.read(r, order),
    virtual_address: @binary.read(r, order),
    size_of_raw_data: @binary.read(r, order),
    pointer_to_raw_data: @binary.read(r, order),
    pointer_to_relocations: @binary.read(r, order),
    pointer_to_line_numbers: @binary.read(r, order),
    number_of_relocations: @binary.read(r, order),
    number_of_line_numbers: @binary.read(r, order),
    characteristics: @binary.read(r, order),
  }
}

///|
/// fullName finds real name of section sh. Normally name is stored
/// in sh.Name, but if it is longer then 8 characters, it is stored
/// in COFF string table st instead.
fn SectionHeader32::full_name(
  self : SectionHeader32,
  st : StringTable,
) -> String raise {
  if self.name[0] != ('/' : Byte) {
    cstring(@slice.fixedarray(self.name))
  } else {
    let i = @strconv.parse_int(cstring(@slice.fixedarray(self.name)[1:]))
    st.string(uint(i))
  }
}

///|
/// TODO(brainman): copy all IMAGE_REL_* consts from ldpe.go here

///|
/// Reloc represents a PE COFF relocation.
/// Each section contains its own relocation list.
pub struct Reloc {
  virtual_address : UInt
  symbol_table_index : UInt
  type_ : UInt16
} derive(Show, Eq, ToJson, Default)

///|
pub impl @binary.Readable for Reloc with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> Reloc raise {
  Reloc::{
    virtual_address: @binary.read(r, order),
    symbol_table_index: @binary.read(r, order),
    type_: @binary.read(r, order),
  }
}

///|
fn read_relocs(sh : SectionHeader, r : &@io.ReadSeeker) -> Array[Reloc] raise {
  if sh.number_of_relocations <= 0 {
    return []
  }
  let _ = r.seek(int64(sh.pointer_to_relocations), @io.SeekStart)
  let relocs = @binary.read_n(
    r,
    @binary.LittleEndian,
    int(sh.number_of_relocations),
  ) catch {
    error => fail("failed to read section relocations: \{error}")
  }
  relocs
}

///|
/// SectionHeader is similar to [SectionHeader32] with Name
/// field replaced by Go string.
pub(all) struct SectionHeader {
  name : String
  virtual_size : UInt
  virtual_address : UInt
  size : UInt
  offset : UInt
  pointer_to_relocations : UInt
  pointer_to_line_numbers : UInt
  number_of_relocations : UInt16
  number_of_line_numbers : UInt16
  characteristics : UInt
} derive(Show, Eq, ToJson)

///|
/// Section provides access to PE COFF section.
pub struct Section {
  section_header : SectionHeader
  mut relocs : Array[Reloc]
  // Embed ReaderAt for ReadAt method.
  // Do not embed SectionReader directly
  // to avoid having Read and Seek.
  // If a client wants Read and Seek it must use
  // Open() to avoid fighting over the seek offset
  reader_at : &@io.ReaderAt
  sr : @io.SectionReader
}

///|
/// Data reads and returns the contents of the PE section s.
///
/// If s.Offset is 0, the section has no contents,
/// and Data will always return a non-nil error.
pub fn Section::data(self : Section) -> @slice.Slice[Byte] raise {
  @saferio.read_data_at(self.sr, uint64(self.section_header.size), 0)
}

///|
/// Open returns a new ReadSeeker reading the PE section s.
///
/// If s.Offset is 0, the section has no contents, and all calls
/// to the returned reader will return a non-nil error.
pub fn Section::open(self : Section) -> &@io.ReadSeeker {
  @io.new_section_reader(self.sr, 0, 1 << (63 - 1))
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
