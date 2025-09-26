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
  mut file_header : FileHeader
  mut optional_header : OptionalHeader? // of type *OptionalHeader32 or *OptionalHeader64
  sections : Array[Section]
  mut symbols : Array[Symbol] // COFF symbols with auxiliary symbol records removed
  mut coff_symbols : Array[COFFSymbol] // all COFF symbols (including auxiliary symbol records)
  mut string_table : StringTable
  priv mut closer : &@io.Closer?
}

///|
/// OptionalHeaderVariant represents either 32-bit or 64-bit optional header
pub(all) enum OptionalHeader {
  Header32(OptionalHeader32)
  Header64(OptionalHeader64)
} derive(Show, Eq, ToJson)

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
  let f = File::{
    file_header: FileHeader::{
      machine: 0,
      number_of_sections: 0,
      time_date_stamp: 0,
      pointer_to_symbol_table: 0,
      number_of_symbols: 0,
      size_of_optional_header: 0,
      characteristics: 0,
    },
    optional_header: None,
    sections: [],
    symbols: [],
    coff_symbols: [],
    string_table: @slice.new(),
    closer: None,
  }
  let sr = @io.new_section_reader(r, 0, (1 : Int64) << (63 - 1))
  let dosheader : FixedArray[Byte] = FixedArray::make(96, 0)
  let _ = r.read_at(@slice.fixedarray(dosheader), 0)
  let mut base : Int64 = 0
  if dosheader[0] == ('M' : Byte) && dosheader[1] == ('Z' : Byte) {
    let signoff : Int64 = @binary.little_endian
      .uint32(@slice.fixedarray(dosheader)[0x3c:0x40])
      .to_int64()
    let sign : FixedArray[Byte] = FixedArray::make(4, 0)
    let _ = r.read_at(@slice.fixedarray(sign), signoff)
    if !(sign[0] == ('P' : Byte) &&
      sign[1] == ('E' : Byte) &&
      sign[2] == (0 : Byte) &&
      sign[3] == (0 : Byte)) {
      raise Failure(
        "invalid PE file signature: \{sign[0]} \{sign[1]} \{sign[2]} \{sign[3]}",
      )
    }
    base = signoff + 4
  } else {
    base = 0
  }
  let _ = sr.seek(base, @io.SeekStart)
  f.file_header = @binary.read(sr, @binary.little_endian)
  match f.file_header.machine {
    IMAGE_FILE_MACHINE_AMD64
    | IMAGE_FILE_MACHINE_ARM64
    | IMAGE_FILE_MACHINE_ARMNT
    | IMAGE_FILE_MACHINE_I386
    | IMAGE_FILE_MACHINE_RISCV32
    | IMAGE_FILE_MACHINE_RISCV64
    | IMAGE_FILE_MACHINE_RISCV128
    | IMAGE_FILE_MACHINE_UNKNOWN => () // ok
    _ =>
      raise Failure(
        "unrecognized PE machine: 0x\{f.file_header.machine.to_string(radix=16)}",
      )
  }

  // Read string table.
  f.string_table = read_string_table(f.file_header, sr)

  // Read symbol table.
  f.coff_symbols = read_coff_symbols(f.file_header, sr)
  f.symbols = remove_aux_symbols(f.coff_symbols, f.string_table)

  // Seek past file header.
  let _ = sr.seek(base + @binary.size(f.file_header).to_int64(), @io.SeekStart)

  // Read optional header.
  f.optional_header = read_optional_header(
    sr,
    f.file_header.size_of_optional_header,
  )

  // Process sections.
  for i in 0..<f.file_header.number_of_sections.to_int() {
    let sh : SectionHeader32 = @binary.read(sr, @binary.little_endian)
    let name = sh.full_name(f.string_table)
    let mut r2 = r
    if sh.pointer_to_raw_data == 0 {
      r2 = NobitsSectionReader::{  }
    }
    let ssr = @io.new_section_reader(
      r2,
      sh.pointer_to_raw_data.to_int64(),
      sh.size_of_raw_data.to_int64(),
    )
    let s = Section::{
      section_header: SectionHeader::{
        name,
        virtual_size: sh.virtual_size,
        virtual_address: sh.virtual_address,
        size: sh.size_of_raw_data,
        offset: sh.pointer_to_raw_data,
        pointer_to_relocations: sh.pointer_to_relocations,
        pointer_to_line_numbers: sh.pointer_to_line_numbers,
        number_of_relocations: sh.number_of_relocations,
        number_of_line_numbers: sh.number_of_line_numbers,
        characteristics: sh.characteristics,
      },
      relocs: [],
      reader_at: ssr,
      sr: ssr,
    }
    f.sections.push(s)
  }
  for i in 0..<f.sections.length() {
    f.sections[i].relocs = read_relocs(f.sections[i].section_header, sr)
  }
  f
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
pub impl @io.ReaderAt for NobitsSectionReader with read_at(
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
pub fn File::dwarf(self : File) -> @dwarf.Data raise {
  fn dwarf_suffix(s : Section) -> String {
    if s.section_header.name is [.. ".debug_", .. name] {
      return name.to_string()
    } else if s.section_header.name is [.. ".zdebug_", .. name] {
      return name.to_string()
    } else {
      return ""
    }
  }

  fn section_data(s : Section) -> @slice.Slice[Byte] raise {
    let mut b = s.data()
    if 0U < s.section_header.virtual_size &&
      s.section_header.virtual_size < s.section_header.size {
      b = b[:int(s.section_header.virtual_size)]
    }
    if len(b) >= 12 && b[:4].bytesview() is "ZLIB" {
      let dlen = @binary.big_endian.uint64(b[4:12])
      let dbuf = @slice.make(int(dlen))
      let r = @zlib.new_reader(@bytes.new_buffer(b[12:]))
      let _ = @io.read_full(r, dbuf)
      r.close()
      b = dbuf
    }
    return b
  }

  // There are many other DWARF sections, but these
  // are the ones the debug/dwarf package uses.
  // Don't bother loading others.
  let dat = {
    "abbrev": @slice.new(),
    "info": @slice.new(),
    "str": @slice.new(),
    "line": @slice.new(),
    "ranges": @slice.new(),
  }
  for s in self.sections {
    let suffix = dwarf_suffix(s)
    if suffix == "" {
      continue
    }
    guard dat.get(suffix) is Some(_) else { continue }
    let b = section_data(s)
    dat[suffix] = b
  }
  let d = @dwarf.new(
    abbrev=dat["abbrev"],
    info=dat["info"],
    str=dat["str"],
    ranges=dat["ranges"],
    line=dat["line"],
  )
  for i in 0..<self.sections.length() {
    let s = self.sections[i]
    let suffix = dwarf_suffix(s)
    if suffix == "" {
      continue
    }
    guard dat.get(suffix) is Some(_) else { continue }
    let b = section_data(s)
    if suffix is "types" {
      d.add_types("types-\{i}", b)
    } else {
      d.add_section([..".debug", ..suffix], b)
    }
  }
  d
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
  guard self.optional_header is Some(oh) else { return [] }
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
  oh_magic = @binary.read(r, @binary.little_endian) catch {
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
        major_linker_version: @binary.read(r, @binary.little_endian),
        minor_linker_version: @binary.read(r, @binary.little_endian),
        size_of_code: @binary.read(r, @binary.little_endian),
        size_of_initialized_data: @binary.read(r, @binary.little_endian),
        size_of_uninitialized_data: @binary.read(r, @binary.little_endian),
        address_of_entry_point: @binary.read(r, @binary.little_endian),
        base_of_code: @binary.read(r, @binary.little_endian),
        base_of_data: @binary.read(r, @binary.little_endian),
        image_base: @binary.read(r, @binary.little_endian),
        section_alignment: @binary.read(r, @binary.little_endian),
        file_alignment: @binary.read(r, @binary.little_endian),
        major_operating_system_version: @binary.read(r, @binary.little_endian),
        minor_operating_system_version: @binary.read(r, @binary.little_endian),
        major_image_version: @binary.read(r, @binary.little_endian),
        minor_image_version: @binary.read(r, @binary.little_endian),
        major_subsystem_version: @binary.read(r, @binary.little_endian),
        minor_subsystem_version: @binary.read(r, @binary.little_endian),
        win32_version_value: @binary.read(r, @binary.little_endian),
        size_of_image: @binary.read(r, @binary.little_endian),
        size_of_headers: @binary.read(r, @binary.little_endian),
        check_sum: @binary.read(r, @binary.little_endian),
        subsystem: @binary.read(r, @binary.little_endian),
        dll_characteristics: @binary.read(r, @binary.little_endian),
        size_of_stack_reserve: @binary.read(r, @binary.little_endian),
        size_of_stack_commit: @binary.read(r, @binary.little_endian),
        size_of_heap_reserve: @binary.read(r, @binary.little_endian),
        size_of_heap_commit: @binary.read(r, @binary.little_endian),
        loader_flags: @binary.read(r, @binary.little_endian),
        number_of_rva_and_sizes: @binary.read(r, @binary.little_endian),
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
        major_linker_version: @binary.read(r, @binary.little_endian),
        minor_linker_version: @binary.read(r, @binary.little_endian),
        size_of_code: @binary.read(r, @binary.little_endian),
        size_of_initialized_data: @binary.read(r, @binary.little_endian),
        size_of_uninitialized_data: @binary.read(r, @binary.little_endian),
        address_of_entry_point: @binary.read(r, @binary.little_endian),
        base_of_code: @binary.read(r, @binary.little_endian),
        image_base: @binary.read(r, @binary.little_endian),
        section_alignment: @binary.read(r, @binary.little_endian),
        file_alignment: @binary.read(r, @binary.little_endian),
        major_operating_system_version: @binary.read(r, @binary.little_endian),
        minor_operating_system_version: @binary.read(r, @binary.little_endian),
        major_image_version: @binary.read(r, @binary.little_endian),
        minor_image_version: @binary.read(r, @binary.little_endian),
        major_subsystem_version: @binary.read(r, @binary.little_endian),
        minor_subsystem_version: @binary.read(r, @binary.little_endian),
        win32_version_value: @binary.read(r, @binary.little_endian),
        size_of_image: @binary.read(r, @binary.little_endian),
        size_of_headers: @binary.read(r, @binary.little_endian),
        check_sum: @binary.read(r, @binary.little_endian),
        subsystem: @binary.read(r, @binary.little_endian),
        dll_characteristics: @binary.read(r, @binary.little_endian),
        size_of_stack_reserve: @binary.read(r, @binary.little_endian),
        size_of_stack_commit: @binary.read(r, @binary.little_endian),
        size_of_heap_reserve: @binary.read(r, @binary.little_endian),
        size_of_heap_commit: @binary.read(r, @binary.little_endian),
        loader_flags: @binary.read(r, @binary.little_endian),
        number_of_rva_and_sizes: @binary.read(r, @binary.little_endian),
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
  @binary.read_n(r, @binary.little_endian, int(n))
}
