///|
pub fn parse_file(data : Bytes) -> File raise {
  if data.length() < 4 {
    raise FormatError::FileTooSmall(actual_size=data.length(), required_size=4)
  }
  let magic = read_uint(data, 0, Little)
  let byte_order = match determine_byte_order(magic) {
    Some(order) => order
    None => raise FormatError::InvalidMagic(magic~)
  }
  let actual_magic = read_uint(data, 0, byte_order)
  let header = parse_file_header(data, byte_order, actual_magic)
  parse_file_with_header(data, header, byte_order)
}

///|
fn parse_file_header(
  data : Bytes,
  byte_order : ByteOrder,
  magic : UInt,
) -> FileHeader raise {
  let header_size = if magic == magic_64 {
    file_header_size_64
  } else {
    file_header_size_32
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
  data : Bytes,
  header : FileHeader,
  byte_order : ByteOrder,
) -> File raise {
  let header_size = if header.magic == magic_64 {
    file_header_size_64
  } else {
    file_header_size_32
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
      let is_64bit = header.magic == magic_64
      Some(parse_symtab(data, st, is_64bit, byte_order)) catch {
        _ => Some(st) // Fall back to original symtab if parsing fails
      }
    }
    None => None
  }
  { header, byte_order, loads, sections, symtab: final_symtab, dysymtab }
}

///|
fn parse_load_commands(
  data : Bytes,
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
        let (segment, segment_sections) = parse_segment_32(cmddat, byte_order)
        loads.push(LoadCommand::Segment(segment))
        for section in segment_sections {
          sections.push(section)
        }
      }
      LoadCmd::Segment64 => {
        let (segment, segment_sections) = parse_segment_64(cmddat, byte_order)
        loads.push(LoadCommand::Segment(segment))
        for section in segment_sections {
          sections.push(section)
        }
      }
      LoadCmd::Symtab => {
        let st = parse_symtab_cmd(cmddat, byte_order)
        loads.push(LoadCommand::Symtab(st))
        symtab = Some(st)
      }
      LoadCmd::Dysymtab => {
        let dst = parse_dysymtab_cmd(cmddat, byte_order)
        loads.push(LoadCommand::Dysymtab(dst))
        dysymtab = Some(dst)
      }
      LoadCmd::Dylib => {
        let dylib = parse_dylib_cmd(cmddat, byte_order)
        loads.push(LoadCommand::Dylib(dylib))
      }
      LoadCmd::Rpath => {
        let rpath = parse_rpath_cmd(cmddat, byte_order)
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
pub fn new_file(data : Bytes) -> File raise {
  parse_file(data)
}

///|
pub fn open_file(path : String) -> File raise {
  let data = @fs.read_file_to_bytes(path)
  parse_file(data)
}

///|
pub fn parse_symtab(
  file_data : Bytes,
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
