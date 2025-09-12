/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// Package elf implements access to ELF object files.
///
/// # Security
///
/// This package is not designed to be hardened against adversarial inputs, and is
/// outside the scope of https://go.dev/security/policy. In particular, only basic
/// validation is done when parsing object files. As such, care should be taken when
/// parsing untrusted inputs, as parsing malformed files may consume significant
/// resources, or cause panics.

///|
/// A FileHeader represents an ELF file header.
pub struct FileHeader {
  class : Class
  data : Data
  version : Version
  osabi : OSABI
  abi_version : Byte
  byte_order : &@binary.ByteOrder
  type_ : Type
  machine : Machine
  entry : UInt64
}

///|
/// A File represents an open ELF file.
pub struct File {
  file_header : FileHeader
  sections : Array[Section]
  progs : Array[Prog]
  priv mut closer : &@io.Closer?
  priv dyn_vers : Array[DynamicVersion]
  priv dyn_ver_needs : Array[DynamicVersionNeed]
  priv gnu_versym : Bytes // Simplified - using Bytes instead of slice
}

///|
/// A SectionHeader represents a single ELF section header.
pub struct SectionHeader {
  name : String
  type_ : SectionType
  flags : SectionFlag
  addr : UInt64
  offset : UInt64
  size : UInt64
  link : UInt
  info : UInt
  addralign : UInt64
  entsize : UInt64
  /// FileSize is the size of this section in the file in bytes.
  /// If a section is compressed, FileSize is the size of the
  /// compressed data, while Size (above) is the size of the
  /// uncompressed data.
  file_size : UInt64
} derive(Show, ToJson)

///|
/// Data reads and returns the contents of the ELF section.
/// Even if the section is stored compressed in the ELF file,
/// Data returns uncompressed data.
pub fn Section::data(self : Section) -> Bytes raise {
  @saferio.read_data(self.open(), self.section_header.size)
}

///|
/// A Section represents a single section in an ELF file.
pub struct Section {
  section_header : SectionHeader
  /// Embed ReaderAt for ReadAt method.
  /// Do not embed SectionReader directly
  /// to avoid having Read and Seek.
  /// If a client wants Read and Seek it must use
  /// Open() to avoid fighting over the seek offset
  /// with other clients.
  ///
  /// ReaderAt may be nil if the section is not easily available
  /// in a random-access form. For example, a compressed section
  /// may have a nil ReaderAt.
  reader_at : &@io.ReaderAt?
  priv sr : @io.SectionReader?
  priv compression_type : CompressionType
  priv compression_offset : Int64
}

///|
/// stringTable reads and returns the string table given by the
/// specified link value.
fn File::string_table(self : File, link : UInt) -> Bytes raise {
  if link <= 0 || link >= self.sections.length().reinterpret_as_uint() {
    raise SectionHasInvalidStringTableLink
  }
  self.sections[link.reinterpret_as_int()].data()
}

///|
/// Open returns a new ReadSeeker reading the ELF section.
/// Even if the section is stored compressed in the ELF file,
/// the ReadSeeker reads uncompressed data.
pub fn Section::open(self : Section) -> &@io.ReadSeeker raise {
  ...
}

///|
/// A ProgHeader represents a single ELF program header.
pub struct ProgHeader {
  type_ : ProgType
  flags : ProgFlag
  off : UInt64
  vaddr : UInt64
  paddr : UInt64
  filesz : UInt64
  memsz : UInt64
  align : UInt64
} derive(Show, ToJson)

///|
/// A Prog represents a single ELF program header in an ELF binary.
pub struct Prog {
  prog_header : ProgHeader
  /// Embed ReaderAt for ReadAt method.
  reader_at : &@io.ReaderAt?
  /// Do not embed SectionReader directly
  /// to avoid having Read and Seek.
  /// If a client wants Read and Seek it must use
  /// Open() to avoid fighting over the seek offset
  /// with other clients.
  priv sr : @io.SectionReader?
}

///|
/// Open returns a new ReadSeeker reading the ELF program body.
pub fn Prog::open(self : Prog) -> &@io.ReadSeeker raise {
  // FIXME: This is a simplified implementation
  ...
}

