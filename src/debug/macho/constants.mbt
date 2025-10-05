///|
const FileHeaderSize32 : Int = 7 * 4

///|
const FileHeaderSize64 : Int = 8 * 4

///|
pub const Magic32 : UInt = 0xfeedface

///|
pub const Magic64 : UInt = 0xfeedfacf

///|
pub const MagicFat : UInt = 0xcafebabe

///|
const CpuArch64 : UInt = 0x01000000

///|
pub enum Type {
  Object
  Exec
  Dylib
  Bundle
  Unknown(UInt)
} derive(Eq, Show)

///|
pub impl Default for Type with default() {
  Unknown(0)
}

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
pub impl Default for Cpu with default() {
  Unknown(0)
}

///|
pub fn Cpu::from_uint(value : UInt) -> Cpu {
  match value {
    7 => I386
    0x1000007 => Amd64
    12 => Arm
    0x100000c => Arm64
    18 => Ppc
    0x1000012 => Ppc64
    _ => Unknown(value)
  }
}

///|
pub fn Cpu::to_uint(self : Cpu) -> UInt {
  match self {
    I386 => 7
    Amd64 => 7 | CpuArch64
    Arm => 12
    Arm64 => 12 | CpuArch64
    Ppc => 18
    Ppc64 => 18 | CpuArch64
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
pub impl @binary.Readable for LoadCmd with read(
  r : &@io.Reader,
  bo : &@binary.ByteOrder,
) -> LoadCmd {
  LoadCmd::from_uint(@binary.read(r, bo))
}

///|
pub fn LoadCmd::from_uint(value : UInt) -> LoadCmd {
  match value {
    0x1 => Segment
    0x2 => Symtab
    0x4 => Thread
    0x5 => UnixThread
    0xb => Dysymtab
    0xc => Dylib
    0xf => Dylinker
    0x19 => Segment64
    0x8000001c => Rpath
    _ => Unknown(value)
  }
}

///|
pub fn LoadCmd::to_uint(self : LoadCmd) -> UInt {
  match self {
    Segment => 0x1
    Symtab => 0x2
    Thread => 0x4
    UnixThread => 0x5
    Dysymtab => 0xb
    Dylib => 0xc
    Dylinker => 0xf
    Segment64 => 0x19
    Rpath => 0x8000001c
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
pub const FlagNoUndefs : UInt = 0x1

///|
pub const FlagIncrLink : UInt = 0x2

///|
pub const FlagDyldLink : UInt = 0x4

///|
pub const FlagBindAtLoad : UInt = 0x8

///|
pub const FlagPrebound : UInt = 0x10

///|
pub const FlagSplitSegs : UInt = 0x20

///|
pub const FlagLazyInit : UInt = 0x40

///|
pub const FlagTwoLevel : UInt = 0x80

///|
pub const FlagForceFlat : UInt = 0x100

///|
pub const FlagNoMultiDefs : UInt = 0x200

///|
pub const FlagNoFixPrebinding : UInt = 0x400

///|
pub const FlagPrebindable : UInt = 0x800

///|
pub const FlagAllModsBound : UInt = 0x1000

///|
pub const FlagSubsectionsViaSymbols : UInt = 0x2000

///|
pub const FlagCanonical : UInt = 0x4000

///|
pub const FlagWeakDefines : UInt = 0x8000

///|
pub const FlagBindsToWeak : UInt = 0x10000

///|
pub const FlagAllowStackExecution : UInt = 0x20000

///|
pub const FlagRootSafe : UInt = 0x40000

///|
pub const FlagSetuidSafe : UInt = 0x80000

///|
pub const FlagNoReexportedDylibs : UInt = 0x100000

///|
pub const FlagPIE : UInt = 0x200000

///|
pub const FlagDeadStrippableDylib : UInt = 0x400000

///|
pub const FlagHasTLVDescriptors : UInt = 0x800000

///|
pub const FlagNoHeapExecution : UInt = 0x1000000

///|
pub const FlagAppExtensionSafe : UInt = 0x2000000
