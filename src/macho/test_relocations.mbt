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



