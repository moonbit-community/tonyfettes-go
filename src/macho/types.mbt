///|
pub struct FileHeader {
  magic : UInt
  cpu : Cpu
  sub_cpu : UInt
  type_ : Type
  ncmd : UInt
  cmdsz : UInt
  flags : UInt
} derive(Eq, Show)

///|
pub enum ByteOrder {
  Little
  Big
} derive(Eq, Show)

///|
pub trait Load {
  raw(Self) -> Bytes
}

///|
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
pub struct LoadBytes {
  data : Bytes
} derive(Eq, Show)

///|
impl Load for LoadBytes with raw(self) {
  self.data
}

///|
pub struct SegmentHeader {
  cmd : LoadCmd
  len : UInt
  name : Bytes
  addr : UInt64
  memsz : UInt64
  offset : UInt64
  filesz : UInt64
  maxprot : UInt
  prot : UInt
  nsect : UInt
  flag : UInt
} derive(Eq, Show)

///|
pub struct Segment {
  load_bytes : LoadBytes
  header : SegmentHeader
  data : Bytes?
} derive(Eq, Show)

///|
impl Load for Segment with raw(self) {
  self.load_bytes.data
}

///|
pub fn Segment::data(self : Segment, file_data : Bytes) -> Bytes raise {
  match self.data {
    Some(data) => data
    None => {
      let offset = self.header.offset.to_uint().reinterpret_as_int()
      let size = self.header.filesz.to_uint().reinterpret_as_int()
      if file_data.length() < offset + size {
        raise ParseError::MissingData(
          offset=offset.to_int64(),
          expected="Segment data (" + size.to_string() + " bytes)",
        )
      }
      read_bytes(file_data, offset, size)
    }
  }
}

///|
pub struct SectionHeader {
  name : Bytes
  seg : Bytes
  addr : UInt64
  size : UInt64
  offset : UInt
  align : UInt
  reloff : UInt
  nreloc : UInt
  flags : UInt
} derive(Eq, Show)

///|
pub struct Reloc {
  addr : UInt
  value : UInt
  type_ : Int
  len : Int
  pcrel : Bool
  is_extern : Bool
  scattered : Bool
} derive(Eq, Show)

///|
pub struct Section {
  header : SectionHeader
  relocs : Array[Reloc]
  data : Bytes?
} derive(Eq, Show)

///|
pub fn Section::data(self : Section, file_data : Bytes) -> Bytes raise {
  match self.data {
    Some(data) => data
    None => {
      let offset = self.header.offset.reinterpret_as_int()
      let size = self.header.size.to_uint().reinterpret_as_int()
      if file_data.length() < offset + size {
        raise ParseError::MissingData(
          offset=offset.to_int64(),
          expected="Section data (" + size.to_string() + " bytes)",
        )
      }
      read_bytes(file_data, offset, size)
    }
  }
}

///|
pub struct Dylib {
  load_bytes : LoadBytes
  name : Bytes
  time : UInt
  current_version : UInt
  compat_version : UInt
} derive(Eq, Show)

///|
impl Load for Dylib with raw(self) {
  self.load_bytes.data
}

///|
pub struct Symbol {
  name : Bytes
  type_ : Int
  sect : Int
  desc : Int
  value : UInt64
} derive(Eq, Show)

///|
pub struct Symtab {
  load_bytes : LoadBytes
  symoff : UInt
  nsyms : UInt
  stroff : UInt
  strsize : UInt
  syms : Array[Symbol]
} derive(Eq, Show)

///|
impl Load for Symtab with raw(self) {
  self.load_bytes.data
}

///|
pub struct Dysymtab {
  load_bytes : LoadBytes
  ilocalsym : UInt
  nlocalsym : UInt
  iextdefsym : UInt
  nextdefsym : UInt
  iundefsym : UInt
  nundefsym : UInt
  tocoffset : UInt
  ntoc : UInt
  modtaboff : UInt
  nmodtab : UInt
  extrefsymoff : UInt
  nextrefsyms : UInt
  indirectsymoff : UInt
  nindirectsyms : UInt
  extreloff : UInt
  nextrel : UInt
  locreloff : UInt
  nlocrel : UInt
  indirect_syms : Array[UInt]
} derive(Eq, Show)

///|
impl Load for Dysymtab with raw(self) {
  self.load_bytes.data
}

