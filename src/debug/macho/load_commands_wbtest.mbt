///|
test "SymtabCmd::parse success" {
  // Create symtab command: cmd + len + symoff + nsyms + stroff + strsize (little endian)
  let data : Bytes = b"\x02\x00\x00\x00\x18\x00\x00\x00\x00\x10\x00\x00\x64\x00\x00\x00\x00\x20\x00\x00\x00\x01\x00\x00"
  let symtab = SymtabCmd::parse(@slice.bytes(data), Little)
  assert_eq(symtab.symtab_cmd.symoff, 0x1000_U)
  assert_eq(symtab.symtab_cmd.nsyms, 100_U)
  assert_eq(symtab.symtab_cmd.stroff, 0x2000_U)
  assert_eq(symtab.symtab_cmd.strsize, 256_U)
}

///|
test "SymtabCmd::parse too small" {
  let data : Bytes = "12345678901234567890123" // Only 23 bytes, need 24
  try {
    let _ = SymtabCmd::parse(@slice.bytes(data), Little)
    fail("Expected MissingData error")
  } catch {
    ParseError::MissingData(offset~, expected~) => {
      assert_eq(offset, 0L)
      assert_eq(expected, "SymtabCmd (24 bytes)")
    }
    _ => fail("Expected MissingData error")
  }
}

///|
test "DysymtabCmd::parse/success" {
  // Create minimal 80-byte dysymtab command: cmd + len + ilocalsym(10) + nlocalsym(5) + rest zeros (little endian)
  let data : Bytes = b"\x0b\x00\x00\x00\x50\x00\x00\x00\x0a\x00\x00\x00\x05\x00\x00\x00" +
    Bytes::make(64, b'\x00')
  let dysymtab = DysymtabCmd::parse(@slice.bytes(data), Little)
  assert_eq(dysymtab.ilocalsym, 10_U)
  assert_eq(dysymtab.nlocalsym, 5_U)
}

///|
test "DysymtabCmd::parse/too-small" {
  let data : Bytes = "short"
  try {
    let _ = DysymtabCmd::parse(@slice.bytes(data), Little)
    fail("Expected MissingData error")
  } catch {
    ParseError::MissingData(offset~, expected~) => {
      assert_eq(offset, 0L)
      assert_eq(expected, "DysymtabCmd (80 bytes)")
    }
    _ => fail("Expected MissingData error")
  }
}

///|
test "DylibCmd::parse success" {
  // Create minimal dylib command: cmd + len + name_offset + timestamp + current_ver + compat_ver (little endian)
  let data : Bytes = b"\x0c\x00\x00\x00\x30\x00\x00\x00\x18\x00\x00\x00\x12\x34\x56\x78\x01\x02\x03\x04\x05\x06\x07\x08/usr/lib/libSystem.B.dylib\x00"
  let dylib = DylibCmd::parse(@slice.bytes(data), Little)
  assert_eq(dylib.time, 0x78563412_U)
  assert_eq(dylib.current_version, 0x04030201_U)
  assert_eq(dylib.compat_version, 0x08070605_U)
}

///|
test "DylibCmd::parse too small" {
  let data : Bytes = "short"
  try {
    let _ = DylibCmd::parse(@slice.bytes(data), Little)
    fail("Expected MissingData error")
  } catch {
    ParseError::MissingData(offset~, expected~) => {
      assert_eq(offset, 0L)
      assert_eq(expected, "DylibCmd (24 bytes)")
    }
    _ => fail("Expected MissingData error")
  }
}

///|
test "DylibCmd::parse invalid name offset" {
  let data : Bytes = b"\x0c\x00\x00\x00\x18\x00\x00\x00\x00\x01\x00\x00\x12\x34\x56\x78\x01\x02\x03\x04\x05\x06\x07\x08"
  try {
    let _ = DylibCmd::parse(@slice.bytes(data), Little)
    fail("Expected InvalidOffset error")
  } catch {
    InvalidDataError::InvalidOffset(offset~, max_offset~, context~) => {
      assert_eq(offset, 256)
      assert_eq(max_offset, 24)
      assert_eq(context, "dylib name offset")
    }
    _ => fail("Expected InvalidOffset error")
  }
}

///|
test "RpathCmd::parse/success" {
  let data : Bytes = b"\x1c\x00\x00\x80\x20\x00\x00\x00\x0c\x00\x00\x00/usr/local/lib\x00"
  let rpath = RpathCmd::parse(@slice.bytes(data), Little)
  // The path should be extracted from the data starting at offset 12
  assert_eq(rpath.path.length() > 0, true)
}

///|
test "RpathCmd::parse/too-small" {
  let data : Bytes = "short"
  try {
    let _ = RpathCmd::parse(@slice.bytes(data), Little)
    fail("Expected MissingData error")
  } catch {
    ParseError::MissingData(offset~, expected~) => {
      assert_eq(offset, 0L)
      assert_eq(expected, "RpathCmd (12 bytes)")
    }
    _ => fail("Expected MissingData error")
  }
}

///|
test "RpathCmd::parse/invalid-path-offset" {
  let data : Bytes = b"\x1c\x00\x00\x80\x20\x00\x00\x00\x00\x01\x00\x00"
  try {
    let _ = RpathCmd::parse(@slice.bytes(data), Little)
    fail("Expected InvalidOffset error")
  } catch {
    InvalidDataError::InvalidOffset(offset~, max_offset~, context~) => {
      assert_eq(offset, 256)
      assert_eq(max_offset, 12)
      assert_eq(context, "rpath path offset")
    }
    _ => fail("Expected InvalidOffset error")
  }
}

///|
test "Segment32::parse success" {
  // Create minimal 32-bit segment command (56 bytes): cmd + len + name + vm_addr + vm_size + file_offset + file_size + maxprot + prot + nsect + flags
  let data : Bytes = b"\x01\x00\x00\x00\x38\x00\x00\x00__TEXT\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  let (segment, sections) = Segment32::parse(@slice.bytes(data), Little)
  assert_eq(sections.length(), 0)
  assert_eq(segment.header.cmd, Segment)
  assert_eq(segment.header.len, 56_U)
}

///|
test "Segment32::parse too small" {
  let data : Bytes = "short data" // Only 10 bytes, need 56
  try {
    let _ = Segment32::parse(@slice.bytes(data), Little)
    fail("Expected SegmentTooSmall error")
  } catch {
    ParseError::SegmentTooSmall(offset~, command_type~) => {
      assert_eq(offset, 0L)
      assert_eq(command_type, "Segment32")
    }
    _ => fail("Expected SegmentTooSmall error")
  }
}

///|
test "Segment64::parse success" {
  // Create minimal 64-bit segment command (72 bytes): cmd + len + name + vm_addr + vm_size + file_offset + file_size + maxprot + prot + nsect + flags
  let data : Bytes = b"\x19\x00\x00\x00\x48\x00\x00\x00__TEXT\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  let (segment, sections) = Segment64::parse(@slice.bytes(data), Little)
  assert_eq(sections.length(), 0)
  assert_eq(segment.header.cmd, Segment64)
  assert_eq(segment.header.len, 72_U)
}

///|
test "Segment64::parse too small" {
  let data : Bytes = "short data for segment64" // Only 24 bytes, need 72
  try {
    let _ = Segment64::parse(@slice.bytes(data), Little)
    fail("Expected SegmentTooSmall error")
  } catch {
    ParseError::SegmentTooSmall(offset~, command_type~) => {
      assert_eq(offset, 0L)
      assert_eq(command_type, "Segment64")
    }
    _ => fail("Expected SegmentTooSmall error")
  }
}
