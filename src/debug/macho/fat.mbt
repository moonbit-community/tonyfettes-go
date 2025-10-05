///|
pub struct FatHeader {
  magic : UInt
  nfat_arch : UInt
} derive(Eq, Show)

///|
pub struct FatArch {
  cpu : Cpu
  sub_cpu : UInt
  offset : UInt
  size : UInt
  align : UInt
} derive(Eq, Show)

///|
pub struct FatFile {
  magic : UInt
  arches : Array[FatArch]
  files : Array[File]
}

///|
pub let fat_header_size : Int = 2 * 4

///|
pub let fat_arch_size : Int = 5 * 4

///|
fn is_fat(magic : UInt) -> Bool {
  magic == MagicFat || magic == 0xbebafeca_U // swapped fat magic
}

///|
fn FatHeader::parse(data : @slice.Slice[Byte], offset : Int) -> FatHeader raise {
  if data.length() < offset + fat_header_size {
    raise FileTooSmall(
      actual_size=data.length(),
      required_size=offset + fat_header_size,
    )
  }
  let magic = read_uint(data, offset, Big)
  let nfat_arch = read_uint(data, offset + 4, Big)
  if not(is_fat(magic)) {
    raise InvalidMagic(magic~)
  }
  { magic, nfat_arch }
}

///|
fn FatArch::parse(data : @slice.Slice[Byte], offset : Int) -> FatArch raise {
  if data.length() < offset + fat_arch_size {
    raise FileTooSmall(
      actual_size=data.length(),
      required_size=offset + fat_arch_size,
    )
  }
  let cpu_raw = read_uint(data, offset, Big)
  let sub_cpu = read_uint(data, offset + 4, Big)
  let file_offset = read_uint(data, offset + 8, Big)
  let size = read_uint(data, offset + 12, Big)
  let align = read_uint(data, offset + 16, Big)
  let cpu = Cpu::from_uint(cpu_raw)
  { cpu, sub_cpu, offset: file_offset, size, align }
}

///|
pub fn FatFile::new(data : @slice.Slice[Byte]) -> FatFile raise {
  let header = FatHeader::parse(data, 0)
  let arches : Array[FatArch] = []
  let files : Array[File] = []

  // Parse each fat architecture
  for i = 0; i < header.nfat_arch.reinterpret_as_int(); i = i + 1 {
    let arch_offset = fat_header_size + i * fat_arch_size
    let arch = FatArch::parse(data, arch_offset)
    arches.push(arch)

    // Extract and parse the Mach-O file for this architecture
    let file_start = arch.offset.reinterpret_as_int()
    let file_size = arch.size.reinterpret_as_int()
    if data.length() < file_start + file_size {
      raise FileTooSmall(
        actual_size=data.length(),
        required_size=file_start + file_size,
      )
    }
    let file_data = read_bytes(data, file_start, file_size)
    files.push(File::parse(file_data))
  }
  { magic: header.magic, arches, files }
}
