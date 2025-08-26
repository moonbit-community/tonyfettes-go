///| Core data structures for Mach-O file format

///| Based on Go's debug/macho package

///|
/// A FileHeader represents a Mach-O file header.
pub struct FileHeader {
  magic : UInt // Magic number
  cpu : Cpu // CPU type
  sub_cpu : UInt // CPU subtype
  type_ : Type // File type
  ncmd : UInt // Number of load commands
  cmdsz : UInt // Size of load commands
  flags : UInt // Flags
} derive(Eq, Show)

///|
/// ByteOrder represents the byte order of the file
pub enum ByteOrder {
  Little
  Big
} derive(Eq, Show)

///|
/// A Load represents any Mach-O load command.
pub trait Load {
  raw(Self) -> Bytes
}

///|
/// LoadCommand enum to represent different types of load commands
pub enum LoadCommand {
  LoadBytes(LoadBytes)
  Segment(Segment)
  Dylib(Dylib)
  Symtab(Symtab)
  Dysymtab(Dysymtab)
  Rpath(Rpath)
  Thread(Thread)
} derive(Show)

///|
impl Load for LoadCommand with raw(self) {
  match self {
    LoadBytes(load_bytes) => load_bytes.raw()
    Segment(segment) => segment.raw()
    Dylib(dylib) => dylib.raw()
    Symtab(symtab) => symtab.raw()
    Dysymtab(dysymtab) => dysymtab.raw()
    Rpath(rpath) => rpath.raw()
    Thread(thread) => thread.raw()
  }
}

///|
/// A LoadBytes is the uninterpreted bytes of a Mach-O load command.
pub struct LoadBytes {
  data : Bytes
} derive(Eq, Show)

///|
impl Load for LoadBytes with raw(self) {
  self.data
}

///|
/// A SegmentHeader is the header for a Mach-O 32-bit or 64-bit load segment command.
pub struct SegmentHeader {
  cmd : LoadCmd // Command type
  len : UInt // Command length
  name : String // Segment name
  addr : UInt64 // Virtual memory address
  memsz : UInt64 // Virtual memory size
  offset : UInt64 // File offset
  filesz : UInt64 // File size
  maxprot : UInt // Maximum VM protection
  prot : UInt // Initial VM protection
  nsect : UInt // Number of sections
  flag : UInt // Flags
} derive(Eq, Show)

///|
/// A Segment represents a Mach-O 32-bit or 64-bit load segment command.
pub struct Segment {
  load_bytes : LoadBytes
  header : SegmentHeader
  data : Bytes? // Segment data (loaded on demand)
} derive(Eq, Show)

///|
impl Load for Segment with raw(self) {
  self.load_bytes.data
}

///|
/// SectionHeader contains the metadata for a section.
pub struct SectionHeader {
  name : String // Section name
  seg : String // Segment name
  addr : UInt64 // Memory address
  size : UInt64 // Size in bytes
  offset : UInt // File offset
  align : UInt // Section alignment (power of 2)
  reloff : UInt // File offset to relocation entries
  nreloc : UInt // Number of relocation entries
  flags : UInt // Section flags
} derive(Eq, Show)

///|
/// A Reloc represents a Mach-O relocation.
pub struct Reloc {
  addr : UInt // Address
  value : UInt // Value
  type_ : Int // Relocation type
  len : Int // Length (0=byte, 1=word, 2=long, 3=quad)
  pcrel : Bool // PC-relative
  is_extern : Bool // External symbol (valid if scattered == false)
  scattered : Bool // Scattered relocation
} derive(Eq, Show)

///|
/// A Section represents a Mach-O section.
pub struct Section {
  header : SectionHeader
  relocs : Array[Reloc]
  data : Bytes? // Section data (loaded on demand)
} derive(Eq, Show)

///|
/// A Dylib represents a Mach-O load dynamic library command.
pub struct Dylib {
  load_bytes : LoadBytes
  name : String
  time : UInt
  current_version : UInt
  compat_version : UInt
} derive(Eq, Show)

///|
impl Load for Dylib with raw(self) {
  self.load_bytes.data
}

