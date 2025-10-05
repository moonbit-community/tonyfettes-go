///|
pub struct FileHeader {
  magic : UInt
  cpu : Cpu
  sub_cpu : UInt
  type_ : Type
  ncmd : UInt
  cmdsz : UInt
  flags : UInt
} derive(Eq, Show, Default)

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
}

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
pub struct LoadBytes(@slice.Slice[Byte])

///|
pub impl Load for LoadBytes with raw(self) {
  self.0
}

///|
pub struct SegmentHeader {
  cmd : LoadCmd
  len : UInt
  name : String
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
// A `Segment` represents a Mach-O 32-bit or 64-bit load segment command.
pub struct Segment {
  load_bytes : LoadBytes
  header : SegmentHeader
  reader_at : &@io.ReaderAt
  sr : @io.SectionReader
}

///|
pub impl Load for Segment with raw(self) {
  self.load_bytes.raw()
}

///|
/// `data` reads and returns the contents of the segment.
pub fn Segment::data(self : Segment) -> @slice.Slice[Byte] raise {
  @saferio.read_data_at(self.sr, self.header.filesz, 0)
}

///|
/// `open` returns a new `&@io.ReadSeeker` reading the segment.
pub fn Segment::open(self : Segment) -> &@io.ReadSeeker {
  return @io.new_section_reader(self.sr, 0, (1 << 63) - 1)
}

///|
pub struct SectionHeader {
  name : String
  seg : String
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
  type_ : Byte
  len : Byte
  pcrel : Bool
  is_extern : Bool
  scattered : Bool
} derive(Eq, Show)

///|
pub struct Section {
  header : SectionHeader
  relocs : Array[Reloc]
  reader_at : &@io.ReaderAt
  sr : @io.SectionReader
}

///|
/// `data` reads and returns the contents of the Mach-O section.
pub fn Section::data(self : Section) -> @slice.Slice[Byte] raise {
  @saferio.read_data_at(self.sr, self.header.size, 0)
}

///|
/// `open` returns a new `&@io.ReadSeeker` reading the Mach-O section.
pub fn Section::open(self : Section) -> &@io.ReadSeeker {
  return @io.new_section_reader(self.sr, 0, (1 << 63) - 1)
}

///|
pub struct Dylib {
  load_bytes : LoadBytes
  name : String
  time : UInt
  current_version : UInt
  compat_version : UInt
}

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
}

///|
pub impl Load for Symtab with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Dysymtab {
  load_bytes : LoadBytes
  dysymtab_cmd : DysymtabCmd
  indirect_syms : Array[UInt]
}

///|
pub impl Load for Dysymtab with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Rpath {
  load_bytes : LoadBytes
  path : String
}

///|
pub impl Load for Rpath with raw(self) {
  self.load_bytes.raw()
}

///|
pub struct Thread {
  load_bytes : LoadBytes
  type_ : UInt
  data : Array[UInt]
}

///|
pub impl Load for Thread with raw(self) {
  self.load_bytes.raw()
}

///|
/// A `File` represents an open Mach-O file.
pub struct File {
  header : FileHeader
  byte_order : &@binary.ByteOrder
  loads : Array[&Load]
  sections : Array[Section]
  symtab : Symtab?
  dysymtab : Dysymtab?
  closer : &@io.Closer?
}

///|
suberror FormatError {
  FormatError(off~ : Int64, msg~ : String, val~ : String?)
}

///|
fn FormatError::new(off : Int64, msg : String, val : &Show?) -> FormatError {
  FormatError(off~, msg~, val=val.map(_.to_string()))
}

///|
pub impl Show for FormatError with output(self : FormatError, logger : &Logger) -> Unit {
  let FormatError(off~, msg~, val~) = self
  logger.write_string(msg)
  if val is Some(val) {
    logger.write_string(" '\{val}'")
  }
  logger.write_string(" in record at byte \{off.to_string(radix=16)}")
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
  cmd : LoadCmd
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
pub impl @binary.Readable for Segment32 with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> Segment32 {
  Segment32::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    name: @binary.read_n(r, order, 16),
    addr: @binary.read(r, order),
    memsz: @binary.read(r, order),
    offset: @binary.read(r, order),
    filesz: @binary.read(r, order),
    maxprot: @binary.read(r, order),
    prot: @binary.read(r, order),
    nsect: @binary.read(r, order),
    flag: @binary.read(r, order),
  }
}

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
pub impl @binary.Readable for Segment64 with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> Segment64 raise {
  Segment64::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    name: @binary.read_n(r, order, 16),
    addr: @binary.read(r, order),
    memsz: @binary.read(r, order),
    offset: @binary.read(r, order),
    filesz: @binary.read(r, order),
    maxprot: @binary.read(r, order),
    prot: @binary.read(r, order),
    nsect: @binary.read(r, order),
    flag: @binary.read(r, order),
  }
}

///|
pub struct SymtabCmd {
  cmd : LoadCmd
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
  cmd : LoadCmd
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
pub impl @binary.Readable for DysymtabCmd with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> DysymtabCmd {
  DysymtabCmd::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    ilocalsym: @binary.read(r, order),
    nlocalsym: @binary.read(r, order),
    iextdefsym: @binary.read(r, order),
    nextdefsym: @binary.read(r, order),
    iundefsym: @binary.read(r, order),
    nundefsym: @binary.read(r, order),
    tocoffset: @binary.read(r, order),
    ntoc: @binary.read(r, order),
    modtaboff: @binary.read(r, order),
    nmodtab: @binary.read(r, order),
    extrefsymoff: @binary.read(r, order),
    nextrefsyms: @binary.read(r, order),
    indirectsymoff: @binary.read(r, order),
    nindirectsyms: @binary.read(r, order),
    extreloff: @binary.read(r, order),
    nextrel: @binary.read(r, order),
    locreloff: @binary.read(r, order),
    nlocrel: @binary.read(r, order),
  }
}

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
pub impl @binary.Readable for Section32 with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> Section32 raise {
  Section32::{
    name: @binary.read_n(r, byte_order, 16),
    seg: @binary.read_n(r, byte_order, 16),
    addr: @binary.read(r, byte_order),
    size: @binary.read(r, byte_order),
    offset: @binary.read(r, byte_order),
    align: @binary.read(r, byte_order),
    reloff: @binary.read(r, byte_order),
    nreloc: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    reserve1: @binary.read(r, byte_order),
    reserve2: @binary.read(r, byte_order),
  }
}

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

pub impl @binary.Readable for Section64 with read(
  r : &@io.Reader,
  byte_order : &@binary.ByteOrder,
) -> Section64 raise {
  Section64::{
    name: @binary.read_n(r, byte_order, 16),
    seg: @binary.read_n(r, byte_order, 16),
    addr: @binary.read(r, byte_order),
    size: @binary.read(r, byte_order),
    offset: @binary.read(r, byte_order),
    align: @binary.read(r, byte_order),
    reloff: @binary.read(r, byte_order),
    nreloc: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    reserve1: @binary.read(r, byte_order),
    reserve2: @binary.read(r, byte_order),
    reserve3: @binary.read(r, byte_order),
  }
}

///|
struct Nlist32 {
  name : UInt
  type_ : Byte
  sect : Byte
  desc : UInt16
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
