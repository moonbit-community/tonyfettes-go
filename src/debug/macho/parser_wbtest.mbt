///|
test "File::parse too small" {
  let small_data : Bytes = "12"
  try {
    let _ = File::parse(@slice.bytes(small_data))
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
test "File::parse invalid magic" {
  let invalid_data : Bytes = "\x12\x34\x56\x78extra data here"
  try {
    let _ = File::parse(@slice.bytes(invalid_data))
    fail("Expected error for invalid magic")
  } catch {
    FormatError::InvalidMagic(magic~) => assert_eq(magic, 0x78563412_U)
    _ => fail("Expected InvalidMagic error")
  }
}

///|
test "parse file header basic" {
  let header_data : Bytes = "\xce\xfa\xed\xfe" +
    "\x07\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x02\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x00\x00\x00\x00"
  try {
    let file = File::parse(@slice.bytes(header_data))
    assert_eq(file.header.magic, Magic32)
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
test "File::new" {
  let small_data : Bytes = "12"
  try {
    let _ = File::new(@slice.bytes(small_data))
    fail("Expected error")
  } catch {
    FormatError::FileTooSmall(_) => ()
    _ => fail("Expected FileTooSmall error")
  }
}

///|
test "File::parse 64-bit magic" {
  let header_data : Bytes = "\xcf\xfa\xed\xfe" +
    "\x07\x00\x00\x01" +
    "\x00\x00\x00\x00" +
    "\x02\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x00\x00\x00\x00"
  try {
    let file = File::parse(@slice.bytes(header_data))
    assert_eq(file.header.magic, Magic64)
    assert_eq(file.header.cpu, Amd64)
    assert_eq(file.header.type_, Exec)
    assert_eq(file.byte_order, Little)
  } catch {
    _ => fail("Expected successful parsing")
  }
}

///|
test "File::parse with command data overflow" {
  // Create header with moderate cmdsz that would still overflow the 28-byte file
  let header_data : Bytes = "\xce\xfa\xed\xfe" +
    "\x07\x00\x00\x00" +
    "\x00\x00\x00\x00" +
    "\x02\x00\x00\x00" +
    "\x01\x00\x00\x00" +
    "\x64\x00\x00\x00" + // cmdsz = 100 bytes, but file is only 28 bytes  
    "\x00\x00\x00\x00"
  try {
    let _ = File::parse(@slice.bytes(header_data))
    fail("Expected CommandDataOverflow error")
  } catch {
    FormatError::CommandDataOverflow(offset~, size~, file_size~) => {
      assert_eq(offset, 28L)
      assert_eq(size, 100_U)
      assert_eq(file_size, 28)
    }
    _ => fail("Expected CommandDataOverflow error")
  }
}

///|
test "File::parse with load commands" {
  // Create a 32-bit file with one load command (symtab)
  let header_data : Bytes = "\xce\xfa\xed\xfe" + // magic_32
    "\x07\x00\x00\x00" + // cpu = I386  
    "\x00\x00\x00\x00" + // sub_cpu
    "\x02\x00\x00\x00" + // type = Exec
    "\x01\x00\x00\x00" + // ncmd = 1
    "\x18\x00\x00\x00" + // cmdsz = 24 (size of symtab command)
    "\x00\x00\x00\x00" + // flags
    // Symtab load command (24 bytes): cmd + len + symoff + nsyms + stroff + strsize
    "\x02\x00\x00\x00" + // cmd = Symtab
    "\x18\x00\x00\x00" + // len = 24
    "\x00\x10\x00\x00" + // symoff = 0x1000
    "\x0a\x00\x00\x00" + // nsyms = 10
    "\x00\x20\x00\x00" + // stroff = 0x2000  
    "\x00\x01\x00\x00" // strsize = 256
  let file = File::parse(@slice.bytes(header_data))
  assert_eq(file.header.magic, Magic32)
  assert_eq(file.header.ncmd, 1_U)
  assert_eq(file.loads.length(), 1)
  match file.loads[0] {
    LoadCommand::Symtab(symtab) => {
      assert_eq(symtab.symoff, 0x1000_U)
      assert_eq(symtab.nsyms, 10_U)
    }
    _ => fail("Expected Symtab load command")
  }
}

///|
test "parse_load_commands invalid command size" {
  // Create command data with invalid size
  let cmd_data : Bytes = b"\x02\x00\x00\x00\x04\x00\x00\x00" // cmd=2, len=4 (too small, min is 8)
  try {
    let _ = parse_load_commands(@slice.bytes(cmd_data), Little, 1)
    fail("Expected InvalidCommandSize error")
  } catch {
    ParseError::InvalidCommandSize(offset~, size~) => {
      assert_eq(offset, 0)
      assert_eq(size, 4_U)
    }
    _ => fail("Expected InvalidCommandSize error")
  }
}
