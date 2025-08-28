///|
pub let file_header_size_32 : Int = 7 * 4

///|
pub let file_header_size_64 : Int = 8 * 4

///|
pub let magic_32 : UInt = 0xfeedface_U

///|
pub let magic_64 : UInt = 0xfeedfacf_U

///|
pub let magic_fat : UInt = 0xcafebabe_U

///|
let cpu_arch_64 : UInt = 0x01000000_U

///|
pub enum Type {
  Object
  Exec
  Dylib
  Bundle
  Unknown(UInt)
} derive(Eq, Show)

///|
pub fn Type::from_uint(value : UInt) -> Type {
  match value {
    1_U => Object
    2_U => Exec
    6_U => Dylib
    8_U => Bundle
    _ => Unknown(value)
  }
}

///|
pub fn Type::to_uint(self : Type) -> UInt {
  match self {
    Object => 1_U
    Exec => 2_U
    Dylib => 6_U
    Bundle => 8_U
    Unknown(val) => val
  }
}

///|
pub fn Type::to_string(self : Type) -> String {
  match self {
    Object => "Object"
    Exec => "Executable"
    Dylib => "Dynamic Library"
    Bundle => "Bundle"
    Unknown(val) => "Unknown(" + val.to_string() + ")"
  }
}

///|
pub enum Cpu {
  I386
  Amd64
  Arm
  Arm64
  Ppc
  Ppc64
  Unknown(UInt)
} derive(Eq, Show)

///|
pub fn Cpu::from_uint(value : UInt) -> Cpu {
  match value {
    7_U => I386
    0x1000007_U => Amd64
    12_U => Arm
    0x100000c_U => Arm64
    18_U => Ppc
    0x1000012_U => Ppc64
    _ => Unknown(value)
  }
}

///|
pub fn Cpu::to_uint(self : Cpu) -> UInt {
  match self {
    I386 => 7_U
    Amd64 => 7_U | cpu_arch_64
    Arm => 12_U
    Arm64 => 12_U | cpu_arch_64
    Ppc => 18_U
    Ppc64 => 18_U | cpu_arch_64
    Unknown(val) => val
  }
}

///|
pub fn Cpu::to_string(self : Cpu) -> String {
  match self {
    I386 => "i386"
    Amd64 => "x86_64"
    Arm => "arm"
    Arm64 => "arm64"
    Ppc => "ppc"
    Ppc64 => "ppc64"
    Unknown(val) => "unknown(" + val.to_string() + ")"
  }
}

///|
pub enum LoadCmd {
  Segment
  Symtab
  Thread
  UnixThread
  Dysymtab
  Dylib
  Dylinker
  Segment64
  Rpath
  Unknown(UInt)
} derive(Eq, Show)

///|
pub fn LoadCmd::from_uint(value : UInt) -> LoadCmd {
  match value {
    0x1_U => Segment
    0x2_U => Symtab
    0x4_U => Thread
    0x5_U => UnixThread
    0xb_U => Dysymtab
    0xc_U => Dylib
    0xf_U => Dylinker
    0x19_U => Segment64
    0x8000001c_U => Rpath
    _ => Unknown(value)
  }
}

///|
pub fn LoadCmd::to_uint(self : LoadCmd) -> UInt {
  match self {
    Segment => 0x1_U
    Symtab => 0x2_U
    Thread => 0x4_U
    UnixThread => 0x5_U
    Dysymtab => 0xb_U
    Dylib => 0xc_U
    Dylinker => 0xf_U
    Segment64 => 0x19_U
    Rpath => 0x8000001c_U
    Unknown(val) => val
  }
}

///|
pub fn LoadCmd::to_string(self : LoadCmd) -> String {
  match self {
    Segment => "Segment"
    Symtab => "Symtab"
    Thread => "Thread"
    UnixThread => "UnixThread"
    Dysymtab => "Dysymtab"
    Dylib => "Dylib"
    Dylinker => "Dylinker"
    Segment64 => "Segment64"
    Rpath => "Rpath"
    Unknown(val) => "Unknown(" + val.to_string() + ")"
  }
}

///|
pub let flag_no_undefs : UInt = 0x1_U

///|
pub let flag_incr_link : UInt = 0x2_U

///|
pub let flag_dyld_link : UInt = 0x4_U

///|
pub let flag_bind_at_load : UInt = 0x8_U

///|
pub let flag_prebound : UInt = 0x10_U

///|
pub let flag_split_segs : UInt = 0x20_U

///|
pub let flag_lazy_init : UInt = 0x40_U

///|
pub let flag_two_level : UInt = 0x80_U

///|
pub let flag_force_flat : UInt = 0x100_U

///|
pub let flag_no_multi_defs : UInt = 0x200_U

///|
pub let flag_no_fix_prebinding : UInt = 0x400_U

///|
pub let flag_prebindable : UInt = 0x800_U

///|
pub let flag_all_mods_bound : UInt = 0x1000_U

///|
pub let flag_subsections_via_symbols : UInt = 0x2000_U

///|
pub let flag_canonical : UInt = 0x4000_U

///|
pub let flag_weak_defines : UInt = 0x8000_U

///|
pub let flag_binds_to_weak : UInt = 0x10000_U

///|
pub let flag_allow_stack_execution : UInt = 0x20000_U

///|
pub let flag_root_safe : UInt = 0x40000_U

///|
pub let flag_setuid_safe : UInt = 0x80000_U

///|
pub let flag_no_reexported_dylibs : UInt = 0x100000_U

///|
pub let flag_pie : UInt = 0x200000_U

///|
pub let flag_dead_strippable_dylib : UInt = 0x400000_U

///|
pub let flag_has_tlv_descriptors : UInt = 0x800000_U

///|
pub let flag_no_heap_execution : UInt = 0x1000000_U

///|
pub let flag_app_extension_safe : UInt = 0x2000000_U
