///|
fn parse_symbols(
  symdata : Bytes,
  strtab : Bytes,
  nsyms : UInt,
  is_64bit : Bool,
  byte_order : ByteOrder,
) -> Array[Symbol] raise {
  let symbols = Array::new()
  let symbol_size = if is_64bit { 16 } else { 12 }
  if symdata.length() < nsyms.reinterpret_as_int() * symbol_size {
    raise ParseError::MissingData(
      offset=0L,
      expected="Symbol table data (" +
        (nsyms.reinterpret_as_int() * symbol_size).to_string() +
        " bytes)",
    )
  }
  for i = 0; i < nsyms.reinterpret_as_int(); i = i + 1 {
    let offset = i * symbol_size
    let symbol = parse_single_symbol(
      symdata, strtab, offset, is_64bit, byte_order,
    )
    symbols.push(symbol)
  }
  symbols
}

///|
fn parse_single_symbol(
  symdata : Bytes,
  strtab : Bytes,
  offset : Int,
  is_64bit : Bool,
  byte_order : ByteOrder,
) -> Symbol raise {
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
  let name : Bytes = if name_index.reinterpret_as_int() < strtab.length() {
    let name_data = read_bytes(
      strtab,
      name_index.reinterpret_as_int(),
      strtab.length() - name_index.reinterpret_as_int(),
    )
    let raw_name = name_data
    if raw_name.length() > 0 && raw_name[0] == '_' && raw_name.contains('.') {
      [..raw_name[1:]]
    } else {
      raw_name
    }
  } else {
    "<invalid>"
  }
  { name, type_, sect, desc, value }
}

///|
fn parse_dynamic_symbol_indices(
  data : Bytes,
  nindirectsyms : UInt,
  byte_order : ByteOrder,
) -> Array[UInt] raise {
  let indices = Array::new()
  let expected_size = nindirectsyms.reinterpret_as_int() * 4
  if data.length() < expected_size {
    raise ParseError::MissingData(
      offset=0L,
      expected="Dynamic symbol indices data (" +
        expected_size.to_string() +
        " bytes)",
    )
  }
  for i = 0; i < nindirectsyms.reinterpret_as_int(); i = i + 1 {
    let index = read_uint(data, i * 4, byte_order)
    indices.push(index)
  }
  indices
}

///|
pub fn File::imported_symbols(self : File) -> Array[Bytes] {
  let imported : Array[Bytes] = []
  match (self.symtab, self.dysymtab) {
    (Some(st), Some(dt)) => {
      let start_index = dt.iundefsym.reinterpret_as_int()
      let count = dt.nundefsym.reinterpret_as_int()
      let end_index = start_index + count
      for i = start_index; i < end_index && i < st.syms.length(); i = i + 1 {
        imported.push(st.syms[i].name)
      }
    }
    (Some(st), None) =>
      for symbol in st.syms {
        if (symbol.type_ & 0x0e) == 0x0 && symbol.sect == 0 {
          imported.push(symbol.name)
        }
      }
    _ => ()
  }
  imported
}

///|
pub fn File::imported_libraries(self : File) -> Array[Bytes] {
  let libraries = Array::new()
  for load_cmd in self.loads {
    match load_cmd {
      LoadCommand::Dylib(dylib) => libraries.push(dylib.name)
      _ => ()
    }
  }
  libraries
}

///|
pub fn File::segment(self : File, name : Bytes) -> Segment? {
  for load_cmd in self.loads {
    match load_cmd {
      LoadCommand::Segment(segment) =>
        if segment.header.name == name {
          return Some(segment)
        }
      _ => ()
    }
  }
  None
}

///|
pub fn File::section(self : File, name : Bytes) -> Section? {
  for section in self.sections {
    if section.header.name == name {
      return Some(section)
    }
  }
  None
}
