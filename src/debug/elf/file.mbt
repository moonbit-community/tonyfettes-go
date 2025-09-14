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
  mut version : Version
  mut osabi : OSABI
  mut abi_version : Byte
  mut byte_order : &@binary.ByteOrder
  mut type_ : Type
  mut machine : Machine
  mut entry : UInt64
}

///|
/// A File represents an open ELF file.
pub struct File {
  file_header : FileHeader
  sections : Array[Section]
  mut progs : Array[Prog]
  priv mut closer : &@io.Closer?
  priv dyn_vers : Array[DynamicVersion]?
  priv mut dyn_ver_needs : Array[DynamicVersionNeed]?
  priv mut gnu_versym : @slice.Slice[Byte] // Simplified - using Bytes instead of slice
}

///|
pub fn File::class(self : File) -> Class {
  self.file_header.class
}

///|
pub fn File::data(self : File) -> Data {
  self.file_header.data
}

///|
pub fn File::version(self : File) -> Version {
  self.file_header.version
}

///|
pub fn File::osabi(self : File) -> OSABI {
  self.file_header.osabi
}

///|
pub fn File::abi_version(self : File) -> Byte {
  self.file_header.abi_version
}

///|
pub fn File::byte_order(self : File) -> &@binary.ByteOrder {
  self.file_header.byte_order
}

///|
pub fn File::type_(self : File) -> Type {
  self.file_header.type_
}

///|
pub fn File::machine(self : File) -> Machine {
  self.file_header.machine
}

///|
pub fn File::entry(self : File) -> UInt64 {
  self.file_header.entry
}

///|
/// A SectionHeader represents a single ELF section header.
pub struct SectionHeader {
  mut name : String
  type_ : SectionType
  flags : SectionFlag
  addr : UInt64
  offset : UInt64
  mut size : UInt64
  link : UInt
  info : UInt
  mut addralign : UInt64
  entsize : UInt64
  /// FileSize is the size of this section in the file in bytes.
  /// If a section is compressed, FileSize is the size of the
  /// compressed data, while Size (above) is the size of the
  /// uncompressed data.
  file_size : UInt64
} derive(Show, ToJson, Default)

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
  mut section_header : SectionHeader
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
  mut reader_at : &@io.ReaderAt?
  priv mut sr : @io.SectionReader?
  priv mut compression_type : CompressionType
  priv mut compression_offset : Int64
} derive(Default)

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
  if self.section_header.type_ is SHT_NOBITS {
    return @io.new_section_reader(
      NobitsSectionReader::{  },
      0,
      self.section_header.size.reinterpret_as_int64(),
    )
  }
  let mut zrd : ((@io.SectionReader) -> &@io.Reader raise)? = None
  if (self.section_header.flags.0 & SHF_COMPRESSED) == 0 {
    if !self.section_header.name.has_prefix(".zdebug") {
      return @io.new_section_reader(self.sr.unwrap(), 0, 1 << (63 - 1))
    }
    let b = @slice.make(12)
    let n = self.sr.unwrap().read_at(b, 0)
    if n != 12 || b[:4].bytesview() is "ZLIB" {
      return @io.new_section_reader(self.sr.unwrap(), 0, 1 << (63 - 1))
    }
    self.compression_offset = 12
    self.compression_type = CompressionType::COMPRESS_ZLIB
    self.section_header.size = @binary.big_endian.uint64(b[4:12])
    zrd = Some(r => @zlib.new_reader(@bufio.new_reader(r)))
  } else if (self.section_header.flags.0 & SHF_ALLOC) != 0 {
    return ErrorReader::new(
      FormatError::new(
        off=self.section_header.offset.reinterpret_as_int64(),
        msg="SHF_COMPRESSED applies only to non-allocable sections",
        val=self.compression_type.to_string(),
      ),
    )
  }
  match self.compression_type {
    COMPRESS_ZLIB => zrd = Some(r => @zlib.new_reader(@bufio.new_reader(r)))
    _ => ()
  }
  guard zrd is Some(zrd) else {
    return ErrorReader::new(
      FormatError::new(
        off=self.section_header.offset.reinterpret_as_int64(),
        msg="unknown compression type",
        val=self.compression_type.to_string(),
      ),
    )
  }
  return ReadSeekerFromReader::new(
    reset=() => {
      let fr = @io.new_section_reader(
        self.sr.unwrap(),
        self.compression_offset,
        self.section_header.file_size.reinterpret_as_int64() -
        self.compression_offset,
      )
      return zrd(fr)
    },
    size=self.section_header.size.reinterpret_as_int64(),
  )
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
} derive(Show, ToJson, Default)

