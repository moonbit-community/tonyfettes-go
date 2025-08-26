///|
/// Test cases for parser functionality
test "parse_file too small" {
  let small_data : Bytes = "12"
  match parse_file(small_data) {
    Ok(_) => fail("Expected error for too small file")
    Err(err) => {
      assert_eq(err.message, "File too small")
      assert_eq(err.offset, 0L)
    }
  }
}

///|
test "parse_file invalid magic" {
  let invalid_data : Bytes = "\x12\x34\x56\x78extra data here"
  match parse_file(invalid_data) {
    Ok(_) => fail("Expected error for invalid magic")
    Err(err) => {
      assert_eq(err.message, "Invalid magic number")
      assert_eq(err.offset, 0L)
    }
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
  match parse_file(header_data) {
    Ok(file) => {
      assert_eq(file.header.magic, magic_32)
      assert_eq(file.header.cpu, I386)
      assert_eq(file.header.type_, Exec)
      assert_eq(file.header.ncmd, 0_U)
      assert_eq(file.header.cmdsz, 0_U)
      assert_eq(file.header.flags, 0_U)
      assert_eq(file.byte_order, Little)
      assert_eq(file.loads.length(), 0)
      assert_eq(file.sections.length(), 0)
    }
    Err(err) => fail("Expected successful parsing: " + err.message)
  }
}

///|
test "new_file convenience function" {
  let small_data : Bytes = "12"
  match new_file(small_data) {
    Ok(_) => fail("Expected error")
    Err(err) => assert_eq(err.message, "File too small")
  }
}

///|
test "open_file not implemented" {
  match open_file("/some/path") {
    Ok(_) => fail("Expected error")
    Err(err) => {
      assert_eq(err.message, "File system access not implemented")
      assert_eq(err.value, Some("/some/path"))
    }
  }
}