///|
pub struct Rpath {
  load_bytes : LoadBytes
  path : Bytes
} derive(Eq, Show)

///|
impl Load for Rpath with raw(self) {
  self.load_bytes.data
}

///|
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
pub struct File {
  header : FileHeader
  byte_order : ByteOrder
  loads : Array[LoadCommand]
  sections : Array[Section]
  symtab : Symtab?
  dysymtab : Dysymtab?
} derive(Show)

///|
suberror FormatError {
  InvalidMagic(magic~ : UInt)
  FileTooSmall(actual_size~ : Int, required_size~ : Int)
  InvalidHeader(offset~ : Int64, message~ : String)
  CommandDataOverflow(offset~ : Int64, size~ : UInt, file_size~ : Int)
}

///|
suberror ParseError {
  InvalidCommandSize(offset~ : Int, size~ : UInt)
  SegmentTooSmall(offset~ : Int64, command_type~ : String)
  SectionDataOverflow(offset~ : Int64, section_type~ : String)
  MissingData(offset~ : Int64, expected~ : String)
}

///|
suberror BufferOverflowError {
  ReadOverflow(
    offset~ : Int,
    length~ : Int,
    buffer_size~ : Int,
    operation~ : String
  )
}

///|
suberror InvalidDataError {
  InvalidOffset(offset~ : Int, max_offset~ : Int, context~ : String)
  InvalidIndex(index~ : Int, max_index~ : Int, context~ : String)
  MalformedString(offset~ : Int, context~ : String)
}

///|
pub struct Segment32 {
  cmd : UInt
  len : UInt
  name : FixedArray[Byte]
  addr : UInt
  memsz : UInt
  offset : UInt
  filesz : UInt
  maxprot : UInt
  prot : UInt
  nsect : UInt
  flag : UInt
} derive(Eq, Show)

///|
pub struct Segment64 {
  cmd : UInt
  len : UInt
  name : FixedArray[Byte]
  addr : UInt64
  memsz : UInt64
  offset : UInt64
  filesz : UInt64
  maxprot : UInt
  prot : UInt
  nsect : UInt
  flag : UInt
} derive(Eq, Show)

///|
pub struct SymtabCmd {
  cmd : UInt
  len : UInt
  symoff : UInt
  nsyms : UInt
  stroff : UInt
  strsize : UInt
} derive(Eq, Show)

///|
pub struct DysymtabCmd {
  cmd : UInt
  len : UInt
  ilocalsym : UInt
  nlocalsym : UInt
  iextdefsym : UInt
  nextdefsym : UInt
  iundefsym : UInt
  nundefsym : UInt
  tocoffset : UInt
  ntoc : UInt
  modtaboff : UInt
  nmodtab : UInt
  extrefsymoff : UInt
  nextrefsyms : UInt
  indirectsymoff : UInt
  nindirectsyms : UInt
  extreloff : UInt
  nextrel : UInt
  locreloff : UInt
  nlocrel : UInt
} derive(Eq, Show)

///|
pub struct DylibCmd {
  cmd : UInt
  len : UInt
  name : UInt
  time : UInt
  current_version : UInt
  compat_version : UInt
} derive(Eq, Show)

///|
pub struct RpathCmd {
  cmd : UInt
  len : UInt
  path : UInt
} derive(Eq, Show)

///|
pub struct Section32 {
  name : FixedArray[Byte]
  seg : FixedArray[Byte]
  addr : UInt
  size : UInt
  offset : UInt
  align : UInt
  reloff : UInt
  nreloc : UInt
  flags : UInt
  reserve1 : UInt
  reserve2 : UInt
} derive(Eq, Show)

///|
pub struct Section64 {
  name : FixedArray[Byte]
  seg : FixedArray[Byte]
  addr : UInt64
  size : UInt64
  offset : UInt
  align : UInt
  reloff : UInt
  nreloc : UInt
  flags : UInt
  reserve1 : UInt
  reserve2 : UInt
  reserve3 : UInt
} derive(Eq, Show)

///|
pub struct Nlist32 {
  name : UInt
  type_ : Byte
  sect : Byte
  desc : UInt
  value : UInt
} derive(Eq, Show)

///|
pub struct Nlist64 {
  name : UInt
  type_ : Byte
  sect : Byte
  desc : UInt
  value : UInt64
} derive(Eq, Show)