///|
/// A Symbol represents an entry in an ELF symbol table section.
pub struct Symbol {
  name : String
  info : Byte
  other : Byte
  /// HasVersion reports whether the symbol has any version information.
  /// This will only be true for the dynamic symbol table.
  mut has_version : Bool
  /// VersionIndex is the symbol's version index.
  /// This field is only meaningful if HasVersion is true.
  mut version_index : VersionIndex
  section : SectionIndex
  value : UInt64
  size : UInt64
  /// These fields are present only for the dynamic symbol table.
  mut version : String
  mut library : String
} derive(Show, ToJson)

///|
/// FormatError is used to indicate an error in the ELF format.
pub suberror FormatError {
  FormatError(off~ : Int64, msg~ : String, val~ : String?)
}

///|
fn FormatError::new(off~ : Int64, msg~ : String, val? : String) -> FormatError {
  FormatError(off~, msg~, val~)
}

///|
impl Show for FormatError with output(self : FormatError, output : &Logger) -> Unit {
  let FormatError(off~, msg~, val~) = self
  output.write_string(msg)
  if val is Some(val) {
    output.write_string(" '")
    output.write_string(val)
    output.write_string("' ")
  }
  output.write_string("in record at byte ")
  output.write_object(off)
}

///|
/// Open opens the named file using os.Open and prepares it for use as an ELF binary.
pub fn open(name : String) -> File raise {
  let f = @os.open(name)
  let ff = new_file(f) catch {
    err => {
      f.close()
      raise err
    }
  }
  ff.closer = Some(f)
  return ff
}

///|
/// Close closes the File.
/// If the File was created using NewFile directly instead of Open,
/// Close has no effect.
pub fn File::close(self : File) -> Unit raise {
  match self.closer {
    Some(closer) => {
      closer.close()
      self.closer = None
    }
    None => ()
  }
}

///|
/// SectionByType returns the first section in f with the
/// given type, or None if there is no such section.
pub fn File::section_by_type(self : File, typ : SectionType) -> Section? {
  for s in self.sections {
    if s.section_header.type_ == typ {
      return Some(s)
    }
  }
  None
}

///|
/// NewFile creates a new File for accessing an ELF binary in an underlying reader.
/// The ELF binary is expected to start at position 0 in the ReaderAt.
pub fn new_file(r : &@io.ReaderAt) -> File raise {
  // Read and decode ELF identifier
  let ident = @slice.make(16)
  let n = r.read_at(ident, 0)
  if n != 16 {
    raise FormatError::new(off=0, msg="incomplete ELF header")
  }
  guard ident.arrayview() is [0x7f, 'E', 'L', 'F', ..] else {
    raise FormatError::new(
      off=0,
      msg="bad magic number",
      val=ident[0:4].to_string(),
    )
  }
  let f = File::{
    file_header: FileHeader::{
      class: Class::from_int(ident[EI_CLASS].to_int()),
      data: Data::from_byte(ident[EI_DATA]),
      version: Version::from_byte(ident[EI_VERSION]),
      osabi: OSABI::from_int(ident[EI_OSABI].to_int()),
      abi_version: ident[EI_ABIVERSION],
      byte_order: @binary.little_endian, // FIXME: should be determined by data field
      type_: Type::from_int(0), // FIXME: read from header
      machine: Machine::from_int(0), // FIXME: read from header
      entry: 0UL, // FIXME: read from header
    },
    sections: [],
    progs: [],
    closer: None,
    dyn_vers: [],
    dyn_ver_needs: [],
    gnu_versym: Bytes::make(0, 0),
  }

  // FIXME: This is a very simplified implementation
  // The real implementation would:
  // 1. Validate the class, data, and version fields
  // 2. Read the full ELF header based on class (32/64 bit)
  // 3. Read program headers
  // 4. Read section headers
  // 5. Parse section names
  // 6. Handle special sections

  f
}

///|
priv suberror NotImplemented

///|
/// getSymbols returns a slice of Symbols from parsing the symbol table
/// with the given type, along with the associated string table.
fn File::get_symbols(
  self : File,
  typ : SectionType,
) -> (Array[Symbol], Bytes, Array[UInt]) raise {
  match self.file_header.class {
    ELFCLASS64 => self.get_symbols64(typ)
    ELFCLASS32 => self.get_symbols32(typ)
    _ => raise NotImplemented
  }
}

