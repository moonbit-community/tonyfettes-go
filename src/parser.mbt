///| Main Mach-O file parsing functionality

///| Based on Go's debug/macho package

///|
/// Result type for parsing operations
pub enum ParseResult[T] {
  Ok(T)
  Err(FormatError)
} derive(Show)

///|
/// Create a new File from raw bytes
pub fn parse_file(data : Bytes) -> ParseResult[File] {
  if data.length() < 4 {
    return Err({ offset: 0L, message: "File too small", value: None })
  }

  // Read magic number to determine byte order and architecture
  let magic = read_uint(data, 0, Little)
  let byte_order = match determine_byte_order(magic) {
    Some(order) => order
    None =>
      return Err({ offset: 0L, message: "Invalid magic number", value: None })
  }

  // Correct magic number based on detected byte order
  let actual_magic = read_uint(data, 0, byte_order)

  // Parse file header
  match parse_file_header(data, byte_order, actual_magic) {
    Ok(header) => parse_file_with_header(data, header, byte_order)
    Err(err) => Err(err)
  }
}

///|
/// Parse the file header
fn parse_file_header(
  data : Bytes,
  byte_order : ByteOrder,
  magic : UInt,
) -> ParseResult[FileHeader] {
  let header_size = if magic == magic_64 {
    file_header_size_64
  } else {
    file_header_size_32
  }
  if data.length() < header_size {
    return Err({ offset: 0L, message: "Incomplete file header", value: None })
  }
  let cpu = Cpu::from_uint(read_uint(data, 4, byte_order))
  let sub_cpu = read_uint(data, 8, byte_order)
  let type_ = Type::from_uint(read_uint(data, 12, byte_order))
  let ncmd = read_uint(data, 16, byte_order)
  let cmdsz = read_uint(data, 20, byte_order)
  let flags = read_uint(data, 24, byte_order)
  Ok({ magic, cpu, sub_cpu, type_, ncmd, cmdsz, flags })
}

///|
/// Parse the complete file with header
fn parse_file_with_header(
  data : Bytes,
  header : FileHeader,
  byte_order : ByteOrder,
) -> ParseResult[File] {
  let header_size = if header.magic == magic_64 {
    file_header_size_64
  } else {
    file_header_size_32
  }

  // Validate command size
  if header_size.reinterpret_as_uint() + header.cmdsz >
    data.length().reinterpret_as_uint() {
    return Err({
      offset: header_size.to_int64(),
      message: "Command data extends beyond file",
      value: None,
    })
  }

  // Parse load commands
  let cmd_data = read_bytes(
    data,
    header_size,
    header.cmdsz.reinterpret_as_int(),
  )
  match parse_load_commands(cmd_data, byte_order, header.ncmd) {
    Ok((loads, sections, symtab, dysymtab)) =>
      Ok({ header, byte_order, loads, sections, symtab, dysymtab })
    Err(err) => Err(err)
  }
}

///|
/// Parse all load commands
fn parse_load_commands(
  data : Bytes,
  byte_order : ByteOrder,
  ncmd : UInt,
) -> ParseResult[(Array[LoadCommand], Array[Section], Symtab?, Dysymtab?)] {
  let loads = Array::new()
  let sections = Array::new()
  let mut symtab : Symtab? = None
  let mut dysymtab : Dysymtab? = None
  let mut offset = 0
  let mut cmd_count = 0_U
  while cmd_count < ncmd && offset + 8 <= data.length() {
    // Read command header
    let cmd = LoadCmd::from_uint(read_uint(data, offset, byte_order))
    let siz = read_uint(data, offset + 4, byte_order)
    if siz < 8_U || offset + siz.reinterpret_as_int() > data.length() {
      return Err({
        offset: offset.to_int64(),
        message: "Invalid command size",
        value: None,
      })
    }
    let cmddat = read_bytes(data, offset, siz.reinterpret_as_int())

    // Parse specific command types
    match cmd {
      LoadCmd::Segment =>
        match parse_segment_32(cmddat, byte_order) {
          Ok((segment, segment_sections)) => {
            loads.push(LoadCommand::Segment(segment))
            for section in segment_sections {
              sections.push(section)
            }
          }
          Err(err) => return Err(err)
        }
      LoadCmd::Segment64 =>
        match parse_segment_64(cmddat, byte_order) {
          Ok((segment, segment_sections)) => {
            loads.push(LoadCommand::Segment(segment))
            for section in segment_sections {
              sections.push(section)
            }
          }
          Err(err) => return Err(err)
        }
      LoadCmd::Symtab =>
        match parse_symtab_cmd(cmddat, byte_order) {
          Ok(st) => {
            loads.push(LoadCommand::Symtab(st))
            symtab = Some(st)
          }
          Err(err) => return Err(err)
        }
      LoadCmd::Dysymtab =>
        match parse_dysymtab_cmd(cmddat, byte_order) {
          Ok(dst) => {
            loads.push(LoadCommand::Dysymtab(dst))
            dysymtab = Some(dst)
          }
          Err(err) => return Err(err)
        }
      LoadCmd::Dylib =>
        match parse_dylib_cmd(cmddat, byte_order) {
          Ok(dylib) => loads.push(LoadCommand::Dylib(dylib))
          Err(err) => return Err(err)
        }
      LoadCmd::Rpath =>
        match parse_rpath_cmd(cmddat, byte_order) {
          Ok(rpath) => loads.push(LoadCommand::Rpath(rpath))
          Err(err) => return Err(err)
        }
      _ =>
        // Unknown command, store as raw bytes
        loads.push(LoadCommand::LoadBytes({ data: cmddat }))
    }
    offset = offset + siz.reinterpret_as_int()
    cmd_count = cmd_count + 1_U
  }
  Ok((loads, sections, symtab, dysymtab))
}

/// Convenience functions for creating File instances

///|
/// Create a File directly from bytes
pub fn new_file(data : Bytes) -> ParseResult[File] {
  parse_file(data)
}
