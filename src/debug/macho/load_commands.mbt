///|
fn Segment32::parse(
  data : @slice.Slice[Byte],
  byte_order : ByteOrder,
) -> (Segment, Array[Section]) raise {
  if data.length() < 56 {
    raise ParseError::SegmentTooSmall(offset=0L, command_type="Segment32")
  }
  let cmd = LoadCmd::from_uint(read_uint(data, 0, byte_order))
  let len = read_uint(data, 4, byte_order)
  let name : @slice.Slice[Byte] = read_cstring(data, 8)
  let addr = read_uint(data, 24, byte_order).to_uint64()
  let memsz = read_uint(data, 28, byte_order).to_uint64()
  let offset = read_uint(data, 32, byte_order).to_uint64()
  let filesz = read_uint(data, 36, byte_order).to_uint64()
  let maxprot = read_uint(data, 40, byte_order)
  let prot = read_uint(data, 44, byte_order)
  let nsect = read_uint(data, 48, byte_order)
  let flag = read_uint(data, 52, byte_order)
  let header : SegmentHeader = {
    cmd,
    len,
    name,
    addr,
    memsz,
    offset,
    filesz,
    maxprot,
    prot,
    nsect,
    flag,
  }
  let segment = { load_bytes: { data, }, header, data: None }
  let sections = Array::new()
  let section_offset = 56
  for i = 0; i < nsect.reinterpret_as_int(); i = i + 1 {
    let sect_start = section_offset + i * 68
    if sect_start + 68 > data.length() {
      raise ParseError::SectionDataOverflow(
        offset=sect_start.to_int64(),
        section_type="Section32",
      )
    }
    let section = Section32::parse(read_bytes(data, sect_start, 68), byte_order)
    sections.push(section)
  }
  (segment, sections)
}

///|
fn Segment64::parse(
  data : @slice.Slice[Byte],
  byte_order : ByteOrder,
) -> (Segment, Array[Section]) raise {
  if data.length() < 72 {
    raise ParseError::SegmentTooSmall(offset=0L, command_type="Segment64")
  }
  let cmd = LoadCmd::from_uint(read_uint(data, 0, byte_order))
  let len = read_uint(data, 4, byte_order)
  let name : @slice.Slice[Byte] = read_cstring(data, 8)
  let addr = read_uint64(data, 24, byte_order)
  let memsz = read_uint64(data, 32, byte_order)
  let offset = read_uint64(data, 40, byte_order)
  let filesz = read_uint64(data, 48, byte_order)
  let maxprot = read_uint(data, 56, byte_order)
  let prot = read_uint(data, 60, byte_order)
  let nsect = read_uint(data, 64, byte_order)
  let flag = read_uint(data, 68, byte_order)
  let header : SegmentHeader = {
    cmd,
    len,
    name,
    addr,
    memsz,
    offset,
    filesz,
    maxprot,
    prot,
    nsect,
    flag,
  }
  let segment = { load_bytes: { data, }, header, data: None }
  let sections = Array::new()
  let section_offset = 72
  for i = 0; i < nsect.reinterpret_as_int(); i = i + 1 {
    let sect_start = section_offset + i * 80
    if sect_start + 80 > data.length() {
      raise ParseError::SectionDataOverflow(
        offset=sect_start.to_int64(),
        section_type="Section64",
      )
    }
    let section = Section64::parse(read_bytes(data, sect_start, 80), byte_order)
    sections.push(section)
  }
  (segment, sections)
}

///|
fn Section32::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Section raise {
  if data.length() < 68 {
    raise ParseError::MissingData(offset=0L, expected="Section32 (68 bytes)")
  }
  let name : @slice.Slice[Byte] = read_cstring(data, 0)
  let seg : @slice.Slice[Byte] = read_cstring(data, 16)
  let addr = read_uint(data, 32, byte_order).to_uint64()
  let size = read_uint(data, 36, byte_order).to_uint64()
  let offset = read_uint(data, 40, byte_order)
  let align = read_uint(data, 44, byte_order)
  let reloff = read_uint(data, 48, byte_order)
  let nreloc = read_uint(data, 52, byte_order)
  let flags = read_uint(data, 56, byte_order)
  let header : SectionHeader = {
    name,
    seg,
    addr,
    size,
    offset,
    align,
    reloff,
    nreloc,
    flags,
  }
  { header, relocs: Array::new(), data: None }
}