///|
/// NoSymbolsError is returned by File.Symbols and File.DynamicSymbols
/// if there is no such section in the File.
pub(all) suberror NoSymbolsError

///|
fn File::get_symbols32(
  self : File,
  typ : SectionType,
) -> (Array[Symbol], Bytes, Array[UInt]) raise {
  // FIXME: Implementation needed
  ...
}

///|
fn File::get_symbols64(
  self : File,
  typ : SectionType,
) -> (Array[Symbol], Bytes, Array[UInt]) raise {
  // FIXME: Implementation needed
  ...
}

///|
/// getString extracts a string from an ELF string table.
fn get_string(section : Bytes, start : Int) -> (String, Bool) {
  if start < 0 || start >= section.length() {
    return ("", false)
  }
  let mut end = start
  while end < section.length() {
    if section[end] == 0 {
      // Convert bytes to string - this may not be perfectly UTF-8 safe
      // but matches the Go implementation behavior
      let bytes_slice = section[start:end]
      return (bytes_slice.to_string(), true)
    }
    end = end + 1
  }
  ("", false)
}

///|
/// Section returns a section with the given name, or None if no such
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
/// Symbols returns the symbol table for f. The symbols will be listed in the order
/// they appear in f.
///
/// For compatibility with Go 1.0, Symbols omits the null symbol at index 0.
/// After retrieving the symbols as symtab, an externally supplied index x
/// corresponds to symtab[x-1], not symtab[x].
pub fn File::symbols(self : File) -> Array[Symbol] raise {
  let (sym, _, _) = self.get_symbols(SHT_SYMTAB)
  sym
}

///|
/// DynamicSymbols returns the dynamic symbol table for f. The symbols
/// will be listed in the order they appear in f.
///
/// If f has a symbol version table, the returned symbols will have
/// initialized Version and Library fields.
///
/// For compatibility with File.Symbols, DynamicSymbols omits the null symbol at index 0.
/// After retrieving the symbols as symtab, an externally supplied index x
/// corresponds to symtab[x-1], not symtab[x].
pub fn File::dynamic_symbols(self : File) -> Array[Symbol] raise {
  let (sym, str, _) = self.get_symbols(SHT_DYNSYM)
  let has_versions = self.gnu_version_init(str)
  if has_versions {
    for i in 0..<sym.length() {
      let (has_ver, ver_idx, version, library) = self.gnu_version(i)
      sym[i].has_version = has_ver
      sym[i].version_index = ver_idx
      sym[i].version = version
      sym[i].library = library
    }
  }
  sym
}

///|
pub struct ImportedSymbol {
  name : String
  version : String
  library : String
} derive(Show, ToJson)

///|
/// ImportedSymbols returns the names of all symbols
/// referred to by the binary f that are expected to be
/// satisfied by other libraries at dynamic load time.
/// It does not return weak symbols.
pub fn File::imported_symbols(self : File) -> Array[ImportedSymbol] raise {
  let (sym, str, _) = self.get_symbols(SHT_DYNSYM)
  self.gnu_version_init(str) |> ignore
  let all : Array[ImportedSymbol] = []
  for i in 0..<sym.length() {
    let s = sym[i]
    if st_bind(s.info) == STB_GLOBAL && s.section == SHN_UNDEF {
      let (_, _, version, library) = self.gnu_version(i)
      all.push(ImportedSymbol::{ name: s.name, version, library })
    }
  }
  all
}

///|
/// VersionIndex is the type of a Symbol version index.
pub struct VersionIndex(UInt16) derive(Show, ToJson, Eq)

///|
/// IsHidden reports whether the symbol is hidden within the version.
/// This means that the symbol can only be seen by specifying the exact version.
pub fn VersionIndex::is_hidden(self : VersionIndex) -> Bool {
  (self.0 & 0x8000) != 0
}

