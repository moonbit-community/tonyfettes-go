///|
/// Test cases for parser functionality
test "parse_file too small" {
  let small_data : Bytes = "12"
  try {
    let _ = parse_file(small_data)
    fail("Expected error for too small file")
  } catch {
    FormatError::FileTooSmall(actual_size~, required_size~) => {
      assert_eq(actual_size, 2)
      assert_eq(required_size, 4)
    }
    _ => fail("Expected FileTooSmall error")
  }
}

///|
test "parse_file invalid magic" {
  let invalid_data : Bytes = "\x12\x34\x56\x78extra data here"
  try {
    let _ = parse_file(invalid_data)
    fail("Expected error for invalid magic")
  } catch {
    FormatError::InvalidMagic(magic~) =>
      // Magic should be 0x78563412 when read as little endian
      assert_eq(magic, 0x78563412_U)
    _ => fail("Expected InvalidMagic error")
  }
}

///|
test "parse file header basic" {
  // Create a minimal valid header using type annotation
  // Magic number for 32-bit Mach-O (0xfeedface in little endian = 0xce 0xfa 0xed 0xfe)
  let header_data : Bytes = "\xce\xfa\xed\xfe" + // magic_32 (little endian)
    "\x07\x00\x00\x00" + // cpu (i386 = 7)
    "\x00\x00\x00\x00" + // subcpu (0)
    "\x02\x00\x00\x00" + // file type (exec = 2)
    "\x00\x00\x00\x00" + // ncmd (0)
    "\x00\x00\x00\x00" + // cmdsz (0)
    "\x00\x00\x00\x00" // flags (0)
  try {
    let file = parse_file(header_data)
    assert_eq(file.header.magic, magic_32)
    assert_eq(file.header.cpu, I386)
    assert_eq(file.header.type_, Exec)
    assert_eq(file.header.ncmd, 0_U)
    assert_eq(file.header.cmdsz, 0_U)
    assert_eq(file.header.flags, 0_U)
    assert_eq(file.byte_order, Little)
    assert_eq(file.loads.length(), 0)
    assert_eq(file.sections.length(), 0)
  } catch {
    _ => fail("Expected successful parsing")
  }
}

///|
test "new_file convenience function" {
  let small_data : Bytes = "12"
  try {
    let _ = new_file(small_data)
    fail("Expected error")
  } catch {
    FormatError::FileTooSmall(_) => ()
    _ => fail("Expected FileTooSmall error")
  }
}
