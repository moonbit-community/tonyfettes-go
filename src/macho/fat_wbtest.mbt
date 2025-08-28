///|
test "is_fat true cases" {
  assert_true(is_fat(magic_fat))
  assert_true(is_fat(0xbebafeca_U)) // swapped fat magic
}

///|
test "is_fat false cases" {
  assert_false(is_fat(magic_32))
  assert_false(is_fat(magic_64))
  assert_false(is_fat(0x12345678_U))
}

///|
test "parse_fat_header success" {
  // Create minimal fat header: magic + nfat_arch
  let data : Bytes = b"\xca\xfe\xba\xbe\x00\x00\x00\x02"
  let header = parse_fat_header(data, 0)
  assert_eq(header.magic, 0xcafebabe_U)
  assert_eq(header.nfat_arch, 2_U)
}

///|
test "parse_fat_header file too small" {
  let data : Bytes = "123" // Only 3 bytes
  try {
    let _ = parse_fat_header(data, 0)
    fail("Expected FileTooSmall error")
  } catch {
    FileTooSmall(actual_size~, required_size~) => {
      assert_eq(actual_size, 3)
      assert_eq(required_size, 8)
    }
    _ => fail("Expected FileTooSmall error")
  }
}

///|
test "parse_fat_header invalid magic" {
  let data : Bytes = b"\x12\x34\x56\x78\x00\x00\x00\x02"
  try {
    let _ = parse_fat_header(data, 0)
    fail("Expected InvalidMagic error")
  } catch {
    InvalidMagic(magic~) => assert_eq(magic, 0x12345678_U)
    _ => fail("Expected InvalidMagic error")
  }
}

///|
test "parse_fat_arch success" {
  // Create minimal fat arch: cpu_type + sub_cpu + offset + size + align
  let data : Bytes = b"\x00\x00\x00\x07\x00\x00\x00\x03\x00\x00\x10\x00\x00\x00\x20\x00\x00\x00\x00\x0c"
  let arch = parse_fat_arch(data, 0)
  assert_eq(arch.cpu, I386)
  assert_eq(arch.sub_cpu, 3_U)
  assert_eq(arch.offset, 0x1000_U)
  assert_eq(arch.size, 0x2000_U)
  assert_eq(arch.align, 12_U)
}

///|
test "parse_fat_arch file too small" {
  let data : Bytes = "123456789012345" // Only 15 bytes, need 20
  try {
    let _ = parse_fat_arch(data, 0)
    fail("Expected FileTooSmall error")
  } catch {
    FileTooSmall(actual_size~, required_size~) => {
      assert_eq(actual_size, 15)
      assert_eq(required_size, 20)
    }
    _ => fail("Expected FileTooSmall error")
  }
}

///|
test "get_arch_file found" {
  let test_file : File = {
    header: {
      magic: magic_32,
      cpu: I386,
      sub_cpu: 0_U,
      type_: Object,
      ncmd: 0_U,
      cmdsz: 0_U,
      flags: 0_U,
    },
    byte_order: Little,
    loads: [],
    sections: [],
    symtab: None,
    dysymtab: None,
  }
  let fat_file : FatFile = {
    magic: magic_fat,
    arches: [{ cpu: I386, sub_cpu: 0_U, offset: 0_U, size: 100_U, align: 12_U }],
    files: [test_file],
  }
  match get_arch_file(fat_file, I386) {
    Some(file) => assert_eq(file.header.cpu, I386)
    None => fail("Expected to find I386 architecture")
  }
}

///|
test "get_arch_file not found" {
  let fat_file : FatFile = {
    magic: magic_fat,
    arches: [{ cpu: I386, sub_cpu: 0_U, offset: 0_U, size: 100_U, align: 12_U }],
    files: [],
  }
  match get_arch_file(fat_file, Arm64) {
    Some(_) => fail("Should not find Arm64 architecture")
    None => () // Expected
  }
}

///|
test "parse_fat_file complete with valid data" {
  // Create a complete fat file with header + arch + embedded mach-o files
  let fat_header : Bytes = b"\xca\xfe\xba\xbe\x00\x00\x00\x01" // magic + 1 arch
  let fat_arch : Bytes = b"\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x20\x00\x00\x00\x0c" // i386 arch at offset 28, size 32
  // Embedded Mach-O file (minimal 32-bit header, 32 bytes)
  let macho_data : Bytes = b"\xce\xfa\xed\xfe\x07\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  let complete_data = fat_header + fat_arch + macho_data
  let fat_file = parse_fat_file(complete_data)
  assert_eq(fat_file.arches.length(), 1)
  assert_eq(fat_file.files.length(), 1)
  assert_eq(fat_file.arches[0].cpu, I386)
  assert_eq(fat_file.files[0].header.cpu, I386)
}

///|
test "parse_fat_file file too small for embedded macho" {
  // Create fat file where embedded file would exceed bounds
  let fat_header : Bytes = b"\xca\xfe\xba\xbe\x00\x00\x00\x01" // magic + 1 arch
  let fat_arch : Bytes = b"\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x01\x00\x00\x00\x00\x0c" // i386 arch at offset 28, size 256 (too big)
  let short_data = fat_header + fat_arch + b"short"
  try {
    let _ = parse_fat_file(short_data)
    fail("Expected FileTooSmall error")
  } catch {
    FileTooSmall(actual_size~, required_size~) => {
      assert_eq(actual_size, 33) // 8 + 20 + 5 bytes  
      assert_eq(required_size, 284) // 28 + 256 bytes
    }
    _ => fail("Expected FileTooSmall error")
  }
}
