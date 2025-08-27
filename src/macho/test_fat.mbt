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
test "is_universal_binary true" {
  let data : Bytes = b"\xca\xfe\xba\xbe\x00\x00\x00\x01rest of data"
  assert_true(is_universal_binary(data))
}

///|
test "is_universal_binary false - too small" {
  let data : Bytes = "123"
  assert_false(is_universal_binary(data))
}

///|
test "is_universal_binary false - wrong magic" {
  let data : Bytes = b"\x12\x34\x56\x78rest"
  assert_false(is_universal_binary(data))
}

///|
test "get_arch_count" {
  let fat_file : FatFile = {
    magic: magic_fat,
    arches: [{ cpu: I386, sub_cpu: 0_U, offset: 0_U, size: 100_U, align: 12_U }],
    files: [],
  }
  assert_eq(get_arch_count(fat_file), 1)
}

///|
test "get_supported_architectures" {
  let arches = [
    { cpu: I386, sub_cpu: 0_U, offset: 0_U, size: 100_U, align: 12_U },
    { cpu: Arm64, sub_cpu: 0_U, offset: 1000_U, size: 200_U, align: 14_U },
  ]
  let fat_file : FatFile = { magic: magic_fat, arches, files: [] }
  let cpus = get_supported_architectures(fat_file)
  assert_eq(cpus.length(), 2)
  assert_eq(cpus[0], I386)
  assert_eq(cpus[1], Arm64)
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
