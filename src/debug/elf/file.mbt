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
  priv mut gnu_versym : @slice.Slice[Byte] // Simplified - using Bytes instead of slice
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
pub fn Section::data(self : Section) -> @slice.Slice[Byte] raise {
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
fn File::string_table(self : File, link : UInt) -> @slice.Slice[Byte] raise {
  if link <= 0 || link >= self.sections.length().reinterpret_as_uint() {
    fail("section has invalid string table link")
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
  match self.sr {
    Some(sr) => @io.new_section_reader(sr, 0, 1L << (63 - 1))
    None =>
      raise FormatError::new(
        off=self.prog_header.off.reinterpret_as_int64(),
        msg="program has no data reader",
      )
  }
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
    gnu_versym: @slice.make(0),
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
) -> (Array[Symbol], @slice.Slice[Byte]) raise {
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
) -> (Array[Symbol], @slice.Slice[Byte]) raise {
  let symtab_section = match self.section_by_type(typ) {
    Some(s) => s
    None => raise NoSymbolsError
  }
  let data = symtab_section.data() catch {
    err => fail("cannot load symbol section: \{err}")
  }
  if data.length() == 0 {
    fail("symbol section is empty")
  }
  if data.length() % Sym32Size != 0 {
    fail("length of symbol section is not a multiple of SymSize")
  }
  let strdata = self.string_table(symtab_section.section_header.link) catch {
    err => fail("cannot load string table section: \{err}")
  }
  let symbols : Array[Symbol] = []
  // The first entry is all zeros.
  for offset = Sym32Size; offset < data.length(); offset = offset + Sym32Size {
    let sym_data = data[offset:offset + Sym32Size]
    let bo = self.file_header.byte_order
    let name_idx = bo.uint32(sym_data[0:4])
    let value = bo.uint32(sym_data[4:8]).to_uint64()
    let size = bo.uint32(sym_data[8:12]).to_uint64()
    let info = sym_data[12]
    let other = sym_data[13]
    let shndx = bo.uint16(sym_data[14:16])
    let (name, _) = get_string(strdata, name_idx.reinterpret_as_int())
    symbols.push(Symbol::{
      name,
      info,
      other,
      has_version: false,
      version_index: VersionIndex::new(0),
      section: SectionIndex::from_int(shndx.to_int()),
      value,
      size,
      version: "",
      library: "",
    })
  }
  (symbols, strdata)
}

///|
fn File::get_symbols64(
  self : File,
  typ : SectionType,
) -> (Array[Symbol], @slice.Slice[Byte]) raise {
  let symtab_section = match self.section_by_type(typ) {
    Some(s) => s
    None => raise NoSymbolsError
  }
  let data = symtab_section.data()
  if data.length() % Sym64Size != 0 {
    raise FormatError::new(
      off=symtab_section.section_header.offset.reinterpret_as_int64(),
      msg="length of symbol section is not a multiple of Sym64Size",
    )
  }
  let strdata = self.string_table(symtab_section.section_header.link)

  // The first entry is all zeros, skip it
  let symbols : Array[Symbol] = []
  for offset = Sym64Size; offset < data.length(); offset = offset + Sym64Size {
    let sym_data = data[offset:offset + Sym64Size]
    let bo = self.file_header.byte_order
    let name_idx = bo.uint32(sym_data[0:4])
    let info = sym_data[4]
    let other = sym_data[5]
    let shndx = bo.uint16(sym_data[6:8])
    let value = bo.uint64(sym_data[8:16])
    let size = bo.uint64(sym_data[16:24])
    let (name, _) = get_string(strdata, name_idx.to_int())
    symbols.push(Symbol::{
      name,
      info,
      other,
      has_version: false,
      version_index: VersionIndex::new(0),
      section: SectionIndex::from_int(shndx.to_int()),
      value,
      size,
      version: "",
      library: "",
    })
  }
  (symbols, strdata)
}

///|
/// getString extracts a string from an ELF string table.
fn get_string(section : @slice.Slice[Byte], start : Int) -> (String, Bool) {
  if start < 0 || start >= section.length() {
    return ("", false)
  }
  for end in start..<section.length() {
    if section[end] == 0 {
      return (@utf8.decode_lossy(section[start:end]), true)
    }
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
  let (sym, _) = self.get_symbols(SHT_SYMTAB)
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
  let (sym, str) = self.get_symbols(SHT_DYNSYM)
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
  let (sym, str) = self.get_symbols(SHT_DYNSYM)
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
fn File::_dynamic_versions(self : File, str : @slice.Slice[Byte]) -> Unit raise {
  ...
}

///|
pub fn File::dynamic_versions(self : File) -> Array[DynamicVersion] raise {
  ...
}

///|
fn File::_dynamic_version_needs(
  self : File,
  str : @slice.Slice[Byte],
) -> Unit raise {
  ...
}

///|
pub fn File::dynamic_version_needs(
  self : File,
) -> Array[DynamicVersionNeed] raise {
  ...
}

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
fn File::gnu_version_init(self : File, str : @slice.Slice[Byte]) -> Bool raise {
  guard self.section_by_type(SHT_GNU_VERSYM) is Some(vs) else { return false }
  let d = vs.data()
  self.gnu_versym = d
  self._dynamic_versions(str)
  self._dynamic_version_needs(str)
  return true
}

///|
/// gnuVersion adds Library and Version information to sym,
/// which came from offset i of the symbol table.
fn File::gnu_version(
  self : File,
  i : Int,
) -> (Bool, VersionIndex, String, String) {
  let i = (i + 1) * 2
  if i >= self.gnu_versym.length() {
    return (false, VersionIndex::new(0), "", "")
  }
  let s = self.gnu_versym[i:]
  if s.length() < 2 {
    return (false, 0, "", "")
  }
  let vi = VersionIndex::new(self.file_header.byte_order.uint16(s))
  let ndx = vi.index()
  if ndx == 0 || ndx == 1 {
    return (true, vi, "", "")
  }
  for v in self.dyn_ver_needs {
    for n in v.needs {
      if ndx == n.index {
        return (true, vi, n.dep, v.name)
      }
    }
  }
  for v in self.dyn_vers {
    if ndx == v.index {
      return (true, vi, v.name, "")
    }
  }
  return (false, VersionIndex::new(0), "", "")
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
  let ds = match self.section_by_type(SHT_DYNAMIC) {
    Some(s) => s
    None => return [] // not dynamic, so no libraries
  }
  let d = ds.data()
  let dyn_size = if self.file_header.class is ELFCLASS64 { 16 } else { 8 }
  if d.length() % dyn_size != 0 {
    fail("length of dynamic section is not a multiple of dynamic entry size")
  }
  let str = self.string_table(ds.section_header.link)
  let all : Array[String] = []
  let bo = self.file_header.byte_order
  let mut offset = 0
  while offset + dyn_size <= d.length() {
    let dyn_data = d[offset:offset + dyn_size]
    let (t, v) = match self.file_header.class {
      ELFCLASS32 => {
        let tag_val = bo.uint32(dyn_data[0:4])
        let val = bo.uint32(dyn_data[4:8]).to_uint64()
        (DynTag::from_int(tag_val.reinterpret_as_int()), val)
      }
      ELFCLASS64 => {
        let tag_val = bo.uint64(dyn_data[0:8])
        let val = bo.uint64(dyn_data[8:16])
        (DynTag::from_int(tag_val.to_int()), val)
      }
      _ => (DT_NULL, 0UL)
    }
    if t == tag {
      let (s, ok) = get_string(str, v.to_int())
      if ok {
        all.push(s)
      }
    }
    offset = offset + dyn_size
  }
  all
}

///|
/// DynValue returns the values listed for the given tag in the file's dynamic
/// section.
fn File::dyn_value(self : File, tag : DynTag) -> Array[UInt64] raise {
  let ds = match self.section_by_type(SHT_DYNAMIC) {
    Some(s) => s
    None => return []
  }
  let d = ds.data()
  let dyn_size = if self.file_header.class is ELFCLASS64 { 16 } else { 8 }
  if d.length() % dyn_size != 0 {
    fail("length of dynamic section is not a multiple of dynamic entry size")
  }
  let vals : Array[UInt64] = []
  let bo = self.file_header.byte_order
  let mut offset = 0
  while offset + dyn_size <= d.length() {
    let dyn_data = d[offset:offset + dyn_size]
    let (t, v) = match self.file_header.class {
      ELFCLASS32 => {
        let tag_val = bo.uint32(dyn_data[0:4])
        let val = bo.uint32(dyn_data[4:8]).to_uint64()
        (DynTag::from_int(tag_val.reinterpret_as_int()), val)
      }
      ELFCLASS64 => {
        let tag_val = bo.uint64(dyn_data[0:8])
        let val = bo.uint64(dyn_data[8:16])
        (DynTag::from_int(tag_val.to_int()), val)
      }
      _ => (DT_NULL, 0UL)
    }
    if t == tag {
      vals.push(v)
    }
    offset = offset + dyn_size
  }
  vals
}

///|
priv struct NobitsSectionReader {}

///|
priv suberror UnexpectedReadFromSntNobitsSection

///|
impl @io.ReaderAt for NobitsSectionReader with read_at(
  _ : NobitsSectionReader,
  _ : @slice.Slice[Byte],
  _ : Int64,
) -> Int raise {
  raise UnexpectedReadFromSntNobitsSection
}
