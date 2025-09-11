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
  priv closer : &@io.Closer?
  priv dyn_vers : Array[DynamicVersion]
  priv dyn_ver_needs : Array[DynamicVersionNeed]
  priv gnu_versym : @slice.Slice[Byte] // Omitted for now since Bytes doesn't implement ToJson
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
/// A Section represents a single section in an ELF file.
pub struct Section {
  section_header : SectionHeader
  /// ReaderAt may be nil if the section is not easily available
  /// in a random-access form. For example, a compressed section
  /// may have a nil ReaderAt.
  // reader_at : Option[&@io.ReaderAt]  // Omitted for now
  // sr : Option[@io.SectionReader]     // Omitted for now
  compression_type : CompressionType
  compression_offset : Int64
} derive(Show, ToJson)

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
  /// ReaderAt for ReadAt method.
  // reader_at : Option[&@io.ReaderAt]  // Omitted for now
  // sr : Option[@io.SectionReader]     // Omitted for now
} derive(Show, ToJson)

///|
/// A Symbol represents an entry in an ELF symbol table section.
pub struct Symbol {
  name : String
  info : Byte
  other : Byte
  /// HasVersion reports whether the symbol has any version information.
  /// This will only be true for the dynamic symbol table.
  has_version : Bool
  /// VersionIndex is the symbol's version index.
  /// This field is only meaningful if HasVersion is true.
  version_index : VersionIndex
  section : SectionIndex
  value : UInt64
  size : UInt64
  /// These fields are present only for the dynamic symbol table.
  version : String
  library : String
} derive(Show, ToJson)

///|
/// FormatError is used to indicate an error in the ELF format.
pub struct FormatError {
  off : Int64
  msg : String
  val : String // Simplified from Go's `any`
} derive(Show, ToJson)

///|
pub fn FormatError::error_message(self : FormatError) -> String {
  let msg = self.msg
  let msg = if self.val.is_empty() { msg } else { msg + " '" + self.val + "' " }
  msg + "in record at byte 0x" + self.off.to_string()
}

///|
pub(all) suberror ElfError {
  Format(FormatError)
  NoSymbols
  InvalidOffset(Int64)
  BadMagic(Bytes)
  UnknownClass(Class)
  UnknownData(Data)
  UnknownVersion(Version)
  MismatchedVersion(Version)
  InvalidShoff(Int64)
  InvalidPhoff(Int64)
  InvalidShnum(Int)
  InvalidShstrndx(Int)
  InvalidPhentsize(Int)
  InvalidShentsize(Int)
  TooManySections(Int)
  SectionHeaderOverflow(Int)
  InvalidSectionOffset(Int64)
  InvalidSectionSize(Int64)
  BadSectionNameIndex(UInt)
  NotImplemented(String)
}

///|
/// VersionIndex is the type of a Symbol version index.
pub struct VersionIndex {
  value : UInt
} derive(Show, ToJson, Eq)

///|
/// IsHidden reports whether the symbol is hidden within the version.
pub fn VersionIndex::is_hidden(self : VersionIndex) -> Bool {
  (self.value & 0x8000U) != 0U
}

///|
/// Index returns the version index.
pub fn VersionIndex::index(self : VersionIndex) -> UInt {
  self.value & 0x7fffU
}

///|
/// Create a new VersionIndex
pub fn VersionIndex::new(value : UInt) -> VersionIndex {
  VersionIndex::{ value, }
}

///|
/// DynamicVersionFlag represents flags for dynamic versions.
pub struct DynamicVersionFlag {
  value : UInt
} derive(Show, ToJson, Eq)

///|
/// Create a new DynamicVersionFlag
pub fn DynamicVersionFlag::new(value : UInt) -> DynamicVersionFlag {
  DynamicVersionFlag::{ value, }
}

///|
/// DynamicVersion is a version defined by a dynamic object.
pub struct DynamicVersion {
  /// Name of version defined by this index.
  /// Version index.
  name : String
  index : UInt
  flags : DynamicVersionFlag
  /// Names of versions that this version depends upon.
  deps : Array[String]
} derive(Show, ToJson)

///|
/// DynamicVersionNeed describes a shared library needed by a dynamic object.
pub struct DynamicVersionNeed {
  /// Shared library name.
  /// Dependencies.
  name : String
  needs : Array[DynamicVersionDep]
} derive(Show, ToJson)

///|
/// DynamicVersionDep is a version needed from some shared library.
pub struct DynamicVersionDep {
  flags : DynamicVersionFlag
  /// Version index.
  /// Name of required version.
  index : UInt
  dep : String
} derive(Show, ToJson)

///|
/// ImportedSymbol represents a symbol imported from a shared library.
pub struct ImportedSymbol {
  name : String
  version : String
  library : String
} derive(Show, ToJson)
