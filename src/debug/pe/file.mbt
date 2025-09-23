// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package pe implements access to PE (Microsoft Windows Portable Executable) files.
//
// # Security
//
// This package is not designed to be hardened against adversarial inputs, and is
// outside the scope of https://go.dev/security/policy. In particular, only basic
// validation is done when parsing object files. As such, care should be taken when
// parsing untrusted inputs, as parsing malformed files may consume significant
// resources, or cause panics.
//

///|
/// A File represents an open PE file.
pub struct File {
  file_header : FileHeader
  optional_header : OptionalHeader // of type *OptionalHeader32 or *OptionalHeader64
  sections : Array[Section]
  symbols : Array[Symbol] // COFF symbols with auxiliary symbol records removed
  coff_symbols : Array[COFFSymbol] // all COFF symbols (including auxiliary symbol records)
  string_table : StringTable
  mut closer : &@io.Closer?
}

///|
/// OptionalHeaderVariant represents either 32-bit or 64-bit optional header
pub(all) enum OptionalHeader {
  Header32(OptionalHeader32)
  Header64(OptionalHeader64)
} derive(Show, Eq, ToJson)

///|
impl @binary.Sized for OptionalHeader32 with size() -> Int {
  224
}

///|
/// Open opens the named file using [os.Open] and prepares it for use as a PE binary.
pub fn open(name : String) -> File raise {
  let f = @os.open(name)
  let ff = new_file(f) catch {
    err => {
      f.close()
      raise err
    }
  }
  ff.closer = Some(f)
  ff
}

///|
/// `close` closes the `File`.
/// If the `File` was created using `new_file` directly instead of `Open`,
/// `close` has no effect.
pub fn File::close(self : File) -> Unit raise {
  if self.closer is Some(closer) {
    closer.close()
  }
}

///|
/// TODO(brainman): add Load function, as a replacement for NewFile, that does not call removeAuxSymbols (for performance)

///|
/// `new_file` creates a new `File` for accessing a PE binary in an underlying reader.
pub fn new_file(r : &@io.ReaderAt) -> File raise {
  ...
}

///|
struct NobitsSectionReader {}

///|
priv suberror UnexpectedReadFromSectionWithUninitializedData

///|
impl Show for UnexpectedReadFromSectionWithUninitializedData with output(
  _ : UnexpectedReadFromSectionWithUninitializedData,
  logger : &Logger,
) -> Unit {
  logger.write_string("unexpected read from section with uninitialized data")
}

///|
fn NobitsSectionReader::read_at(
  _ : NobitsSectionReader,
  _ : @slice.Slice[Byte],
  _ : Int64,
) -> Int raise {
  raise UnexpectedReadFromSectionWithUninitializedData
}

///|
/// `get_string` extracts a string from symbol string table.
fn get_string(section : @slice.Slice[Byte], start : Int) -> (String, Bool) {
  if start < 0 || start >= section.length() {
    return ("", false)
  }
  for end = start; end < section.length(); end = end + 1 {
    if section[end] == (0 : Byte) {
      return (@utf8.decode_lossy(section[start:end]), true)
    }
  }
  ("", false)
}

///|
/// Section returns the first section with the given name, or nil if no such
/// section exists.
pub fn File::section(self : File, name : String) -> Section? {
  for s in self.sections {
    if s.section_header.name == name {
      return Some(s)
    }
  }
  None
}

///|
pub fn File::dwarf(self : File) -> String {
  ...
}

///|
/// TODO(brainman): document ImportDirectory once we decide what to do with it.

///|
pub struct ImportDirectory {
  original_first_thunk : UInt
  time_date_stamp : UInt
  forwarder_chain : UInt
  name : UInt
  first_thunk : UInt
  priv dll : String
} derive(Show, Eq, ToJson)

///|
/// `imported_symbols` returns the names of all symbols
/// referred to by the binary f that are expected to be
/// satisfied by other libraries at dynamic load time.
/// It does not return weak symbols.
pub fn File::imported_symbols(self : File) -> Array[String] {
  ...
}

