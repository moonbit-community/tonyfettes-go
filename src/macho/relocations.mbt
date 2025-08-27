/// Relocation Processing
/// 
/// Handles parsing and processing of Mach-O relocation entries, including
/// both scattered and non-scattered relocation formats.
/// Based on Apple's Mach-O specification and Go's debug/macho implementation.

///|
/// Parse relocations for a section from raw binary data
pub fn parse_relocations(
  data : Bytes,
  offset : Int,
  count : UInt,
  byte_order : ByteOrder,
) -> Array[Reloc] raise {
  if count == 0 {
    return Array::new()
  }
  let reloc_size = 8 // Each relocation entry is 8 bytes
  let total_size = count.reinterpret_as_int() * reloc_size
  if offset + total_size > data.length() {
    raise BufferOverflowError::ReadOverflow(
      offset~,
      length=total_size,
      buffer_size=data.length(),
      operation="parse_relocations",
    )
  }
  let relocs = Array::new()
  for i = 0; i < count.reinterpret_as_int(); i = i + 1 {
    let reloc_offset = offset + i * reloc_size

    // Read raw relocation info (8 bytes) - these will raise on error
    let addr = read_uint(data, reloc_offset, byte_order)
    let symnum = read_uint(data, reloc_offset + 4, byte_order)
    let reloc = parse_reloc_info(addr, symnum, byte_order)
    relocs.push(reloc)
  }
  relocs
}

///|
/// Parse a single relocation entry from raw addr/symnum values
fn parse_reloc_info(
  addr : UInt,
  symnum : UInt,
  byte_order : ByteOrder,
) -> Reloc {
  // Check if this is a scattered relocation (bit 31 set in addr)
  let scattered = (addr & 0x80000000U) != 0U
  if scattered {
    // Scattered relocation format
    let reloc_addr = addr & 0x00FFFFFFU // bits 0-23: address
    let reloc_type = (addr >> 24) & 0x0FU // bits 24-27: type
    let reloc_len = (addr >> 28) & 0x03U // bits 28-29: length
    let pcrel = (addr & 0x40000000U) != 0U // bit 30: pcrel
    let reloc_value = symnum // symnum field contains value for scattered
    {
      addr: reloc_addr,
      value: reloc_value,
      type_: reloc_type.reinterpret_as_int(),
      len: reloc_len.reinterpret_as_int(),
      pcrel,
      is_extern: false,
      scattered: true,
    }
  } else { // scattered relocations are not extern
    // Non-scattered relocation format
    match byte_order {
      Little => {
        let reloc_addr = addr
        let reloc_value = symnum & 0x00FFFFFFU // bits 0-23: symbol/section number
        let pcrel = (symnum & 0x01000000U) != 0U // bit 24: pcrel
        let reloc_len = (symnum >> 25) & 0x03U // bits 25-26: length
        let is_extern = (symnum & 0x08000000U) != 0U // bit 27: extern
        let reloc_type = (symnum >> 28) & 0x0FU // bits 28-31: type
        {
          addr: reloc_addr,
          value: reloc_value,
          type_: reloc_type.reinterpret_as_int(),
          len: reloc_len.reinterpret_as_int(),
          pcrel,
          is_extern,
          scattered: false,
        }
      }
      Big => {
        let reloc_addr = addr
        let reloc_value = symnum >> 8 // bits 8-31: symbol/section number
        let pcrel = (symnum & 0x80U) != 0U // bit 7: pcrel
        let reloc_len = (symnum >> 5) & 0x03U // bits 5-6: length
        let is_extern = (symnum & 0x10U) != 0U // bit 4: extern
        let reloc_type = symnum & 0x0FU // bits 0-3: type
        {
          addr: reloc_addr,
          value: reloc_value,
          type_: reloc_type.reinterpret_as_int(),
          len: reloc_len.reinterpret_as_int(),
          pcrel,
          is_extern,
          scattered: false,
        }
      }
    }
  }
}

///|
/// Enhanced section parsing with relocation support
pub fn parse_section_with_relocations(
  section : Section,
  file_data : Bytes,
  byte_order : ByteOrder,
) -> Section raise {
  // Parse relocations if present
  let relocs = if section.header.nreloc > 0U {
    parse_relocations(
      file_data,
      section.header.reloff.reinterpret_as_int(),
      section.header.nreloc,
      byte_order,
    )
  } else {
    Array::new()
  }

  // Return new section with relocations populated
  { header: section.header, relocs, data: section.data }
}

///|
/// Check if a relocation type is valid for a given architecture
pub fn is_valid_reloc_type(reloc_type : Int, cpu_type : Cpu) -> Bool {
  match cpu_type {
    Amd64 =>
      // x86_64 relocation types: 0-9
      reloc_type >= 0 && reloc_type <= 9
    Arm =>
      // ARM relocation types: 0-9 (but 7 is unused)
      (reloc_type >= 0 && reloc_type <= 6) ||
      (reloc_type >= 8 && reloc_type <= 9)
    Arm64 =>
      // ARM64 relocation types: 0-10
      reloc_type >= 0 && reloc_type <= 10
    I386 =>
      // Generic relocation types: 0-5
      reloc_type >= 0 && reloc_type <= 5
    _ =>
      // For other architectures, use generic relocation types
      reloc_type >= 0 && reloc_type <= 5
  }
}

///|
/// Get relocation length in bytes (0=1byte, 1=2bytes, 2=4bytes, 3=8bytes)
pub fn reloc_length_bytes(len_code : Int) -> Int {
  match len_code {
    0 => 1
    1 => 2
    2 => 4
    3 => 8
    _ => 0 // Invalid
  }
}

///|
/// Format relocation information for debugging
pub fn format_relocation(reloc : Reloc) -> String {
  let scattered_str = if reloc.scattered { "scattered" } else { "normal" }
  let extern_str = if reloc.is_extern { "extern" } else { "local" }
  let pcrel_str = if reloc.pcrel { "PC-relative" } else { "absolute" }
  let len_bytes = reloc_length_bytes(reloc.len)
  "Reloc(addr=0x" +
  reloc.addr.to_string() +
  ", value=" +
  reloc.value.to_string() +
  ", type=" +
  reloc.type_.to_string() +
  ", len=" +
  len_bytes.to_string() +
  "bytes, " +
  pcrel_str +
  ", " +
  extern_str +
  ", " +
  scattered_str +
  ")"
}
