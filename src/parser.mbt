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
  { header, byte_order, loads, sections, symtab, dysymtab }
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