///|
/// ImportedLibraries returns the names of all libraries
/// referred to by the binary f that are expected to be
/// linked with the binary at dynamic link time.
pub fn File::imported_libraries(_ : File) -> Array[String] raise {
  // TODO
  // cgo -dynimport don't use this for windows PE, so just return.
  if false {
    fail("unreachable")
  }
  return []
}

///|
/// FormatError is unused.
/// The type is retained for compatibility.
pub(all) struct FormatError {} derive(Show, Eq, ToJson)

///|
pub fn FormatError::error(_ : FormatError) -> String {
  "unknown error"
}

///|
/// readOptionalHeader accepts an io.ReadSeeker pointing to optional header in the PE file
/// and its size as seen in the file header.
/// It parses the given size of bytes and returns optional header. It infers whether the
/// bytes being parsed refer to 32 bit or 64 bit version of optional header.
fn read_optional_header(
  r : &@io.ReadSeeker,
  sz : UInt16,
) -> OptionalHeader? raise {
  // If optional header size is 0, return empty optional header.
  if sz == 0 {
    return None
  }
  let mut oh_magic : UInt16 = 0
  let oh_magic_sz = @binary.size(oh_magic)

  // If optional header size is greater than 0 but less than its magic size, return error.
  if sz < oh_magic_sz.to_uint16() {
    raise Failure(
      "optional header size is less than optional header magic size",
    )
  }
  oh_magic = @binary.read(r, @binary.little_endian, 0) catch {
    err => raise Failure("failure to read optional header magic: \{err}")
  }
  match oh_magic {
    0x10b => { // PE32
      let oh32_min_sz : UInt16 = 96
      if sz < oh32_min_sz {
        raise Failure(
          "optional header size(\{sz}) is less minimum size (\{oh32_min_sz}) of PE32 optional header",
        )
      }

      // Init oh32 fields
      let oh32 = OptionalHeader32::{
        magic: oh_magic,
        major_linker_version: @binary.read(r, @binary.little_endian, 0),
        minor_linker_version: @binary.read(r, @binary.little_endian, 0),
        size_of_code: @binary.read(r, @binary.little_endian, 0),
        size_of_initialized_data: @binary.read(r, @binary.little_endian, 0),
        size_of_uninitialized_data: @binary.read(r, @binary.little_endian, 0),
        address_of_entry_point: @binary.read(r, @binary.little_endian, 0),
        base_of_code: @binary.read(r, @binary.little_endian, 0),
        base_of_data: @binary.read(r, @binary.little_endian, 0),
        image_base: @binary.read(r, @binary.little_endian, 0),
        section_alignment: @binary.read(r, @binary.little_endian, 0),
        file_alignment: @binary.read(r, @binary.little_endian, 0),
        major_operating_system_version: @binary.read(
          r, @binary.little_endian, 0,
        ),
        minor_operating_system_version: @binary.read(
          r, @binary.little_endian, 0,
        ),
        major_image_version: @binary.read(r, @binary.little_endian, 0),
        minor_image_version: @binary.read(r, @binary.little_endian, 0),
        major_subsystem_version: @binary.read(r, @binary.little_endian, 0),
        minor_subsystem_version: @binary.read(r, @binary.little_endian, 0),
        win32_version_value: @binary.read(r, @binary.little_endian, 0),
        size_of_image: @binary.read(r, @binary.little_endian, 0),
        size_of_headers: @binary.read(r, @binary.little_endian, 0),
        check_sum: @binary.read(r, @binary.little_endian, 0),
        subsystem: @binary.read(r, @binary.little_endian, 0),
        dll_characteristics: @binary.read(r, @binary.little_endian, 0),
        size_of_stack_reserve: @binary.read(r, @binary.little_endian, 0),
        size_of_stack_commit: @binary.read(r, @binary.little_endian, 0),
        size_of_heap_reserve: @binary.read(r, @binary.little_endian, 0),
        size_of_heap_commit: @binary.read(r, @binary.little_endian, 0),
        loader_flags: @binary.read(r, @binary.little_endian, 0),
        number_of_rva_and_sizes: @binary.read(r, @binary.little_endian, 0),
        data_directory: [],
      }
      let dd = read_data_directories(
        r,
        sz - oh32_min_sz,
        oh32.number_of_rva_and_sizes,
      )
      for i in 0..<16 {
        oh32.data_directory[i] = dd[i]
      }
      Some(Header32(oh32))
    }
    0x20b => { // PE32+
      let oh64_min_sz : UInt16 = 112
      if sz < oh64_min_sz {
        raise Failure(
          "optional header size is less minimum size for PE32+ optional header",
        )
      }
      let oh64 = OptionalHeader64::{
        magic: oh_magic,
        major_linker_version: @binary.read(r, @binary.little_endian, 0),
        minor_linker_version: @binary.read(r, @binary.little_endian, 0),
        size_of_code: @binary.read(r, @binary.little_endian, 0),
        size_of_initialized_data: @binary.read(r, @binary.little_endian, 0),
        size_of_uninitialized_data: @binary.read(r, @binary.little_endian, 0),
        address_of_entry_point: @binary.read(r, @binary.little_endian, 0),
        base_of_code: @binary.read(r, @binary.little_endian, 0),
        image_base: @binary.read(r, @binary.little_endian, 0),
        section_alignment: @binary.read(r, @binary.little_endian, 0),
        file_alignment: @binary.read(r, @binary.little_endian, 0),
        major_operating_system_version: @binary.read(
          r, @binary.little_endian, 0,
        ),
        minor_operating_system_version: @binary.read(
          r, @binary.little_endian, 0,
        ),
        major_image_version: @binary.read(r, @binary.little_endian, 0),
        minor_image_version: @binary.read(r, @binary.little_endian, 0),
        major_subsystem_version: @binary.read(r, @binary.little_endian, 0),
        minor_subsystem_version: @binary.read(r, @binary.little_endian, 0),
        win32_version_value: @binary.read(r, @binary.little_endian, 0),
        size_of_image: @binary.read(r, @binary.little_endian, 0),
        size_of_headers: @binary.read(r, @binary.little_endian, 0),
        check_sum: @binary.read(r, @binary.little_endian, 0),
        subsystem: @binary.read(r, @binary.little_endian, 0),
        dll_characteristics: @binary.read(r, @binary.little_endian, 0),
        size_of_stack_reserve: @binary.read(r, @binary.little_endian, 0),
        size_of_stack_commit: @binary.read(r, @binary.little_endian, 0),
        size_of_heap_reserve: @binary.read(r, @binary.little_endian, 0),
        size_of_heap_commit: @binary.read(r, @binary.little_endian, 0),
        loader_flags: @binary.read(r, @binary.little_endian, 0),
        number_of_rva_and_sizes: @binary.read(r, @binary.little_endian, 0),
        data_directory: FixedArray::make(16, DataDirectory::default()),
      }
      let dd = read_data_directories(
        r,
        sz - oh64_min_sz,
        oh64.number_of_rva_and_sizes,
      )
      for i in 0..<16 {
        oh64.data_directory[i] = dd[i]
      }
      Some(Header64(oh64))
    }
    _ =>
      raise Failure(
        "optional header has unexpected Magic of 0x\{oh_magic.to_string(radix=16)}",
      )
  }
}

///|
/// read_data_directories accepts an io.ReadSeeker pointing to data directories in the PE file,
/// its size and number of data directories as seen in optional header.
/// It parses the given size of bytes and returns given number of data directories.
fn read_data_directories(
  r : &@io.ReadSeeker,
  sz : UInt16,
  n : UInt,
) -> Array[DataDirectory] raise {
  let dd_sz : UInt64 = 8
  if sz.to_uint64() != n.to_uint64() * dd_sz {
    raise Failure(
      "size of data directories(\{sz}) is inconsistent with number of data directories(\{n})",
    )
  }
  let dd : Array[DataDirectory] = Array::make(
    n.reinterpret_as_int(),
    DataDirectory::default(),
  )
  @binary.read(r, @binary.little_endian, dd)
}
