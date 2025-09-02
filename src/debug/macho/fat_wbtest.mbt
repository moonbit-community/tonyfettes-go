///|
test "is_fat true cases" {
  assert_true(is_fat(MagicFat))
  assert_true(is_fat(0xbebafeca)) // swapped fat magic
}

///|
test "is_fat false cases" {
  assert_false(is_fat(Magic32))
  assert_false(is_fat(Magic64))
  assert_false(is_fat(0x12345678))
}

///|
test "FatHeader::parse/success" {
  // Create minimal fat header: magic + nfat_arch
  let data = @slice.bytes(b"\xca\xfe\xba\xbe\x00\x00\x00\x02")
  let header = FatHeader::parse(data, 0)
  assert_eq(header.magic, 0xcafebabe)
  assert_eq(header.nfat_arch, 2)
}

///|
test "FatHeader::parse/file-too-small" {
  let data = @slice.bytes("123") // Only 3 bytes
  try {
    let _ = FatHeader::parse(data, 0)
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
test "FatHeader::parse/invalid-magic" {
  let data = @slice.bytes(b"\x12\x34\x56\x78\x00\x00\x00\x02")
  try {
    let _ = FatHeader::parse(data, 0)
    fail("Expected InvalidMagic error")
  } catch {
    InvalidMagic(magic~) => assert_eq(magic, 0x12345678_U)
    _ => fail("Expected InvalidMagic error")
  }
}

///|
test "FatArch::parse/success" {
  // Create minimal fat arch: cpu_type + sub_cpu + offset + size + align
  let data = @slice.bytes(
    b"\x00\x00\x00\x07\x00\x00\x00\x03\x00\x00\x10\x00\x00\x00\x20\x00\x00\x00\x00\x0c",
  )
  let arch = FatArch::parse(data, 0)
  assert_eq(arch.cpu, I386)
  assert_eq(arch.sub_cpu, 3_U)
  assert_eq(arch.offset, 0x1000_U)
  assert_eq(arch.size, 0x2000_U)
  assert_eq(arch.align, 12_U)
}

///|
test "FatArch::parse/file-too-small" {
  let data = @slice.bytes("123456789012345") // Only 15 bytes, need 20
  try {
    let _ = FatArch::parse(data, 0)
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
test "FatFile::new/complete-with-valid-data" {
  // Create a complete fat file with header + arch + embedded mach-o files
  let fat_header = b"\xca\xfe\xba\xbe\x00\x00\x00\x01" // magic + 1 arch
  let fat_arch = b"\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x20\x00\x00\x00\x0c" // i386 arch at offset 28, size 32)
  // Embedded Mach-O file (minimal 32-bit header, 32 bytes)
  let macho_data = b"\xce\xfa\xed\xfe\x07\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  let complete_data = fat_header + fat_arch + macho_data
  let fat_file = FatFile::new(@slice.bytes(complete_data))
  assert_eq(fat_file.arches.length(), 1)
  assert_eq(fat_file.files.length(), 1)
  assert_eq(fat_file.arches[0].cpu, I386)
  assert_eq(fat_file.files[0].header.cpu, I386)
}

///|
test "FatFile::new/file-too-small-for-embedded macho" {
  // Create fat file where embedded file would exceed bounds
  let fat_header = b"\xca\xfe\xba\xbe\x00\x00\x00\x01" // magic + 1 arch)
  let fat_arch = b"\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x01\x00\x00\x00\x00\x0c" // i386 arch at offset 28, size 256 (too big))
  let short_data = fat_header + fat_arch + b"short"
  try {
    let _ = FatFile::new(@slice.bytes(short_data))
    fail("Expected FileTooSmall error")
  } catch {
    FileTooSmall(actual_size~, required_size~) => {
      assert_eq(actual_size, 33) // 8 + 20 + 5 bytes
      assert_eq(required_size, 284) // 28 + 256 bytes
    }
    _ => fail("Expected FileTooSmall error")
  }
}
