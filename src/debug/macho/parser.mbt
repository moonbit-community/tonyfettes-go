///|
fn cstring(b : @slice.Slice[Byte]) -> String {
  let mut i = @bytes.index_byte(b, 0)
  if i == -1 {
    i = len(b)
  }
  return @utf8.decode_lossy(b[0:i])
}

///|
pub fn open(name : String) -> File raise {
  let f = @os.open(name)
  new_file(f, closer=f)
}

///|
pub fn new_file(r : &@io.ReaderAt, closer? : &@io.Closer) -> File raise {
  let sr = @io.new_section_reader(r, 0, (1 << 63) - 1)
  let ident = @slice.make(4)
  let _ = r.read_at(ident[0:], 0)
  let be = @binary.big_endian.uint32(ident[0:])
  let le = @binary.little_endian.uint32(ident[0:])
  let (bo, magic) = if (Magic32 & 1U.lnot()) == (be & 1U.lnot()) {
    (@binary.big_endian as &@binary.ByteOrder, be)
  } else if (Magic32 & 1U.lnot()) == (le & 1U.lnot()) {
    (@binary.little_endian, le)
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
  let loads : Array[&Load] = []
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
        loads.push(l)
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
        loads.push(l)
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
        loads.push(st)
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
        loads.push(st)
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
        loads.push(s)
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
        loads.push(s)
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
      _ => loads.push(LoadBytes::LoadBytes(cmddat))
    }
  }
  File::{
    header: file_header,
    byte_order: bo,
    loads,
    sections,
    symtab,
    dysymtab,
    closer,
  }
}

///|
fn File::parse_symtab(
  bo : &@binary.ByteOrder,
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
  bo : &@binary.ByteOrder,
) -> RelocInfo {
  RelocInfo::{ addr: @binary.read(r, bo), symnum: @binary.read(r, bo) }
}

///|
fn File::push_section(
  bo : &@binary.ByteOrder,
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
        match bo.view() {
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
