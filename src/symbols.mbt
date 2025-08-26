///| Symbol table parsing functionality for Mach-O files

///| Handles parsing of symbol tables and string tables

///|
/// Parse symbols from symbol table data
pub fn parse_symbols(
  symdata : Bytes,
  strtab : Bytes,
  nsyms : UInt,
  is_64bit : Bool,
  byte_order : ByteOrder,
) -> ParseResult[Array[Symbol]] {
  let symbols = Array::new()
  let symbol_size = if is_64bit { 16 } else { 12 }
  if symdata.length() < nsyms.reinterpret_as_int() * symbol_size {
    return Err({
      offset: 0L,
      message: "Symbol table data too small",
      value: None,
    })
  }
  for i = 0; i < nsyms.reinterpret_as_int(); i = i + 1 {
    let offset = i * symbol_size
    match parse_single_symbol(symdata, strtab, offset, is_64bit, byte_order) {
      Ok(symbol) => symbols.push(symbol)
      Err(err) => return Err(err)
    }
  }
  Ok(symbols)
}

///|
/// Parse a single symbol entry
fn parse_single_symbol(
  symdata : Bytes,
  strtab : Bytes,
  offset : Int,
  is_64bit : Bool,
  byte_order : ByteOrder,
) -> ParseResult[Symbol] {
  let name_index = read_uint(symdata, offset, byte_order)
  let type_ = symdata[offset + 4].to_int()
  let sect = symdata[offset + 5].to_int()
  let desc = read_uint(symdata, offset + 6, byte_order)
    .land(0xFFFF_U)
    .reinterpret_as_int()
  let value = if is_64bit {
    read_uint64(symdata, offset + 8, byte_order)
  } else {
    read_uint(symdata, offset + 8, byte_order).to_uint64()
  }

  // Extract symbol name from string table
  let name : Bytes = if name_index.reinterpret_as_int() < strtab.length() {
    let name_data = read_bytes(
      strtab,
      name_index.reinterpret_as_int(),
      strtab.length() - name_index.reinterpret_as_int(),
    )
    let raw_name = name_data
    // Remove leading underscore if present (Go compatibility)
    if raw_name.length() > 0 && raw_name[0] == '_' && raw_name.contains('.') {
      [..raw_name[1:]]
    } else {
      raw_name
    }
  } else {
    "<invalid>"
  }
  Ok({ name, type_, sect, desc, value })
}

///|
/// Parse dynamic symbol indices
pub fn parse_dynamic_symbol_indices(
  data : Bytes,
  nindirectsyms : UInt,
  byte_order : ByteOrder,
) -> ParseResult[Array[UInt]] {
  let indices = Array::new()
  let expected_size = nindirectsyms.reinterpret_as_int() * 4
  if data.length() < expected_size {
    return Err({
      offset: 0L,
      message: "Dynamic symbol indices data too small",
      value: None,
    })
  }
  for i = 0; i < nindirectsyms.reinterpret_as_int(); i = i + 1 {
    let index = read_uint(data, i * 4, byte_order)
    indices.push(index)
  }
  Ok(indices)
}

///|
/// Extract imported symbols from the symbol table
pub fn get_imported_symbols(file : File) -> Array[Bytes] {
  let imported = Array::new()
  match (file.symtab, file.dysymtab) {
    (Some(st), Some(dt)) => {
      // Extract undefined symbols (imported symbols)
      let start_index = dt.iundefsym.reinterpret_as_int()
      let count = dt.nundefsym.reinterpret_as_int()
      let end_index = start_index + count
      for i = start_index; i < end_index && i < st.syms.length(); i = i + 1 {
        imported.push(st.syms[i].name)
      }
    }
    (Some(st), None) =>
      // Fall back to checking symbol types for undefined symbols
      for symbol in st.syms {
        // N_TYPE = 0x0e, N_UNDF = 0x0
        if (symbol.type_ & 0x0e) == 0x0 && symbol.sect == 0 {
          imported.push(symbol.name)
        }
      }
    _ => () // No symbol table available
  }
  imported
}

///|
/// Extract imported libraries from the load commands
pub fn get_imported_libraries(file : File) -> Array[Bytes] {
  let libraries = Array::new()
  for load_cmd in file.loads {
    match load_cmd {
      LoadCommand::Dylib(dylib) => libraries.push(dylib.name)
      _ => () // Not a dylib command
    }
  }
  libraries
}

///|
/// Find a specific segment by name
pub fn find_segment(file : File, name : Bytes) -> Segment? {
  for load_cmd in file.loads {
    match load_cmd {
      LoadCommand::Segment(segment) =>
        if segment.header.name == name {
          return Some(segment)
        }
      _ => () // Not a segment
    }
  }
  None
}

///|
/// Find a specific section by name
pub fn find_section(file : File, name : Bytes) -> Section? {
  for section in file.sections {
    if section.header.name == name {
      return Some(section)
    }
  }
  None
}

///|
/// Get all section names in the file
pub fn get_section_names(file : File) -> Array[Bytes] {
  let names = Array::new()
  for section in file.sections {
    names.push(section.header.name)
  }
  names
}

///|
/// Get all segment names in the file
pub fn get_segment_names(file : File) -> Array[Bytes] {
  let names = Array::new()
  for load_cmd in file.loads {
    match load_cmd {
      LoadCommand::Segment(segment) => names.push(segment.header.name)
      _ => ()
    }
  }
  names
}
