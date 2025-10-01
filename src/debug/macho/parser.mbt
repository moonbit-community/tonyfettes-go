///|
fn File::parse(r : &@io.ReaderAt) -> File raise {
  let ident = @slice.make(4)
  let _ = r.read_at(ident[0:], 0)
  if data.length() < 4 {
    raise FormatError::FileTooSmall(actual_size=data.length(), required_size=4)
  }
  let magic = read_uint(data, 0, Little)
  let byte_order = match determine_byte_order(magic) {
    Some(order) => order
    None => raise FormatError::InvalidMagic(magic~)
  }
  let magic = read_uint(data, 0, byte_order)
  let header = FileHeader::parse(data, byte_order, magic)
  parse_file_with_header(data, header, byte_order)
}

///|
fnalias @builtin.int64

///|
fnalias @builtin.uint64

///|
fnalias @builtin.uint as uint32

///|
fnalias @builtin.int

///|
fnalias @builtin.len

///|
fn cstring(b : @slice.Slice[Byte]) -> String {
  let mut i = @bytes.index_byte(b, 0)
  if i == -1 {
    i = len(b)
  }
  return @utf8.decode_lossy(b[0:i])
}

///|
fn new_file(r : &@io.ReaderAt) -> File raise {
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
        let st = {
          ...
        }

      }
      _ => loads.push(LoadBytes::LoadBytes(cmddat))
    }
  }
  ...
}

///|
fn File::parse_symtab(
  f : File,
  symdat : @slice.Slice[Byte],
  strtab : @slice.Slice[Byte],
  cmddat : @slice.Slice[Byte],
  hdr : SymtabCmd,
  offset : Int64,
) -> Symtab raise {
  let bo = f.byte_order
  let symtab = []
  let b = @bytes.new_reader(symdat)
  for i in 0..<hdr.nsyms.reinterpret_as_int() {
    let n : Nlist64 = if f.header.magic == Magic64 {
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
fn FileHeader::parse(
  data : @slice.Slice[Byte],
  byte_order : ByteOrder,
  magic : UInt,
) -> FileHeader raise {
  let header_size = if magic == Magic64 {
    FileHeaderSize64
  } else {
    FileHeaderSize32
  }
  if data.length() < header_size {
    raise FormatError::FileTooSmall(
      actual_size=data.length(),
      required_size=header_size,
    )
  }
  let cpu = Cpu::from_uint(read_uint(data, 4, byte_order))
  let sub_cpu = read_uint(data, 8, byte_order)
  let type_ = Type::from_uint(read_uint(data, 12, byte_order))
  let ncmd = read_uint(data, 16, byte_order)
  let cmdsz = read_uint(data, 20, byte_order)
  let flags = read_uint(data, 24, byte_order)
  { magic, cpu, sub_cpu, type_, ncmd, cmdsz, flags }
}

///|
fn parse_file_with_header(
  data : @slice.Slice[Byte],
  header : FileHeader,
  byte_order : ByteOrder,
) -> File raise {
  let header_size = if header.magic == Magic64 {
    FileHeaderSize64
  } else {
    FileHeaderSize32
  }
  if header_size.reinterpret_as_uint() + header.cmdsz >
    data.length().reinterpret_as_uint() {
    raise FormatError::CommandDataOverflow(
      offset=header_size.to_int64(),
      size=header.cmdsz,
      file_size=data.length(),
    )
  }
  let cmd_data = read_bytes(
    data,
    header_size,
    header.cmdsz.reinterpret_as_int(),
  )
  let (loads, sections, symtab, dysymtab) = parse_load_commands(
    cmd_data,
    byte_order,
    header.ncmd,
  )
  let final_symtab = match symtab {
    Some(st) => {
      let is_64bit = header.magic == Magic64
      Some(Symtab::parse(data, st, is_64bit, byte_order)) catch {
        _ => Some(st) // Fall back to original symtab if parsing fails
      }
    }
    None => None
  }
  { header, byte_order, loads, sections, symtab: final_symtab, dysymtab }
}

///|
fn parse_load_commands(
  data : @slice.Slice[Byte],
  byte_order : ByteOrder,
  ncmd : UInt,
) -> (Array[LoadCommand], Array[Section], Symtab?, Dysymtab?) raise {
  let loads = Array::new()
  let sections = Array::new()
  let mut symtab : Symtab? = None
  let mut dysymtab : Dysymtab? = None
  let mut offset = 0
  let mut cmd_count = 0_U
  while cmd_count < ncmd && offset + 8 <= data.length() {
    let cmd = LoadCmd::from_uint(read_uint(data, offset, byte_order))
    let siz = read_uint(data, offset + 4, byte_order)
    if siz < 8_U || offset + siz.reinterpret_as_int() > data.length() {
      raise ParseError::InvalidCommandSize(offset~, size=siz)
    }
    let cmddat = read_bytes(data, offset, siz.reinterpret_as_int())
    match cmd {
      LoadCmd::Segment => {
        let (segment, segment_sections) = Segment32::parse(cmddat, byte_order)
        loads.push(LoadCommand::Segment(segment))
        for section in segment_sections {
          sections.push(section)
        }
      }
      LoadCmd::Segment64 => {
        let (segment, segment_sections) = Segment64::parse(cmddat, byte_order)
        loads.push(LoadCommand::Segment(segment))
        for section in segment_sections {
          sections.push(section)
        }
      }
      LoadCmd::Symtab => {
        let st = SymtabCmd::parse(cmddat, byte_order)
        loads.push(LoadCommand::Symtab(st))
        symtab = Some(st)
      }
      LoadCmd::Dysymtab => {
        let dst = DysymtabCmd::parse(cmddat, byte_order)
        loads.push(LoadCommand::Dysymtab(dst))
        dysymtab = Some(dst)
      }
      LoadCmd::Dylib => {
        let dylib = DylibCmd::parse(cmddat, byte_order)
        loads.push(LoadCommand::Dylib(dylib))
      }
      LoadCmd::Rpath => {
        let rpath = RpathCmd::parse(cmddat, byte_order)
        loads.push(LoadCommand::Rpath(rpath))
      }
      _ => loads.push(LoadCommand::LoadBytes({ data: cmddat }))
    }
    offset = offset + siz.reinterpret_as_int()
    cmd_count = cmd_count + 1_U
  }
  (loads, sections, symtab, dysymtab)
}

///|
pub fn File::new(data : @slice.Slice[Byte]) -> File raise {
  File::parse(data)
}

///|
pub fn open_file(path : String) -> File raise {
  let data = @fs.read_file_to_bytes(path)
  File::parse(@slice.bytes(data))
}

///|
fn Symtab::parse(
  file_data : @slice.Slice[Byte],
  symtab : Symtab,
  is_64bit : Bool,
  byte_order : ByteOrder,
) -> Symtab raise {
  let symdata_offset = symtab.symoff.reinterpret_as_int()
  let string_table_offset = symtab.stroff.reinterpret_as_int()
  let string_table_size = symtab.strsize.reinterpret_as_int()
  let symdata = read_bytes(
    file_data,
    symdata_offset,
    symtab.nsyms.reinterpret_as_int() * (if is_64bit { 16 } else { 12 }),
  )
  let strtab = read_bytes(file_data, string_table_offset, string_table_size)
  let symbols = parse_symbols(
    symdata,
    strtab,
    symtab.nsyms,
    is_64bit,
    byte_order,
  )
  {
    load_bytes: symtab.load_bytes,
    symoff: symtab.symoff,
    nsyms: symtab.nsyms,
    stroff: symtab.stroff,
    strsize: symtab.strsize,
    syms: symbols,
  }
}