///|
/// A Symbol is a Mach-O 32-bit or 64-bit symbol table entry.
pub struct Symbol {
  name : String
  type_ : Int
  sect : Int
  desc : Int
  value : UInt64
} derive(Eq, Show)

///|
/// A Symtab represents a Mach-O symbol table command.
pub struct Symtab {
  load_bytes : LoadBytes
  symoff : UInt // File offset to symbol table
  nsyms : UInt // Number of symbols
  stroff : UInt // File offset to string table
  strsize : UInt // String table size
  syms : Array[Symbol] // Symbols
} derive(Eq, Show)

///|
impl Load for Symtab with raw(self) {
  self.load_bytes.data
}

///|
/// A Dysymtab represents a Mach-O dynamic symbol table command.
pub struct Dysymtab {
  load_bytes : LoadBytes
  ilocalsym : UInt // Index to local symbols
  nlocalsym : UInt // Number of local symbols
  iextdefsym : UInt // Index to externally defined symbols
  nextdefsym : UInt // Number of externally defined symbols
  iundefsym : UInt // Index to undefined symbols
  nundefsym : UInt // Number of undefined symbols
  tocoffset : UInt // File offset to table of contents
  ntoc : UInt // Number of entries in table of contents
  modtaboff : UInt // File offset to module table
  nmodtab : UInt // Number of entries in module table
  extrefsymoff : UInt // File offset to referenced symbol table
  nextrefsyms : UInt // Number of referenced symbol table entries
  indirectsymoff : UInt // File offset to indirect symbol table
  nindirectsyms : UInt // Number of indirect symbol table entries
  extreloff : UInt // File offset to external relocation entries
  nextrel : UInt // Number of external relocation entries
  locreloff : UInt // File offset to local relocation entries
  nlocrel : UInt // Number of local relocation entries
  indirect_syms : Array[UInt] // Indices into Symtab.syms
} derive(Eq, Show)

///|
impl Load for Dysymtab with raw(self) {
  self.load_bytes.data
}

///|
/// A Rpath represents a Mach-O rpath command.
pub struct Rpath {
  load_bytes : LoadBytes
  path : String
} derive(Eq, Show)

///|
impl Load for Rpath with raw(self) {
  self.load_bytes.data
}

///|
/// A Thread represents a Mach-O thread state command.
pub struct Thread {
  load_bytes : LoadBytes
  type_ : UInt
  data : Array[UInt]
} derive(Eq, Show)

///|
impl Load for Thread with raw(self) {
  self.load_bytes.data
}

///|
/// A File represents an open Mach-O file.
pub struct File {
  header : FileHeader
  byte_order : ByteOrder
  loads : Array[LoadCommand]
  sections : Array[Section]
  symtab : Symtab?
  dysymtab : Dysymtab?
} derive(Show)

///|
/// FormatError is returned when the data does not have the correct format for a Mach-O file.
pub struct FormatError {
  offset : Int64
  message : String
  value : String?
} derive(Eq, Show)

///|
pub fn FormatError::to_string(self : FormatError) -> String {
  let base_msg = "Mach-O format error: " + self.message
  let msg = match self.value {
    Some(val) => base_msg + " '" + val + "'"
    None => base_msg
  }
  msg + " at offset " + self.offset.to_string()
}

///|
/// Raw data structures for binary parsing

///|

///|
/// 32-bit segment load command
pub struct Segment32 {
  cmd : UInt // Command type
  len : UInt // Command length
  name : FixedArray[Byte] // Segment name (16 bytes)
  addr : UInt // Virtual memory address
  memsz : UInt // Virtual memory size
  offset : UInt // File offset
  filesz : UInt // File size
  maxprot : UInt // Maximum VM protection
  prot : UInt // Initial VM protection
  nsect : UInt // Number of sections
  flag : UInt // Flags
} derive(Eq, Show)