///|
/// A Prog represents a single ELF program header in an ELF binary.
pub struct Prog {
  mut prog_header : ProgHeader
  /// Embed ReaderAt for ReadAt method.
  mut reader_at : &@io.ReaderAt?
  /// Do not embed SectionReader directly
  /// to avoid having Read and Seek.
  /// If a client wants Read and Seek it must use
  /// Open() to avoid fighting over the seek offset
  /// with other clients.
  priv mut sr : @io.SectionReader?
} derive(Default)

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
  let sr = @io.new_section_reader(r, 0, 1L << (63 - 1))
  // Read and decode ELF identifier
  let ident = @slice.make(16)
  let n = r.read_at(ident, 0)
  if n != 16 {
    raise FormatError::new(off=0, msg="incomplete ELF header")
  }
  guard ident.arrayview() is [0x7f, 'E', 'L', 'F'] else {
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
      osabi: OSABI::from_byte(ident[EI_OSABI]),
      abi_version: ident[EI_ABIVERSION],
      byte_order: @binary.little_endian, // will be set correctly below
      type_: Type::from_uint16(0), // will be read from header
      machine: Machine::from_uint16(0), // will be read from header
      entry: 0UL, // will be read from header
    },
    sections: [],
    progs: [],
    closer: None,
    dyn_vers: None,
    dyn_ver_needs: None,
    gnu_versym: @slice.make(0),
  }
  match f.file_header.class {
    ELFCLASS32 | ELFCLASS64 => ()
    _ =>
      raise FormatError::new(
        off=0,
        msg="unknown ELF class",
        val=f.file_header.class.to_int().to_string(),
      )
  }
  let bo = match f.file_header.data {
    ELFDATA2LSB => @binary.little_endian as &@binary.ByteOrder
    ELFDATA2MSB => @binary.big_endian
    _ =>
      raise FormatError::new(
        off=0,
        msg="unknown ELF data encoding",
        val=f.file_header.data.to_byte().to_int().to_string(),
      )
  }
  f.file_header.byte_order = bo
  f.file_header.version = Version::from_byte(ident[EI_VERSION])
  if f.file_header.version != EV_CURRENT {
    raise FormatError::new(
      off=0,
      msg="unknown ELF version",
      val=f.file_header.version.to_byte().to_int().to_string(),
    )
  }
  f.file_header.osabi = OSABI::from_byte(ident[EI_OSABI])
  f.file_header.abi_version = ident[EI_ABIVERSION]

  // Read ELF file header based on class
  let mut phoff : Int64 = 0
  let mut phentsize : Int = 0
  let mut phnum : Int = 0
  let mut shoff : Int64 = 0
  let mut shentsize : Int = 0
  let mut shnum : Int = 0
  let mut shstrndx : Int = 0
  match f.file_header.class {
    ELFCLASS32 => {
      let data = @slice.make(52)
      let n = sr.read_at(data, 0)
      if n != 52 {
        raise FormatError::new(off=0, msg="incomplete ELF32 header")
      }
      f.file_header.type_ = Type::from_uint16(bo.uint16(data[16:18]))
      f.file_header.machine = Machine::from_uint16(bo.uint16(data[18:20]))
      f.file_header.entry = bo.uint32(data[24:28]).to_uint64()
      let v = Version::from_byte(bo.uint32(data[20:24]).to_byte())
      if v != f.file_header.version {
        raise FormatError::new(
          off=0,
          msg="mismatched ELF version",
          val=v.to_string(),
        )
      }
      phoff = bo.uint32(data[28:32]).to_int64()
      phentsize = bo.uint16(data[42:44]).to_int()
      phnum = bo.uint16(data[44:46]).to_int()
      shoff = bo.uint32(data[32:36]).to_int64()
      shentsize = bo.uint16(data[46:48]).to_int()
      shnum = bo.uint16(data[48:50]).to_int()
      shstrndx = bo.uint16(data[50:52]).to_int()
    }
    ELFCLASS64 => {
      let data = @slice.make(Header64::sizeof(Header64))
      let n = sr.read_at(data, 0)
      if n != 64 {
        raise FormatError::new(off=0, msg="incomplete ELF64 header")
      }
      f.file_header.type_ = Type::from_uint16(
        bo.uint16(data[Header64::offsetof(Type):]),
      )
      f.file_header.machine = Machine::from_uint16(
        bo.uint16(data[Header64::offsetof(Machine):]),
      )
      f.file_header.entry = bo.uint64(data[Header64::offsetof(Entry):])
      let version_check = bo.uint32(data[Header64::offsetof(Version):])
      if Version::from_byte(version_check.to_byte()) != f.file_header.version {
        raise FormatError::new(
          off=0,
          msg="mismatched ELF version",
          val=version_check.to_string(),
        )
      }
      phoff = int64(bo.uint64(data[Header64::offsetof(Phoff):]))
      phentsize = int(bo.uint16(data[Header64::offsetof(Phentsize):]))
      phnum = int(bo.uint16(data[Header64::offsetof(Phnum):]))
      shoff = int64(bo.uint64(data[Header64::offsetof(Shoff):]))
      shentsize = int(bo.uint16(data[Header64::offsetof(Shentsize):]))
      shnum = int(bo.uint16(data[Header64::offsetof(Shnum):]))
      shstrndx = int(bo.uint16(data[Header64::offsetof(Shstrndx):]))
    }
    _ => ()
  }

  // Validate offsets
  if shoff < 0 {
    raise FormatError::new(off=0, msg="invalid shoff", val=shoff.to_string())
  }
  if phoff < 0 {
    raise FormatError::new(off=0, msg="invalid phoff", val=phoff.to_string())
  }
  if shoff == 0 && shnum != 0 {
    raise FormatError::new(
      off=0,
      msg="invalid ELF shnum for shoff=0",
      val=shnum.to_string(),
    )
  }
  if shnum > 0 && shstrndx >= shnum {
    raise FormatError::new(
      off=0,
      msg="invalid ELF shstrndx",
      val=shstrndx.to_string(),
    )
  }

  // Validate header entry sizes
  let want_phentsize = match f.file_header.class {
    ELFCLASS32 => 8 * 4
    ELFCLASS64 => 2 * 4 + 6 * 8
    _ => 0
  }
  let want_shentsize = match f.file_header.class {
    ELFCLASS32 => 10 * 4
    ELFCLASS64 => 4 * 4 + 6 * 8
    _ => 0
  }
  if phnum > 0 && phentsize < want_phentsize {
    raise FormatError::new(
      off=0,
      msg="invalid ELF phentsize",
      val=phentsize.to_string(),
    )
  }
  f.progs = []
  let phdata = @saferio.read_data_at(
    sr,
    phnum.to_uint64() * phentsize.to_uint64(),
    phoff,
  )
  for i in 0..<phnum {
    let off = (i.to_uint64() * phentsize.to_uint64()).to_int()
    let p = Prog::default()
    match f.file_header.class {
      ELFCLASS32 =>
        p.prog_header = ProgHeader::{
          type_: ProgType::from_int(
            bo.uint32(phdata[off + 0:off + 4]).reinterpret_as_int(),
          ),
          flags: ProgFlag::from_uint(bo.uint32(phdata[off + 24:off + 28])),
          off: bo.uint32(phdata[off + 4:off + 8]).to_uint64(),
          vaddr: bo.uint32(phdata[off + 8:off + 12]).to_uint64(),
          paddr: bo.uint32(phdata[off + 12:off + 16]).to_uint64(),
          filesz: bo.uint32(phdata[off + 16:off + 20]).to_uint64(),
          memsz: bo.uint32(phdata[off + 20:off + 24]).to_uint64(),
          align: bo.uint32(phdata[off + 28:off + 32]).to_uint64(),
        }
      ELFCLASS64 =>
        p.prog_header = ProgHeader::{
          type_: ProgType::from_int(
            bo.uint32(phdata[off + 0:off + 4]).reinterpret_as_int(),
          ),
          flags: ProgFlag::from_uint(bo.uint32(phdata[off + 4:off + 8])),
          off: bo.uint64(phdata[off + 8:off + 16]),
          vaddr: bo.uint64(phdata[off + 16:off + 24]),
          paddr: bo.uint64(phdata[off + 24:off + 32]),
          filesz: bo.uint64(phdata[off + 32:off + 40]),
          memsz: bo.uint64(phdata[off + 40:off + 48]),
          align: bo.uint64(phdata[off + 48:off + 56]),
        }
      _ => ()
    }
    if p.prog_header.off < 0 {
      raise FormatError::new(
        off=phoff + off.to_int64(),
        msg="invalid ELF program offset",
        val=p.prog_header.off.to_string(),
      )
    }
    if p.prog_header.filesz < 0 {
      raise FormatError::new(
        off=phoff + off.to_int64(),
        msg="invalid ELF program size",
        val=p.prog_header.filesz.to_string(),
      )
    }
    p.sr = Some(
      @io.new_section_reader(
        sr,
        p.prog_header.off.reinterpret_as_int64(),
        p.prog_header.filesz.reinterpret_as_int64(),
      ),
    )
    p.reader_at = p.sr.map(sr => sr)
    f.progs.push(p)
  }

  // If the number of sections is greater than or equal to SHN_LORESERVE
  // (0xff00), shnum has the value zero and the actual number of section
  // header table entries is contained in the sh_size field of the section
  // header at index 0.
  if shoff > 0 && shnum == 0 {
    ignore(sr.seek(shoff, @io.Start)) catch {
      _ => ()
    }
    let mut typ : UInt = 0
    let mut link : UInt = 0
    match f.file_header.class {
      ELFCLASS32 => {
        let data = @slice.make(40)
        let n = sr.read(data)
        if n != 40 {
          raise FormatError::new(
            off=shoff,
            msg="incomplete ELF32 section header",
          )
        }
        let sh : Section32 = {
          name: bo.uint32(data[0:4]),
          type_: bo.uint32(data[4:8]),
          flags: bo.uint32(data[8:12]),
          addr: bo.uint32(data[12:16]),
          off: bo.uint32(data[16:20]),
          size: bo.uint32(data[20:24]),
          link: bo.uint32(data[24:28]),
          info: bo.uint32(data[28:32]),
          addralign: bo.uint32(data[32:36]),
          entsize: bo.uint32(data[36:40]),
        }
        shnum = sh.size.reinterpret_as_int()
        typ = sh.type_
        link = sh.link
      }
      ELFCLASS64 => {
        let data = @slice.make(64)
        let n = sr.read(data)
        if n != 64 {
          raise FormatError::new(
            off=shoff,
            msg="incomplete ELF64 section header",
          )
        }
        let sh : Section64 = {
          name: bo.uint32(data[0:4]),
          type_: bo.uint32(data[4:8]),
          flags: bo.uint64(data[8:16]),
          addr: bo.uint64(data[16:24]),
          off: bo.uint64(data[24:32]),
          size: bo.uint64(data[32:40]),
          link: bo.uint32(data[40:44]),
          info: bo.uint32(data[44:48]),
          addralign: bo.uint64(data[48:56]),
          entsize: bo.uint64(data[56:64]),
        }
        shnum = sh.size.to_int()
        typ = sh.type_
        link = sh.link
      }
      _ => ()
    }
    if !(SectionType::from_uint(typ) is SHT_NULL) {
      raise FormatError::new(
        off=shoff,
        msg="invalid type of the initial section",
        val=typ.to_string(),
      )
    }
    if shnum < SHN_LORESERVE.to_int() {
      raise FormatError::new(
        off=shoff,
        msg="invalid ELF shnum contained in sh_size",
        val=shnum.to_string(),
      )
    }
    // If the section name string table section index is greater than or
    // equal to SHN_LORESERVE (0xff00), this member has the value
    // SHN_XINDEX (0xffff) and the actual index of the section name
    // string table section is contained in the sh_link field of the
    // section header at index 0.
    if shstrndx == SHN_XINDEX.to_int() {
      shstrndx = link.reinterpret_as_int()
      if shstrndx < SHN_LORESERVE.to_int() {
        raise FormatError::new(
          off=shoff,
          msg="invalid ELF shstrndx contained in sh_link",
          val=shstrndx.to_string(),
        )
      }
    }
  }
  if shnum > 0 && shentsize < want_shentsize {
    raise FormatError::new(
      off=0,
      msg="invalid ELF shentsize",
      val=shentsize.to_string(),
    )
  }
  // Read section headers
  f.sections.clear()
  let names : Array[UInt] = []
  let shdata = @saferio.read_data_at(
    sr,
    shnum.to_uint64() * shentsize.to_uint64(),
    shoff,
  )
  for i in 0..<shnum {
    let off = (i.to_uint64() * shentsize.to_uint64()).to_int()
    let s = Section::default()
    let sh = match f.file_header.class {
      ELFCLASS32 => {
        names.push(bo.uint32(shdata[off + 0:off + 4]))
        s.section_header = SectionHeader::{
          name: "",
          type_: SectionType::from_uint(bo.uint32(shdata[off + 4:off + 8])),
          flags: SectionFlag(bo.uint32(shdata[off + 8:off + 12])),
          addr: bo.uint32(shdata[off + 12:off + 16]).to_uint64(),
          offset: bo.uint32(shdata[off + 16:off + 20]).to_uint64(),
          size: 0,
          file_size: bo.uint32(shdata[off + 20:off + 24]).to_uint64(),
          link: bo.uint32(shdata[off + 24:off + 28]),
          info: bo.uint32(shdata[off + 28:off + 32]),
          addralign: bo.uint32(shdata[off + 32:off + 36]).to_uint64(),
          entsize: bo.uint32(shdata[off + 36:off + 40]).to_uint64(),
        }
      }
      ELFCLASS64 => {
        names.push(bo.uint32(shdata[off + 0:off + 4]))
        s.section_header = SectionHeader::{
          name: "",
          type_: SectionType::from_uint(bo.uint32(shdata[off + 4:off + 8])),
          flags: SectionFlag(bo.uint64(shdata[off + 8:off + 16]).to_uint()),
          addr: bo.uint64(shdata[off + 16:off + 24]),
          offset: bo.uint64(shdata[off + 24:off + 32]),
          size: 0,
          file_size: bo.uint64(shdata[off + 32:off + 40]),
          link: bo.uint32(shdata[off + 40:off + 44]),
          info: bo.uint32(shdata[off + 44:off + 48]),
          addralign: bo.uint64(shdata[off + 48:off + 56]),
          entsize: bo.uint64(shdata[off + 56:off + 64]),
        }
      }
      ELFCLASSNONE => ()
    }
    if s.section_header.offset < 0 {
      raise FormatError::new(
        off=shoff + off.to_int64(),
        msg="invalid ELF section offset",
        val=s.section_header.offset.to_string(),
      )
    }
    if s.section_header.file_size < 0 {
      raise FormatError::new(
        off=shoff + off.to_int64(),
        msg="invalid ELF section size",
        val=s.section_header.file_size.to_string(),
      )
    }
    s.sr = Some(
      @io.new_section_reader(
        r,
        s.section_header.offset.reinterpret_as_int64(),
        s.section_header.file_size.reinterpret_as_int64(),
      ),
    )
    if (s.section_header.flags.0 & SHF_COMPRESSED) == 0 {
      s.reader_at = s.sr.map(sr => sr)
      s.section_header.size = s.section_header.file_size
    } else {
      match f.class() {
        ELFCLASS32 => {
          let chdata = @slice.make(12)
          guard s.sr is Some(sr)
          let n = sr.read_at(chdata, 0)
          if n != 12 {
            raise FormatError::new(
              off=s.section_header.offset.reinterpret_as_int64(),
              msg="incomplete ELF32 compressed section header",
            )
          }
          s.compression_type = CompressionType::from_int(
            bo.uint32(chdata[0:4]).reinterpret_as_int(),
          )
          s.section_header.size = bo.uint32(chdata[4:8]).to_uint64()
          s.section_header.addralign = bo.uint32(chdata[8:12]).to_uint64()
          s.compression_offset = 12
        }
        ELFCLASS64 => {
          let chdata = @slice.make(16)
          guard s.sr is Some(sr)
          let n = sr.read_at(chdata, 0)
          if n != 16 {
            raise FormatError::new(
              off=s.section_header.offset.reinterpret_as_int64(),
              msg="incomplete ELF64 compressed section header",
            )
          }
          s.compression_type = CompressionType::from_int(
            bo.uint32(chdata[0:4]).reinterpret_as_int(),
          )
          s.section_header.size = bo.uint64(chdata[4:12])
          s.section_header.addralign = bo.uint64(chdata[12:16])
          s.compression_offset = 16
        }
        ELFCLASSNONE => ()
      }
    }
    f.sections.push(s)
  }
  if f.sections.length() == 0 {
    return f
  }
  // Load section header string table.
  if shstrndx == 0 {
    return f
  }
  let shstr = f.sections[shstrndx]
  if shstr.section_header.type_ != SHT_STRTAB {
    raise FormatError::new(
      off=shoff +
        (shstrndx.to_uint64() * shentsize.to_uint64()).reinterpret_as_int64(),
      msg="invalid ELF shstrndx section type",
      val=shstr.section_header.type_.to_string(),
    )
  }
  let shstrtab = shstr.data()
  for i, s in f.sections {
    let (s_name, ok) = get_string(shstrtab, names[i].reinterpret_as_int())
    s.section_header.name = s_name
    if !ok {
      raise FormatError::new(
        off=shoff +
          (i.to_uint64() * shentsize.to_uint64()).reinterpret_as_int64(),
        msg="invalid ELF section name",
        val=names[i].to_string(),
      )
    }
  }
  return f
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
  if self.dyn_vers is Some(_) {
    return
  }
  let vd = self.section_by_type(SHT_GNU_VERDEF)
  guard vd is Some(vd) else { return }
  let d = vd.data()
  let dyn_vers : Array[DynamicVersion] = []
  for i = 0; i + 20 <= d.length(); {
    let version = self.file_header.byte_order.uint16(d[i + 2:i + 4])
    if version != 1 {
      raise FormatError::new(
        off=vd.section_header.offset.reinterpret_as_int64() + i.to_int64(),
        msg="unexpected dynamic version",
        val=version.to_string(),
      )
    }
    let flags = DynamicVersionFlag(
      self.file_header.byte_order.uint16(d[i + 4:i + 6]),
    )
    let ndx = self.file_header.byte_order.uint16(d[i + 6:i + 8])
    let cnt = self.file_header.byte_order.uint16(d[i + 8:i + 10])
    let aux = self.file_header.byte_order.uint32(d[i + 12:i + 16])
    let next = self.file_header.byte_order.uint32(d[i + 16:i + 20])
    if cnt == 0 {
      raise FormatError::new(
        off=vd.section_header.offset.reinterpret_as_int64() + i.to_int64(),
        msg="dynamic version has no name",
      )
    }
    let mut name = ""
    let mut dep_name = ""
    let deps = []
    for j = i + aux.reinterpret_as_int(), c = 0; c < cnt.to_int(); {
      if j + 8 > d.length() {
        break
      }
      let vname = self.file_header.byte_order.uint32(d[j + 0:j + 4])
      let vnext = self.file_header.byte_order.uint32(d[j + 4:j + 8])
      name = get_string(str, vname.reinterpret_as_int()).0
      if c == 0 {
        dep_name = name
      } else {
        deps.push(dep_name)
      }
      continue j + vnext.reinterpret_as_int(), c + 1
    }
    dyn_vers.push(DynamicVersion::{ name, index: ndx, flags, deps })
    if next == 0 {
      break
    }
    continue i + next.reinterpret_as_int()
  }
}

