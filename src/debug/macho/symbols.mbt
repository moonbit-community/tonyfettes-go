///|
fn parse_symbols(
  symdata : @slice.Slice[Byte],
  strtab : @slice.Slice[Byte],
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
  symdata : @slice.Slice[Byte],
  strtab : @slice.Slice[Byte],
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
  let name : @slice.Slice[Byte] = if name_index.reinterpret_as_int() <
    strtab.length() {
    let name_data = read_cstring(strtab, name_index.reinterpret_as_int())
    let raw_name = name_data
    if raw_name.length() > 0 && raw_name[0] == '_' && raw_name.contains('.') {
      raw_name[1:]
    } else {
      raw_name
    }
  } else {
    @slice.bytes("<invalid>")
  }
  { name, type_, sect, desc, value }
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
      if (s.type_ & 0x0e) == 0x0 && (s.type_ & 0x01) != 0 {
        all.push(s.name)
      }
    }
  }
  all
}

///|
pub fn File::imported_libraries(self : File) -> Array[@slice.Slice[Byte]] {
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
pub fn File::segment(self : File, name : @slice.Slice[Byte]) -> Segment? {
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
pub fn File::section(self : File, name : @slice.Slice[Byte]) -> Section? {
  for section in self.sections {
    if section.header.name == name {
      return Some(section)
    }
  }
  None
}
