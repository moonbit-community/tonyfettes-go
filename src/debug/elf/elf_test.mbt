///|
/// Basic test for ELF constants and types
test "elf constants" {
  // Test Version enum
  @json.inspect(Version::EV_CURRENT.to_int(), content=1)
  @json.inspect(Version::from_int(1), content="EV_CURRENT")

  // Test Class enum
  @json.inspect(Class::ELFCLASS64.to_int(), content=2)
  @json.inspect(Class::from_int(2), content="ELFCLASS64")

  // Test Data enum
  @json.inspect(Data::ELFDATA2LSB.to_int(), content=1)
  @json.inspect(Data::from_int(1), content="ELFDATA2LSB")

  // Test Machine enum
  @json.inspect(Machine::EM_X86_64.to_int(), content=62)
  @json.inspect(Machine::from_int(62), content="EM_X86_64")

  // Test Type enum
  @json.inspect(Type::ET_EXEC.to_int(), content=2)
  @json.inspect(Type::from_int(2), content="ET_EXEC")
}

///|
test "version index operations" {
  let vi = VersionIndex::new(0x8001U)
  @json.inspect(vi.is_hidden(), content=true)
  @json.inspect(vi.index(), content=1)
  let vi2 = VersionIndex::new(0x1U)
  @json.inspect(vi2.is_hidden(), content=false)
  @json.inspect(vi2.index(), content=1)
}

///|
test "magic constant" {
  @json.inspect(ELFMAG, content="ELF")
}

///|
test "section types" {
  @json.inspect(SectionType::SHT_PROGBITS.to_int(), content=1)
  @json.inspect(SectionType::from_int(1), content={ "$tag": "SHT_PROGBITS" })
  @json.inspect(SectionType::SHT_SYMTAB.to_int(), content=2)
  @json.inspect(SectionType::from_int(2), content={ "$tag": "SHT_SYMTAB" })
}

///|
test "program types" {
  @json.inspect(ProgType::PT_LOAD.to_int(), content=1)
  @json.inspect(ProgType::from_int(1), content={ "$tag": "PT_LOAD" })
  @json.inspect(ProgType::PT_DYNAMIC.to_int(), content=2)
  @json.inspect(ProgType::from_int(2), content={ "$tag": "PT_DYNAMIC" })
}

///|
test "compression types" {
  @json.inspect(CompressionType::COMPRESS_ZLIB.to_int(), content=1)
  @json.inspect(CompressionType::from_int(1), content={
    "$tag": "COMPRESS_ZLIB",
  })
  @json.inspect(CompressionType::COMPRESS_ZSTD.to_int(), content=2)
  @json.inspect(CompressionType::from_int(2), content={
    "$tag": "COMPRESS_ZSTD",
  })
}