///|
/// 64-bit segment load command
pub struct Segment64 {
  cmd : UInt // Command type
  len : UInt // Command length
  name : FixedArray[Byte] // Segment name (16 bytes)
  addr : UInt64 // Virtual memory address
  memsz : UInt64 // Virtual memory size
  offset : UInt64 // File offset
  filesz : UInt64 // File size
  maxprot : UInt // Maximum VM protection
  prot : UInt // Initial VM protection
  nsect : UInt // Number of sections
  flag : UInt // Flags
} derive(Eq, Show)

///|
/// Symbol table command
pub struct SymtabCmd {
  cmd : UInt // Command type
  len : UInt // Command length
  symoff : UInt // File offset to symbol table
  nsyms : UInt // Number of symbols
  stroff : UInt // File offset to string table
  strsize : UInt // String table size
} derive(Eq, Show)

///|
/// Dynamic symbol table command
pub struct DysymtabCmd {
  cmd : UInt // Command type
  len : UInt // Command length
  ilocalsym : UInt // Index to local symbols
  nlocalsym : UInt // Number of local symbols
  iextdefsym : UInt // Index to externally defined symbols
  nextdefsym : UInt // Number of externally defined symbols
  iundefsym : UInt // Index to undefined symbols
  nundefsym : UInt // Number of undefined symbols
  tocoffset : UInt // File offset to table of contents
  ntoc : UInt // Number of entries in table of contents
  modtaboff : UInt // File offset to module table
  nmodtab : UInt // Number of entries in module table
  extrefsymoff : UInt // File offset to referenced symbol table
  nextrefsyms : UInt // Number of referenced symbol table entries
  indirectsymoff : UInt // File offset to indirect symbol table
  nindirectsyms : UInt // Number of indirect symbol table entries
  extreloff : UInt // File offset to external relocation entries
  nextrel : UInt // Number of external relocation entries
  locreloff : UInt // File offset to local relocation entries
  nlocrel : UInt // Number of local relocation entries
} derive(Eq, Show)

///|
/// Dynamic library command
pub struct DylibCmd {
  cmd : UInt // Command type
  len : UInt // Command length
  name : UInt // Offset to library name
  time : UInt // Library's build time stamp
  current_version : UInt // Library's current version number
  compat_version : UInt // Library's compatibility version number
} derive(Eq, Show)

///|
/// Rpath command
pub struct RpathCmd {
  cmd : UInt // Command type
  len : UInt // Command length
  path : UInt // Offset to path string
} derive(Eq, Show)

///|
/// 32-bit section header
pub struct Section32 {
  name : FixedArray[Byte] // Section name (16 bytes)
  seg : FixedArray[Byte] // Segment name (16 bytes)
  addr : UInt // Memory address
  size : UInt // Size in bytes
  offset : UInt // File offset
  align : UInt // Section alignment (power of 2)
  reloff : UInt // File offset to relocation entries
  nreloc : UInt // Number of relocation entries
  flags : UInt // Section flags
  reserve1 : UInt // Reserved
  reserve2 : UInt // Reserved
} derive(Eq, Show)

///|
/// 64-bit section header
pub struct Section64 {
  name : FixedArray[Byte] // Section name (16 bytes)
  seg : FixedArray[Byte] // Segment name (16 bytes)
  addr : UInt64 // Memory address
  size : UInt64 // Size in bytes
  offset : UInt // File offset
  align : UInt // Section alignment (power of 2)
  reloff : UInt // File offset to relocation entries
  nreloc : UInt // Number of relocation entries
  flags : UInt // Section flags
  reserve1 : UInt // Reserved
  reserve2 : UInt // Reserved
  reserve3 : UInt // Reserved (64-bit only)
} derive(Eq, Show)

///|
/// 32-bit symbol table entry
pub struct Nlist32 {
  name : UInt // String table index
  type_ : Byte // Symbol type
  sect : Byte // Section number
  desc : UInt // Symbol description
  value : UInt // Symbol value
} derive(Eq, Show)

///|
/// 64-bit symbol table entry
pub struct Nlist64 {
  name : UInt // String table index
  type_ : Byte // Symbol type
  sect : Byte // Section number
  desc : UInt // Symbol description
  value : UInt64 // Symbol value
} derive(Eq, Show)
