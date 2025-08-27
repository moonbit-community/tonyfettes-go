///|
test "parse_relocations empty count" {
  let data : Bytes = "some data"
  let relocs = parse_relocations(data, 0, 0_U, Little)
  assert_eq(relocs.length(), 0)
}

///|
test "parse_relocations buffer overflow" {
  let data : Bytes = "short"
  try {
    let _ = parse_relocations(data, 0, 2_U, Little) // Need 16 bytes, only have 5
    fail("Expected ReadOverflow error")
  } catch {
    BufferOverflowError::ReadOverflow(
      offset~,
      length~,
      buffer_size~,
      operation~
    ) => {
      assert_eq(offset, 0)
      assert_eq(length, 16) // 2 relocations * 8 bytes each
      assert_eq(buffer_size, 5)
      assert_eq(operation, "parse_relocations")
    }
    _ => fail("Expected ReadOverflow error")
  }
}

///|
test "parse_relocations success little endian" {
  // Create relocation data: 2 relocations, 8 bytes each (addr + info)
  let data : Bytes = b"\x00\x10\x00\x00\x01\x00\x00\x08" + // addr=0x1000, info=0x08000001 (extern, type=0)
    b"\x00\x20\x00\x00\x02\x00\x00\x10" // addr=0x2000, info=0x10000002 (extern, type=1)
  let relocs = parse_relocations(data, 0, 2_U, Little)
  assert_eq(relocs.length(), 2)
  assert_eq(relocs[0].addr, 0x1000_U)
  assert_eq(relocs[0].type_, 0)
  assert_eq(relocs[1].addr, 0x2000_U)
  assert_eq(relocs[1].type_, 1)
}

///|
test "parse_relocations success big endian" {
  // Create relocation data for big endian
  let data : Bytes = b"\x00\x00\x10\x00\x08\x00\x00\x01" + // addr=0x1000, info=0x08000001
    b"\x00\x00\x20\x00\x10\x00\x00\x02" // addr=0x2000, info=0x10000002
  let relocs = parse_relocations(data, 0, 2_U, Big)
  assert_eq(relocs.length(), 2)
  assert_eq(relocs[0].addr, 0x1000_U)
  assert_eq(relocs[1].addr, 0x2000_U)
}

///|
test "parse_section_with_relocations no relocations" {
  let section : Section = {
    header: {
      name: "__text",
      seg: "__TEXT",
      addr: 0_UL,
      size: 100_UL,
      offset: 1000_U,
      align: 4_U,
      reloff: 0_U,
      nreloc: 0_U,
      flags: 0_U,
    },
    relocs: [],
    data: None,
  }
  let file_data : Bytes = "dummy file data"
  let result = parse_section_with_relocations(section, file_data, Little)
  assert_eq(result.relocs.length(), 0)
}

///|
test "parse_section_with_relocations with relocations" {
  let section : Section = {
    header: {
      name: "__text",
      seg: "__TEXT",
      addr: 0_UL,
      size: 100_UL,
      offset: 1000_U,
      align: 4_U,
      reloff: 0_U, // Relocations at offset 0
      nreloc: 1_U, // 1 relocation
      flags: 0_U,
    },
    relocs: [],
    data: None,
  }
  // File data with one relocation at the beginning
  let file_data : Bytes = b"\x00\x10\x00\x00\x01\x00\x00\x08" +
    Bytes::make(1000, b'\x00')
  let result = parse_section_with_relocations(section, file_data, Little)
  assert_eq(result.relocs.length(), 1)
  assert_eq(result.relocs[0].addr, 0x1000_U)
}

///|
test "is_valid_reloc_type amd64" {
  assert_true(is_valid_reloc_type(0, Amd64))
  assert_true(is_valid_reloc_type(5, Amd64))
  assert_true(is_valid_reloc_type(9, Amd64))
  assert_false(is_valid_reloc_type(10, Amd64))
  assert_false(is_valid_reloc_type(-1, Amd64))
}

///|
test "is_valid_reloc_type arm" {
  assert_true(is_valid_reloc_type(0, Arm))
  assert_true(is_valid_reloc_type(6, Arm))
  assert_true(is_valid_reloc_type(8, Arm))
  assert_true(is_valid_reloc_type(9, Arm))
  assert_false(is_valid_reloc_type(7, Arm)) // 7 is unused
  assert_false(is_valid_reloc_type(10, Arm))
}

///|
test "is_valid_reloc_type arm64" {
  assert_true(is_valid_reloc_type(0, Arm64))
  assert_true(is_valid_reloc_type(5, Arm64))
  assert_true(is_valid_reloc_type(10, Arm64))
  assert_false(is_valid_reloc_type(11, Arm64))
}

///|
test "is_valid_reloc_type i386" {
  assert_true(is_valid_reloc_type(0, I386))
  assert_true(is_valid_reloc_type(5, I386))
  assert_false(is_valid_reloc_type(6, I386))
}

///|
test "is_valid_reloc_type unknown cpu" {
  assert_true(is_valid_reloc_type(0, Ppc))
  assert_true(is_valid_reloc_type(5, Ppc))
  assert_false(is_valid_reloc_type(6, Ppc))
}

///|
test "reloc_length_bytes" {
  assert_eq(reloc_length_bytes(0), 1)
  assert_eq(reloc_length_bytes(1), 2)
  assert_eq(reloc_length_bytes(2), 4)
  assert_eq(reloc_length_bytes(3), 8)
  assert_eq(reloc_length_bytes(4), 0) // Invalid
  assert_eq(reloc_length_bytes(-1), 0) // Invalid
}

///|
test "format_relocation normal" {
  let reloc : Reloc = {
    addr: 0x1000_U,
    value: 42_U,
    type_: 2,
    len: 2,
    pcrel: true,
    is_extern: true,
    scattered: false,
  }
  let formatted = format_relocation(reloc)
  assert_true(formatted.contains("addr=0x4096"))
  assert_true(formatted.contains("value=42"))
  assert_true(formatted.contains("type=2"))
  assert_true(formatted.contains("len=4bytes"))
  assert_true(formatted.contains("PC-relative"))
  assert_true(formatted.contains("extern"))
  assert_true(formatted.contains("normal"))
}

///|
test "format_relocation scattered" {
  let reloc : Reloc = {
    addr: 0x2000_U,
    value: 0x12345_U,
    type_: 1,
    len: 1,
    pcrel: false,
    is_extern: false,
    scattered: true,
  }
  let formatted = format_relocation(reloc)
  assert_true(formatted.contains("addr=0x8192"))
  assert_true(formatted.contains("value=74565"))
  assert_true(formatted.contains("type=1"))
  assert_true(formatted.contains("len=2bytes"))
  assert_true(formatted.contains("absolute"))
  assert_true(formatted.contains("local"))
  assert_true(formatted.contains("scattered"))
}