///|
// dynamic_versions returns version information for a dynamic object.
pub fn File::dynamic_versions(self : File) -> Array[DynamicVersion] raise {
  if self.dyn_vers is None {
    let (_, str) = self.get_symbols(SHT_DYNSYM)
    let has_versions = self.gnu_version_init(str)
    if !has_versions {
      fail("DynamicVersions: missing version table")
    }
  }
  return self.dyn_vers.unwrap()
}

///|
/// _dynamic_version_needs returns version dependencies for a dynamic object.
fn File::_dynamic_version_needs(
  self : File,
  str : @slice.Slice[Byte],
) -> Unit raise {
  if self.dyn_ver_needs is Some(_) {
    // Already initialized.
    return
  }
  let vn = self.section_by_type(SHT_GNU_VERNEED)
  guard vn is Some(vn) else { return }
  let d = vn.data()
  let dyn_ver_needs : Array[DynamicVersionNeed] = []
  for i = 0; i + 16 <= d.length(); {
    let vers = self.file_header.byte_order.uint16(d[i:i + 2])
    if vers != 1 {
      raise FormatError::new(
        off=vn.section_header.offset.reinterpret_as_int64() + i.to_int64(),
        msg="unexpected dynamic version need",
        val=vers.to_string(),
      )
    }
    let cnt = self.file_header.byte_order.uint16(d[i + 2:i + 4])
    let fileoff = self.file_header.byte_order.uint32(d[i + 4:i + 8])
    let aux = self.file_header.byte_order.uint32(d[i + 8:i + 12])
    let next = self.file_header.byte_order.uint32(d[i + 12:i + 16])
    let (file, _) = get_string(str, fileoff.reinterpret_as_int())
    let deps = []
    for j = i + aux.reinterpret_as_int(), c = 0; j + 16 <= d.length() &&
       c < cnt.to_int(); {
      let flags = DynamicVersionFlag(
        self.file_header.byte_order.uint16(d[j + 4:j + 6]),
      )
      let index = self.file_header.byte_order.uint16(d[j + 6:j + 8])
      let nameoff = self.file_header.byte_order.uint32(d[j + 8:j + 12])
      let next = self.file_header.byte_order.uint32(d[j + 12:j + 16])
      let (dep_name, _) = get_string(str, nameoff.reinterpret_as_int())
      deps.push(DynamicVersionDep::{ flags, index, dep: dep_name })
      if next == 0 {
        break
      }
      continue j + next.reinterpret_as_int(), c + 1
    }
    dyn_ver_needs.push(DynamicVersionNeed::{ name: file, needs: deps })
    if next == 0 {
      break
    }
    continue i + next.reinterpret_as_int()
  }
  self.dyn_ver_needs = Some(dyn_ver_needs)
  return
}

///|
pub fn File::dynamic_version_needs(
  self : File,
) -> Array[DynamicVersionNeed] raise {
  if self.dyn_ver_needs is None {
    let (_, str) = self.get_symbols(SHT_DYNSYM)
    let has_versions = self.gnu_version_init(str)
    if !has_versions {
      fail("DynamicVersionNeeds: missing version table")
    }
  }
  return self.dyn_ver_needs.unwrap()
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
  if self.dyn_ver_needs is Some(dyn_ver_needs) {
    for v in dyn_ver_needs {
      for n in v.needs {
        if ndx == n.index {
          return (true, vi, n.dep, v.name)
        }
      }
    }
  }
  if self.dyn_vers is Some(dyn_vers) {
    for v in dyn_vers {
      if ndx == v.index {
        return (true, vi, v.name, "")
      }
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