///|
/// Index returns the version index.
/// If this is the value 0, it means that the symbol is local,
/// and is not visible externally.
/// If this is the value 1, it means that the symbol is in the base version,
/// and has no specific version; it may or may not match a
/// [DynamicVersion.Index] in the slice returned by [File.DynamicVersions].
/// Other values will match either [DynamicVersion.Index]
/// in the slice returned by [File.DynamicVersions],
/// or [DynamicVersionDep.Index] in the Needs field
/// of the elements of the slice returned by [File.DynamicVersionNeeds].
/// In general, a defined symbol will have an index referring
/// to DynamicVersions, and an undefined symbol will have an index
/// referring to some version in DynamicVersionNeeds.
pub fn VersionIndex::index(self : VersionIndex) -> UInt16 {
  self.0 & 0x7fff
}

///|
/// Create a new VersionIndex
pub fn VersionIndex::new(value : UInt16) -> VersionIndex {
  VersionIndex(value)
}

///|
/// DynamicVersion is a version defined by a dynamic object.
pub struct DynamicVersion {
  /// Name of version defined by this index.
  name : String
  /// Version index.
  index : UInt16
  flags : DynamicVersionFlag
  /// Names of versions that this version depends upon.
  deps : Array[String]
} derive(Show, ToJson)

///|
/// DynamicVersionNeed describes a shared library needed by a dynamic object.
pub struct DynamicVersionNeed {
  /// Shared library name.
  name : String
  /// Dependencies.
  needs : Array[DynamicVersionDep]
} derive(Show, ToJson)

///|
/// DynamicVersionDep is a version needed from some shared library.
pub struct DynamicVersionDep {
  flags : DynamicVersionFlag
  /// Version index.
  index : UInt16
  /// Name of required version.
  dep : String
} derive(Show, ToJson)

///|
priv suberror SectionHasInvalidStringTableLink

///|
impl Show for SectionHasInvalidStringTableLink with output(
  _ : SectionHasInvalidStringTableLink,
  logger : &Logger,
) -> Unit {
  logger.write_string("section has invalid string table link")
}

///|
/// gnuVersionInit parses the GNU version tables
/// for use by calls to gnuVersion.
/// It reports whether any version tables were found.
fn File::gnu_version_init(self : File, str : Bytes) -> Bool {
  // FIXME: Implementation needed
  false
}

///|
/// gnuVersion adds Library and Version information to sym,
/// which came from offset i of the symbol table.
fn File::gnu_version(
  self : File,
  i : Int,
) -> (Bool, VersionIndex, String, String) {
  // FIXME: Implementation needed
  (false, VersionIndex::new(0), "", "")
}

///|
/// ImportedLibraries returns the names of all libraries
/// referred to by the binary f that are expected to be
/// linked with the binary at dynamic link time.
pub fn File::imported_libraries(self : File) -> Array[String] raise {
  self.dyn_string(DT_NEEDED)
}

///|
/// DynString returns the strings listed for the given tag in the file's dynamic
/// section.
///
/// The tag must be one that takes string values: DT_NEEDED, DT_SONAME, DT_RPATH, or
/// DT_RUNPATH.
pub fn File::dyn_string(self : File, tag : DynTag) -> Array[String] raise {
  match tag {
    DT_NEEDED | DT_SONAME | DT_RPATH | DT_RUNPATH => ()
    _ =>
      raise FormatError::new(
        off=0,
        msg="non-string-valued tag",
        val=tag.to_int().to_string(),
      )
  }

  // FIXME: This is a placeholder implementation
  // The real implementation would:
  // 1. Find the SHT_DYNAMIC section
  // 2. Parse dynamic entries
  // 3. Find entries matching the tag
  // 4. Look up strings in the string table
  []
}

///|
/// DynValue returns the values listed for the given tag in the file's dynamic
/// section.
fn File::dyn_value(self : File, tag : DynTag) -> Array[UInt64] {
  // FIXME: This is a placeholder implementation
  []
}

///|
priv struct NobitsSectionReader {}

///|
priv suberror UnexpectedReadFromSntNobitsSection

///|
impl @io.ReaderAt for NobitsSectionReader with read_at(
  _ : NobitsSectionReader,
  p : @slice.Slice[Byte],
  off : Int64,
) -> Int raise {
  raise UnexpectedReadFromSntNobitsSection
}
