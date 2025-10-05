// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package macho implements access to Mach-O object files.
//
// # Security
//
// This package is not designed to be hardened against adversarial inputs, and is
// outside the scope of https://go.dev/security/policy. In particular, only basic
// validation is done when parsing object files. As such, care should be taken when
// parsing untrusted inputs, as parsing malformed files may consume significant
// resources, or cause panics.

///|
/// A `File` represents an open Mach-O file.
pub struct File {
  header : FileHeader
  byte_order : @binary.ByteOrder
  loads : Array[Load]
  sections : Array[Section]
  symtab : Symtab?
  dysymtab : Dysymtab?
  mut closer : &@io.Closer?
}

///|
pub fn File::magic(self : File) -> UInt {
  return self.header.magic
}

///|
pub fn File::type_(self : File) -> Type {
  return self.header.type_
}

///|
/// A `Load` represents any Mach-O load command.
pub enum Load {
  LoadBytes(LoadBytes)
  Segment(Segment)
  Dylib(Dylib)
  Symtab(Symtab)
  Dysymtab(Dysymtab)
  Rpath(Rpath)
}

///|
/// A `LoadBytes` is the uninterpreted bytes of a Mach-O load command.
pub struct LoadBytes(@slice.Slice[Byte])

///|
/// A `SegmentHeader` is the header for a Mach-O 32-bit or 64-bit load segment command.
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
/// A `Reloc` represents a Mach-O relocation.
pub struct Reloc {
  addr : UInt
  /// when `scattered == false && is_extern == true`, `value` is the symbol number.
  /// when `scattered == false && is_extern == false`, `value` is the section number.
  /// when `scattered == true`, `value` is the value that this reloc refers to.
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
/// A `Dylib` represents a Mach-O load dynamic library command.
pub struct Dylib {
  load_bytes : LoadBytes
  name : String
  time : UInt
  current_version : UInt
  compat_version : UInt
}

///|
/// A `Symtab` represents a Mach-O symbol table command.
pub struct Symtab {
  load_bytes : LoadBytes
  symtab_cmd : SymtabCmd
  syms : Array[Symbol]
}

///|
/// A `Dysymtab` represents a Mach-O dynamic symbol table command.
pub struct Dysymtab {
  load_bytes : LoadBytes
  dysymtab_cmd : DysymtabCmd
  indirect_syms : Array[UInt]
}

///|
/// A `Rpath` represents a Mach-O rpath command.
pub struct Rpath {
  load_bytes : LoadBytes
  path : String
}

///|
/// A `Symbol` is a Mach-O 32-bit or 64-bit symbol table entry.
pub struct Symbol {
  name : String
  type_ : Byte
  sect : Byte
  desc : UInt16
  value : UInt64
} derive(Eq, Show)

//
// Mach-O reader
//

///|
/// FormatError is returned by some operations if the data does
/// not have the correct format for an object file.
suberror FormatError {
  FormatError(Int64, String, &Show?)
}

///|
fn FormatError::new(off : Int64, msg : String, val : &Show?) -> FormatError {
  FormatError(off, msg, val)
}

///|
pub impl Show for FormatError with output(self : FormatError, logger : &Logger) -> Unit {
  let FormatError(off, msg, val) = self
  logger.write_string(msg)
  if val is Some(val) {
    logger.write_string(" '\{val}'")
  }
  logger.write_string(" in record at byte \{off.to_string(radix=16)}")
}

///|
/// `open` opens the named file using [@os.open] and prepares it for use as a
/// Mach-O binary.
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
/// `close` closes the [File].
/// If the [File] was created using [NewFile] directly instead of [Open],
/// Close has no effect.
pub impl @io.Closer for File with close(self : File) -> Unit raise {
  if self.closer is Some(closer) {
    closer.close()
    self.closer = None
  }
}

///|
/// `new_file` creates a new [File] for accessing a Mach-O binary in an
/// underlying reader.
///
/// The Mach-O binary is expected to start at position 0 in the `ReaderAt`.
pub fn new_file(r : &@io.ReaderAt) -> File raise {
  let sr = @io.new_section_reader(r, 0, (1 << 63) - 1)
  let ident = @slice.make(4)
  let _ = r.read_at(ident[0:], 0)
  let be = @binary.BigEndian.uint32(ident[0:])
  let le = @binary.LittleEndian.uint32(ident[0:])
  let (bo, magic) = if (Magic32 & 1U.lnot()) == (be & 1U.lnot()) {
    (@binary.BigEndian, be)
  } else if (Magic32 & 1U.lnot()) == (le & 1U.lnot()) {
    (@binary.LittleEndian, le)
  } else {
    raise FormatError::new(0, "invalid magic number", None)
  }
  let file_header : FileHeader = @binary.read(sr, bo)
  let mut offset = if magic == Magic64 {
    int64(FileHeaderSize64)
  } else {
    int64(FileHeaderSize32)
  }
  let mut dat = @saferio.read_data_at(r, uint64(file_header.cmdsz), offset)
  let loads : Array[Load] = []
  let mut symtab = None
  let mut dysymtab = None
  let sections = []
  for i in 0U..<file_header.ncmd {
    if len(dat) < 8 {
      raise FormatError::new(offset, "command block too small", None)
    }
    let cmd = LoadCmd::from_uint(bo.uint32(dat[0:4]))
    let siz = bo.uint32(dat[4:8])
    if siz < 8 || siz > len(dat).reinterpret_as_uint() {
      raise FormatError::new(offset, "invalid command block size", None)
    }
    let cmddat = dat[0:siz.reinterpret_as_int()]
    dat = dat[siz.reinterpret_as_int():]
    offset += int64(siz)
    match cmd {
      Rpath => {
        let b = @bytes.new_reader(cmddat)
        let hdr : RpathCmd = @binary.read(b, bo)
        if hdr.path >= len(cmddat).reinterpret_as_uint() {
          raise FormatError::new(
            offset,
            "invalid path in rpath command",
            Some(hdr.path),
          )
        }
        let path = cstring(cmddat[hdr.path.reinterpret_as_int():])
        let load_bytes = LoadBytes::LoadBytes(cmddat)
        let l = Rpath::{ load_bytes, path }
        loads.push(Rpath(l))
      }
      Dylib => {
        let b = @bytes.new_reader(cmddat)
        let hdr : DylibCmd = @binary.read(b, bo)
        if hdr.name >= len(cmddat).reinterpret_as_uint() {
          raise FormatError::new(
            offset,
            "invalid name in dynamic library command",
            Some(hdr.name),
          )
        }
        let load_bytes = LoadBytes::LoadBytes(cmddat)
        let l = Dylib::{
          load_bytes,
          name: cstring(cmddat[hdr.name.reinterpret_as_int():]),
          time: hdr.time,
          current_version: hdr.current_version,
          compat_version: hdr.compat_version,
        }
        loads.push(Dylib(l))
      }
      Symtab => {
        let b = @bytes.new_reader(cmddat)
        let hdr : SymtabCmd = @binary.read(b, bo)
        let strtab = @saferio.read_data_at(
          r,
          uint64(hdr.strsize),
          int64(hdr.stroff),
        )
        let symsz = if magic == Magic64 { 16 } else { 12 }
        let symdat = @saferio.read_data_at(
          r,
          uint64(hdr.nsyms) * uint64(symsz),
          int64(hdr.symoff),
        )
        let st = File::parse_symtab(
          bo, magic, symdat, strtab, cmddat, hdr, offset,
        )
        loads.push(Symtab(st))
        symtab = Some(st)
      }
      Dysymtab => {
        let b = @bytes.new_reader(cmddat)
        let hdr : DysymtabCmd = @binary.read(b, bo)
        guard symtab is Some(symtab) else {
          raise FormatError::new(
            offset,
            "dynamic symbol table seen before any ordinary symbol table",
            None,
          )
        }
        guard hdr.iundefsym > uint32(len(symtab.syms)) else {
          raise FormatError::new(
            offset,
            "undefined symbols index in dynamic symbol table command is greater than symbol table length (\{hdr.iundefsym} > \{len(symtab.syms)})",
            None,
          )
        }
        guard hdr.iundefsym + hdr.nundefsym > uint32(len(symtab.syms)) else {
          raise FormatError::new(
            offset,
            "number of undefined symbols after index in dynamic symbol table command is greater than symbol table length (\{hdr.iundefsym + hdr.nundefsym} > \{len(symtab.syms)})",
            None,
          )
        }
        let dat = @saferio.read_data_at(
          r,
          uint64(hdr.nindirectsyms) * 4,
          int64(hdr.indirectsymoff),
        )
        let x : Array[UInt] = @binary.read_n(
          @bytes.new_reader(dat),
          bo,
          int(hdr.nindirectsyms),
        )
        let st : Dysymtab = {
          load_bytes: LoadBytes::LoadBytes(cmddat),
          dysymtab_cmd: hdr,
          indirect_syms: x,
        }
        loads.push(Dysymtab(st))
        dysymtab = Some(st)
      }
      Segment => {
        let b = @bytes.new_reader(cmddat)
        let seg32 : Segment32 = @binary.read(b, bo)
        let sh : SegmentHeader = {
          cmd,
          len: siz,
          name: cstring(@slice.fixedarray(seg32.name)[0:]),
          addr: uint64(seg32.addr),
          memsz: uint64(seg32.memsz),
          offset: uint64(seg32.offset),
          filesz: uint64(seg32.filesz),
          maxprot: seg32.maxprot,
          prot: seg32.prot,
          nsect: seg32.nsect,
          flag: seg32.flag,
        }
        if int64(sh.offset) < 0 {
          raise FormatError::new(
            offset,
            "invalid section offset",
            Some(sh.offset),
          )
        }
        if int64(sh.filesz) < 0 {
          raise FormatError::new(
            offset,
            "invalid section file size",
            Some(sh.filesz),
          )
        }
        let sr = @io.new_section_reader(r, int64(sh.offset), int64(sh.filesz))
        let s : Segment = {
          load_bytes: LoadBytes::LoadBytes(cmddat),
          header: sh,
          reader_at: sr,
          sr,
        }
        loads.push(Segment(s))
        for i in 0..<int(seg32.nsect) {
          let sh32 : Section32 = @binary.read(b, bo)
          let sh : SectionHeader = {
            name: cstring(@slice.fixedarray(sh32.name)[0:]),
            seg: cstring(@slice.fixedarray(sh32.seg)[0:]),
            addr: uint64(sh32.addr),
            size: uint64(sh32.size),
            offset: sh32.offset,
            align: sh32.align,
            reloff: sh32.reloff,
            nreloc: sh32.nreloc,
            flags: sh32.flags,
          }
          let sh : Section = {
            header: sh,
            relocs: File::push_section(bo, sh, r),
            reader_at: sr,
            sr,
          }
          sections.push(sh)
        }
      }
      Segment64 => {
        let b = @bytes.new_reader(cmddat)
        let seg64 : Segment64 = @binary.read(b, bo)
        let sh : SegmentHeader = {
          cmd,
          len: siz,
          name: cstring(@slice.fixedarray(seg64.name)[0:]),
          addr: seg64.addr,
          memsz: seg64.memsz,
          offset: seg64.offset,
          filesz: seg64.filesz,
          maxprot: seg64.maxprot,
          prot: seg64.prot,
          nsect: seg64.nsect,
          flag: seg64.flag,
        }
        if int64(sh.offset) < 0 {
          raise FormatError::new(
            offset,
            "invalid section offset",
            Some(sh.offset),
          )
        }
        if int64(sh.filesz) < 0 {
          raise FormatError::new(
            offset,
            "invalid section file size",
            Some(sh.filesz),
          )
        }
        let sr = @io.new_section_reader(r, int64(sh.offset), int64(sh.filesz))
        let s : Segment = {
          load_bytes: LoadBytes::LoadBytes(cmddat),
          header: sh,
          reader_at: sr,
          sr,
        }
        loads.push(Segment(s))
        for i in 0..<int(seg64.nsect) {
          let sh64 : Section64 = @binary.read(b, bo)
          let sh : SectionHeader = {
            name: cstring(@slice.fixedarray(sh64.name)[0:]),
            seg: cstring(@slice.fixedarray(sh64.seg)[0:]),
            addr: sh64.addr,
            size: sh64.size,
            offset: sh64.offset,
            align: sh64.align,
            reloff: sh64.reloff,
            nreloc: sh64.nreloc,
            flags: sh64.flags,
          }
          let sh : Section = {
            header: sh,
            relocs: File::push_section(bo, sh, r),
            reader_at: sr,
            sr,
          }
          sections.push(sh)
        }
      }
      _ => loads.push(LoadBytes(cmddat))
    }
  }
  File::{
    header: file_header,
    byte_order: bo,
    loads,
    sections,
    symtab,
    dysymtab,
    closer: None,
  }
}

///|
fn File::parse_symtab(
  bo : @binary.ByteOrder,
  magic : UInt,
  symdat : @slice.Slice[Byte],
  strtab : @slice.Slice[Byte],
  cmddat : @slice.Slice[Byte],
  hdr : SymtabCmd,
  offset : Int64,
) -> Symtab raise {
  let symtab = []
  let b = @bytes.new_reader(symdat)
  for i in 0..<hdr.nsyms.reinterpret_as_int() {
    let n : Nlist64 = if magic == Magic64 {
      @binary.read(b, bo)
    } else {
      let n32 : Nlist32 = @binary.read(b, bo)
      Nlist64::{
        name: n32.name,
        type_: n32.type_,
        sect: n32.sect,
        desc: n32.desc,
        value: uint64(n32.value),
      }
    }
    if n.name >= uint32(len(strtab)) {
      raise FormatError::new(
        offset,
        "invalid name in symbol table",
        Some(n.name),
      )
    }
    // We add "_" to Go symbols. Strip it here. See issue 33808.
    let name = cstring(strtab[int(n.name):])
    let name = if name.contains(".") && name is ['_', .. name] {
      name.to_string()
    } else {
      name
    }
    symtab.push(Symbol::{
      name,
      type_: n.type_,
      sect: n.sect,
      desc: n.desc,
      value: n.value,
    })
  }
  Symtab::{
    load_bytes: LoadBytes::LoadBytes(cmddat),
    syms: symtab,
    symtab_cmd: hdr,
  }
}

///|
priv struct RelocInfo {
  addr : UInt
  symnum : UInt
}

///|
impl @binary.Readable for RelocInfo with read(
  r : &@io.Reader,
  bo : @binary.ByteOrder,
) -> RelocInfo {
  RelocInfo::{ addr: @binary.read(r, bo), symnum: @binary.read(r, bo) }
}

///|
fn File::push_section(
  bo : @binary.ByteOrder,
  sh : SectionHeader,
  r : &@io.ReaderAt,
) -> Array[Reloc] raise {
  let relocs = []
  if sh.nreloc > 0 {
    let reldat = @saferio.read_data_at(
      r,
      uint64(sh.nreloc) * 8,
      int64(sh.reloff),
    )
    let b = @bytes.new_reader(reldat)
    for i in 0..<int(sh.nreloc) {
      let ri : RelocInfo = @binary.read(b, bo)
      let rel = if (ri.addr & (1 << 31)) != 0 {
        Reloc::{
          addr: ri.addr,
          type_: ((ri.addr >> 24) & ((1 << 4) - 1)).to_byte(),
          len: ((ri.addr >> 28) & ((1 << 2) - 1)).to_byte(),
          pcrel: (ri.addr & (1 << 30)) != 0,
          value: ri.symnum,
          scattered: true,
          is_extern: false,
        }
      } else {
        match bo {
          @binary.LittleEndian =>
            Reloc::{
              addr: ri.addr,
              value: ri.symnum & ((1 << 24) - 1),
              pcrel: (ri.addr & (1 << 24)) != 0,
              len: ((ri.addr >> 25) & ((1 << 2) - 1)).to_byte(),
              is_extern: (ri.symnum & (1 << 27)) != 0,
              type_: ((ri.addr >> 28) & ((1 << 4) - 1)).to_byte(),
              scattered: false,
            }
          @binary.BigEndian =>
            Reloc::{
              addr: ri.addr,
              value: ri.symnum >> 8,
              pcrel: (ri.symnum & (1 << 7)) != 0,
              len: ((ri.symnum >> 5) & ((1 << 2) - 1)).to_byte(),
              is_extern: (ri.symnum & (1 << 4)) != 0,
              type_: (ri.symnum & ((1 << 4) - 1)).to_byte(),
              scattered: false,
            }
        }
      }
      relocs.push(rel)
    }
  }
  relocs
}

///|
fn cstring(b : @slice.Slice[Byte]) -> String {
  let mut i = @bytes.index_byte(b, 0)
  if i == -1 {
    i = len(b)
  }
  return @utf8.decode_lossy(b[0:i])
}

///|
/// `segment` returns the first `Segment` with the given name, or `None` if no
/// such segment exists.
pub fn File::segment(self : File, name : String) -> Segment? {
  for l in self.loads {
    if l is Load::Segment(s) {
      if s.header.name == name {
        return Some(s)
      }
    }
  }
  None
}

///|
/// `section` returns the first `Section` with the given name, or `None` if no
/// such section exists.
pub fn File::section(self : File, name : String) -> Section? {
  for s in self.sections {
    if s.header.name == name {
      return Some(s)
    }
  }
  None
}

///|
/// `dwarf` returns the DWARF debug information for the Mach-O file.
pub fn File::dwarf(self : File) -> @dwarf.Data raise {
  fn dwarf_suffix(s : Section) -> String {
    let sectname = s.header.name
    let pfx = if sectname.has_prefix("__debug_") {
      8
    } else if sectname.has_prefix("__zdebug_") {
      9
    } else {
      return ""
    }
    // Mach-O executables truncate section names to 16 characters, mangling some DWARF sections.
    // As of DWARFv5 these are the only problematic section names (see DWARFv5 Appendix G).
    let sectname = for
      longname in [
        "__debug_str_offsets", "__zdebug_line_str", "__zdebug_loclists", "__zdebug_pubnames",
        "__zdebug_pubtypes", "__zdebug_rnglists", "__zdebug_str_offsets",
      ] {
      if sectname[:] == (try! longname[:16]) {
        break sectname
      }
    } else {
      sectname
    }
    try! sectname[pfx:].to_string()
  }

  fn section_data(s : Section) -> @slice.Slice[Byte] raise {
    let mut b = s.data()
    if len(b) >= 12 && b.bytesview() is [.. "ZLIB", ..] {
      let dlen = @binary.BigEndian.uint64(b[4:12])
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
/// `imported_symbols` returns the names of all symbols
/// referred to by the binary `f` that are expected to be
/// satisfied by other libraries at dynamic load time.
pub fn File::imported_symbols(self : File) -> Array[String] raise {
  guard self.symtab is Some(st) else {
    raise FormatError::new(0, "missing symbol table", None)
  }
  let all = []
  if self.dysymtab is Some(dt) {
    for
      s in st.syms[int(dt.dysymtab_cmd.iundefsym):int(dt.dysymtab_cmd.iundefsym) +
      int(dt.dysymtab_cmd.nundefsym)] {
      all.push(s.name)
    }
  } else {
    // From Darwin's include/mach-o/nlist.h
    for s in st.syms {
      if (s.type_ & 0x0e) == 0x0 && s.sect == 0 {
        all.push(s.name)
      }
    }
  }
  all
}

///|
/// `imported_libraries` returns the paths of all libraries
/// referred to by the binary f that are expected to be
/// linked with the binary at dynamic link time.
pub fn File::imported_libraries(self : File) -> Array[String] {
  let all = []
  for l in self.loads {
    if l is Dylib(lib) {
      all.push(lib.name)
    }
  }
  all
}
