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
pub impl @binary.Readable for FileHeader with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> FileHeader raise {
  FileHeader::{
    cpu: Cpu::from_uint(@binary.read(r, byte_order)),
    sub_cpu: @binary.read(r, byte_order),
    type_: Type::from_uint(@binary.read(r, byte_order)),
    ncmd: @binary.read(r, byte_order),
    cmdsz: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    magic: @binary.read(r, byte_order),
  }
}

///|
pub enum ByteOrder {
  Little
  Big
} derive(Eq, Show)

///|
pub trait Load {
  raw(Self) -> @slice.Slice[Byte]
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
pub impl Load for LoadCommand with raw(self) {
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
pub struct LoadBytes(@slice.Slice[Byte]) derive(Eq, Show)

///|
pub impl Load for LoadBytes with raw(self) {
  self.0
}

///|
pub struct SegmentHeader {
  cmd : LoadCmd
  len : UInt
  name : @slice.Slice[Byte]
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
  data : @slice.Slice[Byte]?
} derive(Eq, Show)

///|
pub impl Load for Segment with raw(self) {
  self.load_bytes.raw()
}

///|
pub fn Segment::data(
  self : Segment,
  file_data : @slice.Slice[Byte],
) -> @slice.Slice[Byte] raise {
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
  name : @slice.Slice[Byte]
  seg : @slice.Slice[Byte]
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
  data : @slice.Slice[Byte]?
} derive(Eq, Show)

///|
pub fn Section::data(
  self : Section,
  file_data : @slice.Slice[Byte],
) -> @slice.Slice[Byte] raise {
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
  name : String
  time : UInt
  current_version : UInt
  compat_version : UInt
} derive(Show)

///|
pub impl Load for Dylib with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Symbol {
  name : String
  type_ : Byte
  sect : Byte
  desc : UInt16
  value : UInt64
} derive(Eq, Show)

///|
pub struct Symtab {
  load_bytes : LoadBytes
  symtab_cmd : SymtabCmd
  syms : Array[Symbol]
} derive(Show)

///|
pub impl Load for Symtab with raw(self) {
  self.load_bytes.raw()
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
pub impl Load for Dysymtab with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Rpath {
  load_bytes : LoadBytes
  path : String
} derive(Show)

///|
pub impl Load for Rpath with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Thread {
  load_bytes : LoadBytes
  type_ : UInt
  data : Array[UInt]
} derive(Eq, Show)

///|
pub impl Load for Thread with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct File {
  header : FileHeader
  byte_order : ByteOrder
  loads : Array[LoadCommand]
  sections : Array[Section]
  symtab : Symtab?
  dysymtab : Dysymtab?
  priv mut closer : &@io.Closer?
}

///|
pub impl Show for File with output(self : File, logger : &Logger) -> Unit {
  logger.write_string("File { header: ")
  self.header.output(logger)
  logger.write_string(", byte_order: ")
  self.byte_order.output(logger)
  logger.write_string(", loads: ")
  self.loads.output(logger)
  logger.write_string(", sections: ")
  self.sections.output(logger)
  logger.write_string(", symtab: ")
  self.symtab.output(logger)
  logger.write_string(", dysymtab: ")
  self.dysymtab.output(logger)
  logger.write_string(" }")
}

///|
suberror FormatError {
  FormatError(off~ : Int64, msg~ : String, val~ : String?)
  FileTooSmall(actual_size~ : Int, required_size~ : Int)
  InvalidMagic(magic~ : UInt)
  CommandDataOverflow(offset~ : Int, size~ : UInt, file_size~ : Int)
}

///|
fn FormatError::new(off : Int64, msg : String, val : &Show?) -> FormatError {
  FormatError(off~, msg~, val=val.map(_.to_string()))
}

///|
pub impl Show for FormatError with output(self : FormatError, logger : &Logger) -> Unit {
  match self {
    FormatError(off~, msg~, val~) => {
      logger.write_string(msg)
      if val is Some(val) {
        logger.write_string(" '\{val}'")
      }
      logger.write_string(" in record at byte \{off.to_string(radix=16)}")
    }
    FileTooSmall(actual_size~, required_size~) =>
      logger.write_string(
        "file too small: actual size \{actual_size}, required \{required_size}",
      )
    InvalidMagic(magic~) =>
      logger.write_string("invalid magic number: \{magic.to_string(radix=16)}")
    CommandDataOverflow(offset~, size~, file_size~) =>
      logger.write_string(
        "command data overflow at offset \{offset}: size \{size}, file size \{file_size}",
      )
  }
}

///|
priv suberror ParseError {
  InvalidCommandSize(offset~ : Int, size~ : UInt)
  SegmentTooSmall(offset~ : Int64, command_type~ : String)
  SectionDataOverflow(offset~ : Int64, section_type~ : String)
  MissingData(offset~ : Int64, expected~ : String)
}

///|
priv suberror BufferOverflowError {
  ReadOverflow(
    offset~ : Int,
    length~ : Int,
    buffer_size~ : Int,
    operation~ : String
  )
}

///|
priv suberror InvalidDataError {
  InvalidOffset(offset~ : Int, max_offset~ : Int, context~ : String)
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
pub impl @binary.Readable for SymtabCmd with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> SymtabCmd raise {
  SymtabCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    symoff: @binary.read(r, byte_order),
    nsyms: @binary.read(r, byte_order),
    stroff: @binary.read(r, byte_order),
    strsize: @binary.read(r, byte_order),
  }
}

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
pub impl @binary.Readable for DylibCmd with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> DylibCmd raise {
  DylibCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    name: @binary.read(r, byte_order),
    time: @binary.read(r, byte_order),
    current_version: @binary.read(r, byte_order),
    compat_version: @binary.read(r, byte_order),
  }
}

///|
struct RpathCmd {
  cmd : UInt
  len : UInt
  path : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for RpathCmd with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> RpathCmd raise {
  RpathCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    path: @binary.read(r, byte_order),
  }
}

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
struct Nlist32 {
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
  desc : UInt16
  value : UInt64
} derive(Eq, Show)

///|
pub impl @binary.Readable for Nlist32 with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> Nlist32 raise {
  Nlist32::{
    name: @binary.read(r, byte_order),
    type_: @binary.read(r, byte_order),
    sect: @binary.read(r, byte_order),
    desc: @binary.read(r, byte_order),
    value: @binary.read(r, byte_order),
  }
}

///|
pub impl @binary.Readable for Nlist64 with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> Nlist64 raise {
  Nlist64::{
    name: @binary.read(r, byte_order),
    type_: @binary.read(r, byte_order),
    sect: @binary.read(r, byte_order),
    desc: @binary.read(r, byte_order),
    value: @binary.read(r, byte_order),
  }
}
