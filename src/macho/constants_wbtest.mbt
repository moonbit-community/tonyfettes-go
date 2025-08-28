///|
test "magic number constants" {
  assert_eq(Magic32, 4277009102_U)
  assert_eq(Magic64, 4277009103_U)
  assert_eq(MagicFat, 3405691582_U)
}

///|
test "file header sizes" {
  assert_eq(file_header_size_32, 28)
  assert_eq(file_header_size_64, 32)
}

///|
test "Type enum conversions" {
  assert_eq(Type::Object.to_uint(), 1_U)
  assert_eq(Type::Exec.to_uint(), 2_U)
  assert_eq(Type::Dylib.to_uint(), 6_U)
  assert_eq(Type::Bundle.to_uint(), 8_U)
  assert_eq(Type::from_uint(1_U), Object)
  assert_eq(Type::from_uint(2_U), Exec)
  assert_eq(Type::from_uint(6_U), Dylib)
  assert_eq(Type::from_uint(8_U), Bundle)
  assert_eq(Type::from_uint(99_U), Unknown(99_U))
}

///|
test "Cpu enum conversions" {
  assert_eq(Cpu::I386.to_uint(), 7_U)
  assert_eq(Cpu::Amd64.to_uint(), 16777223_U)
  assert_eq(Cpu::Arm.to_uint(), 12_U)
  assert_eq(Cpu::Arm64.to_uint(), 16777228_U)
  assert_eq(Cpu::from_uint(7_U), I386)
  assert_eq(Cpu::from_uint(16777223_U), Amd64)
  assert_eq(Cpu::from_uint(12_U), Arm)
  assert_eq(Cpu::from_uint(16777228_U), Arm64)
  assert_eq(Cpu::from_uint(99_U), Unknown(99_U))
}

///|
test "LoadCmd enum conversions" {
  assert_eq(LoadCmd::Segment.to_uint(), 1_U)
  assert_eq(LoadCmd::Symtab.to_uint(), 2_U)
  assert_eq(LoadCmd::Thread.to_uint(), 4_U)
  assert_eq(LoadCmd::UnixThread.to_uint(), 5_U)
  assert_eq(LoadCmd::Dysymtab.to_uint(), 11_U)
  assert_eq(LoadCmd::Dylib.to_uint(), 12_U)
  assert_eq(LoadCmd::Dylinker.to_uint(), 15_U)
  assert_eq(LoadCmd::Segment64.to_uint(), 25_U)
  assert_eq(LoadCmd::Rpath.to_uint(), 2147483676_U)
  assert_eq(LoadCmd::from_uint(1_U), Segment)
  assert_eq(LoadCmd::from_uint(2_U), Symtab)
  assert_eq(LoadCmd::from_uint(4_U), Thread)
  assert_eq(LoadCmd::from_uint(5_U), UnixThread)
  assert_eq(LoadCmd::from_uint(11_U), Dysymtab)
  assert_eq(LoadCmd::from_uint(12_U), Dylib)
  assert_eq(LoadCmd::from_uint(15_U), Dylinker)
  assert_eq(LoadCmd::from_uint(25_U), Segment64)
  assert_eq(LoadCmd::from_uint(2147483676_U), Rpath)
  assert_eq(LoadCmd::from_uint(999_U), Unknown(999_U))
}

///|
test "Type Unknown variant to_uint" {
  let unknown_type = Type::Unknown(42_U)
  assert_eq(unknown_type.to_uint(), 42_U)
}

///|
test "Cpu PowerPC variants" {
  assert_eq(Cpu::from_uint(18_U), Ppc)
  assert_eq(Cpu::from_uint(0x1000012_U), Ppc64) // 18_U | cpu_arch_64 = 0x1000012
  assert_eq(Cpu::Ppc.to_uint(), 18_U)
  assert_eq(Cpu::Ppc64.to_uint(), 0x1000012_U)
}

///|
test "Cpu Unknown variant to_uint" {
  let unknown_cpu = Cpu::Unknown(123_U)
  assert_eq(unknown_cpu.to_uint(), 123_U)
}

///|
test "LoadCmd Unknown variant to_uint" {
  let unknown_cmd = LoadCmd::Unknown(456_U)
  assert_eq(unknown_cmd.to_uint(), 456_U)
}