///|
fn Section64::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Section raise {
  if data.length() < 80 {
    raise ParseError::MissingData(offset=0L, expected="Section64 (80 bytes)")
  }
  let name : @slice.Slice[Byte] = read_cstring(data, 0)
  let seg : @slice.Slice[Byte] = read_cstring(data, 16)
  let addr = read_uint64(data, 32, byte_order)
  let size = read_uint64(data, 40, byte_order)
  let offset = read_uint(data, 48, byte_order)
  let align = read_uint(data, 52, byte_order)
  let reloff = read_uint(data, 56, byte_order)
  let nreloc = read_uint(data, 60, byte_order)
  let flags = read_uint(data, 64, byte_order)
  let header : SectionHeader = {
    name,
    seg,
    addr,
    size,
    offset,
    align,
    reloff,
    nreloc,
    flags,
  }
  { header, relocs: Array::new(), data: None }
}

///|
fn SymtabCmd::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Symtab raise {
  if data.length() < 24 {
    raise ParseError::MissingData(offset=0L, expected="SymtabCmd (24 bytes)")
  }
  let symoff = read_uint(data, 8, byte_order)
  let nsyms = read_uint(data, 12, byte_order)
  let stroff = read_uint(data, 16, byte_order)
  let strsize = read_uint(data, 20, byte_order)
  { load_bytes: { data, }, symoff, nsyms, stroff, strsize, syms: Array::new() }
}

///|
fn DysymtabCmd::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Dysymtab raise {
  if data.length() < 80 {
    raise ParseError::MissingData(offset=0L, expected="DysymtabCmd (80 bytes)")
  }
  let ilocalsym = read_uint(data, 8, byte_order)
  let nlocalsym = read_uint(data, 12, byte_order)
  let iextdefsym = read_uint(data, 16, byte_order)
  let nextdefsym = read_uint(data, 20, byte_order)
  let iundefsym = read_uint(data, 24, byte_order)
  let nundefsym = read_uint(data, 28, byte_order)
  let tocoffset = read_uint(data, 32, byte_order)
  let ntoc = read_uint(data, 36, byte_order)
  let modtaboff = read_uint(data, 40, byte_order)
  let nmodtab = read_uint(data, 44, byte_order)
  let extrefsymoff = read_uint(data, 48, byte_order)
  let nextrefsyms = read_uint(data, 52, byte_order)
  let indirectsymoff = read_uint(data, 56, byte_order)
  let nindirectsyms = read_uint(data, 60, byte_order)
  let extreloff = read_uint(data, 64, byte_order)
  let nextrel = read_uint(data, 68, byte_order)
  let locreloff = read_uint(data, 72, byte_order)
  let nlocrel = read_uint(data, 76, byte_order)
  {
    load_bytes: { data, },
    ilocalsym,
    nlocalsym,
    iextdefsym,
    nextdefsym,
    iundefsym,
    nundefsym,
    tocoffset,
    ntoc,
    modtaboff,
    nmodtab,
    extrefsymoff,
    nextrefsyms,
    indirectsymoff,
    nindirectsyms,
    extreloff,
    nextrel,
    locreloff,
    nlocrel,
    indirect_syms: Array::new(),
  }
}

///|
fn DylibCmd::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Dylib raise {
  if data.length() < 24 {
    raise ParseError::MissingData(offset=0L, expected="DylibCmd (24 bytes)")
  }
  let name_offset = read_uint(data, 8, byte_order)
  let time = read_uint(data, 12, byte_order)
  let current_version = read_uint(data, 16, byte_order)
  let compat_version = read_uint(data, 20, byte_order)
  if name_offset.reinterpret_as_int() >= data.length() {
    raise InvalidDataError::InvalidOffset(
      offset=name_offset.reinterpret_as_int(),
      max_offset=data.length(),
      context="dylib name offset",
    )
  }
  let name = read_cstring(data, name_offset.reinterpret_as_int())
  { load_bytes: { data, }, name, time, current_version, compat_version }
}

///|
fn RpathCmd::parse(data : @slice.Slice[Byte], byte_order : ByteOrder) -> Rpath raise {
  if data.length() < 12 {
    raise ParseError::MissingData(offset=0L, expected="RpathCmd (12 bytes)")
  }
  let path_offset = read_uint(data, 8, byte_order)
  if path_offset.reinterpret_as_int() >= data.length() {
    raise InvalidDataError::InvalidOffset(
      offset=path_offset.reinterpret_as_int(),
      max_offset=data.length(),
      context="rpath path offset",
    )
  }
  let path = read_cstring(data, path_offset.reinterpret_as_int())
  { load_bytes: { data, }, path }
}
