/// Relocation Processing
///
/// Handles parsing and processing of Mach-O relocation entries, including
/// both scattered and non-scattered relocation formats.
/// Based on Apple's Mach-O specification and Go's debug/macho implementation.

///|
/// Parse relocations for a section from raw binary data
fn parse_relocations(
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
