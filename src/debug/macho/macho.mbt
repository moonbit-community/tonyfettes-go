// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Mach-O header data structures
// Originally at:
// http://developer.apple.com/mac/library/documentation/DeveloperTools/Conceptual/MachORuntime/Reference/reference.html (since deleted by Apple)
// Archived copy at:
// https://web.archive.org/web/20090819232456/http://developer.apple.com/documentation/DeveloperTools/Conceptual/MachORuntime/index.html
// For cloned PDF see:
// https://github.com/aidansteele/osx-abi-macho-file-format-reference

///|
/// A `FileHeader` represents a Mach-O file header.
pub struct FileHeader {
  magic : UInt
  cpu : Cpu
  sub_cpu : UInt
  type_ : Type
  ncmd : UInt
  cmdsz : UInt
  flags : UInt
} derive(Eq, Show, Default)

///|
pub impl @binary.Readable for FileHeader with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> FileHeader raise {
  FileHeader::{
    cpu: Cpu::from_uint(@binary.read(r, byte_order)),
    sub_cpu: @binary.read(r, byte_order),
    type_: Type::from_uint(@binary.read(r, byte_order)),
    ncmd: @binary.read(r, byte_order),
    cmdsz: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    magic: @binary.read(r, byte_order),
  }
}

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
// A Type is the Mach-O file type, e.g. an object file, executable, or dynamic library.
pub enum Type {
  Obj
  Exec
  Dylib
  Bundle
  Type(UInt)
} derive(Eq, Show)

///|
pub impl Default for Type with default() {
  Type(0)
}

///|
pub fn Type::from_uint(value : UInt) -> Type {
  match value {
    1 => Obj
    2 => Exec
    6 => Dylib
    8 => Bundle
    _ => Type(value)
  }
}

///|
pub fn Type::to_uint(self : Type) -> UInt {
  match self {
    Obj => 1
    Exec => 2
    Dylib => 6
    Bundle => 8
    Type(val) => val
  }
}

///|
pub fn Type::to_string(self : Type) -> String {
  match self {
    Obj => "Obj"
    Exec => "Exec"
    Dylib => "Dylib"
    Bundle => "Bundle"
    Type(val) => "Type(" + val.to_string() + ")"
  }
}

///|
const CpuArch64 : UInt = 0x01000000

///|
pub enum Cpu {
  I386
  Amd64
  Arm
  Arm64
  Ppc
  Ppc64
  Cpu(UInt)
} derive(Eq, Show)

///|
pub impl @builtin.ToUInt64 for Cpu with to_uint64(self : Cpu) -> UInt64 {
  self.to_uint().to_uint64()
}

///|
pub impl Default for Cpu with default() {
  Cpu(0)
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
    _ => Cpu(value)
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
    Cpu(val) => val
  }
}

///|
pub fn Cpu::to_string(self : Cpu) -> String {
  match self {
    I386 => "Cpu386"
    Amd64 => "CpuAmd64"
    Arm => "CpuArm"
    Arm64 => "CpuArm64"
    Ppc => "CpuPpc"
    Ppc64 => "CpuPpc64"
    Cpu(val) => "Cpu(\{val})"
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
  LoadCmd(UInt)
} derive(Eq, Show)

///|
pub impl @binary.Readable for LoadCmd with read(
  r : &@io.Reader,
  bo : @binary.ByteOrder,
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
    _ => LoadCmd(value)
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
    LoadCmd(val) => val
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
    LoadCmd(val) => "LoadCmd(\{val})"
  }
}

///|
pub struct Segment32 {
  cmd : LoadCmd
  len : UInt
  name : FixedArray[Byte]
  addr : UInt
  memsz : UInt
  offset : UInt
  filesz : UInt
  maxprot : UInt
  prot : UInt
  nsect : UInt
  flag : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for Segment32 with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> Segment32 {
  Segment32::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    name: @binary.read_n(r, order, 16),
    addr: @binary.read(r, order),
    memsz: @binary.read(r, order),
    offset: @binary.read(r, order),
    filesz: @binary.read(r, order),
    maxprot: @binary.read(r, order),
    prot: @binary.read(r, order),
    nsect: @binary.read(r, order),
    flag: @binary.read(r, order),
  }
}

///|
pub struct Segment64 {
  cmd : LoadCmd
  len : UInt
  name : FixedArray[Byte]
  addr : UInt64
  memsz : UInt64
  offset : UInt64
  filesz : UInt64
  maxprot : UInt
  prot : UInt
  nsect : UInt
  flag : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for Segment64 with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> Segment64 raise {
  Segment64::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    name: @binary.read_n(r, order, 16),
    addr: @binary.read(r, order),
    memsz: @binary.read(r, order),
    offset: @binary.read(r, order),
    filesz: @binary.read(r, order),
    maxprot: @binary.read(r, order),
    prot: @binary.read(r, order),
    nsect: @binary.read(r, order),
    flag: @binary.read(r, order),
  }
}

///|
pub struct SymtabCmd {
  cmd : LoadCmd
  len : UInt
  symoff : UInt
  nsyms : UInt
  stroff : UInt
  strsize : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for SymtabCmd with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> SymtabCmd raise {
  SymtabCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    symoff: @binary.read(r, byte_order),
    nsyms: @binary.read(r, byte_order),
    stroff: @binary.read(r, byte_order),
    strsize: @binary.read(r, byte_order),
  }
}

///|
pub struct DysymtabCmd {
  cmd : LoadCmd
  len : UInt
  ilocalsym : UInt
  nlocalsym : UInt
  iextdefsym : UInt
  nextdefsym : UInt
  iundefsym : UInt
  nundefsym : UInt
  tocoffset : UInt
  ntoc : UInt
  modtaboff : UInt
  nmodtab : UInt
  extrefsymoff : UInt
  nextrefsyms : UInt
  indirectsymoff : UInt
  nindirectsyms : UInt
  extreloff : UInt
  nextrel : UInt
  locreloff : UInt
  nlocrel : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for DysymtabCmd with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> DysymtabCmd {
  DysymtabCmd::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    ilocalsym: @binary.read(r, order),
    nlocalsym: @binary.read(r, order),
    iextdefsym: @binary.read(r, order),
    nextdefsym: @binary.read(r, order),
    iundefsym: @binary.read(r, order),
    nundefsym: @binary.read(r, order),
    tocoffset: @binary.read(r, order),
    ntoc: @binary.read(r, order),
    modtaboff: @binary.read(r, order),
    nmodtab: @binary.read(r, order),
    extrefsymoff: @binary.read(r, order),
    nextrefsyms: @binary.read(r, order),
    indirectsymoff: @binary.read(r, order),
    nindirectsyms: @binary.read(r, order),
    extreloff: @binary.read(r, order),
    nextrel: @binary.read(r, order),
    locreloff: @binary.read(r, order),
    nlocrel: @binary.read(r, order),
  }
}

///|
pub struct DylibCmd {
  cmd : UInt
  len : UInt
  name : UInt
  time : UInt
  current_version : UInt
  compat_version : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for DylibCmd with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> DylibCmd raise {
  DylibCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    name: @binary.read(r, byte_order),
    time: @binary.read(r, byte_order),
    current_version: @binary.read(r, byte_order),
    compat_version: @binary.read(r, byte_order),
  }
}

///|
struct RpathCmd {
  cmd : UInt
  len : UInt
  path : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for RpathCmd with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> RpathCmd raise {
  RpathCmd::{
    cmd: @binary.read(r, byte_order),
    len: @binary.read(r, byte_order),
    path: @binary.read(r, byte_order),
  }
}

///|
pub struct Thread {
  cmd : LoadCmd
  len : UInt
  type_ : UInt
  data : Array[UInt]
}

///|
pub impl @binary.Readable for Thread with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> Thread raise {
  Thread::{
    cmd: @binary.read(r, order),
    len: @binary.read(r, order),
    type_: @binary.read(r, order),
    data: {
      let n : UInt = @binary.read(r, order)
      let data = []
      for i in 0U..<n {
        data.push(@binary.read(r, order))
      }
      data
    },
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

///|
// A `Section32` is a 32-bit Mach-O section header.
pub struct Section32 {
  name : FixedArray[Byte]
  seg : FixedArray[Byte]
  addr : UInt
  size : UInt
  offset : UInt
  align : UInt
  reloff : UInt
  nreloc : UInt
  flags : UInt
  reserve1 : UInt
  reserve2 : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for Section32 with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> Section32 raise {
  Section32::{
    name: @binary.read_n(r, byte_order, 16),
    seg: @binary.read_n(r, byte_order, 16),
    addr: @binary.read(r, byte_order),
    size: @binary.read(r, byte_order),
    offset: @binary.read(r, byte_order),
    align: @binary.read(r, byte_order),
    reloff: @binary.read(r, byte_order),
    nreloc: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    reserve1: @binary.read(r, byte_order),
    reserve2: @binary.read(r, byte_order),
  }
}

///|
// A `Section64` is a 64-bit Mach-O section header.
pub struct Section64 {
  name : FixedArray[Byte]
  seg : FixedArray[Byte]
  addr : UInt64
  size : UInt64
  offset : UInt
  align : UInt
  reloff : UInt
  nreloc : UInt
  flags : UInt
  reserve1 : UInt
  reserve2 : UInt
  reserve3 : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for Section64 with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> Section64 raise {
  Section64::{
    name: @binary.read_n(r, byte_order, 16),
    seg: @binary.read_n(r, byte_order, 16),
    addr: @binary.read(r, byte_order),
    size: @binary.read(r, byte_order),
    offset: @binary.read(r, byte_order),
    align: @binary.read(r, byte_order),
    reloff: @binary.read(r, byte_order),
    nreloc: @binary.read(r, byte_order),
    flags: @binary.read(r, byte_order),
    reserve1: @binary.read(r, byte_order),
    reserve2: @binary.read(r, byte_order),
    reserve3: @binary.read(r, byte_order),
  }
}

///|
// An `Nlist32` is a Mach-O 32-bit symbol table entry.
struct Nlist32 {
  name : UInt
  type_ : Byte
  sect : Byte
  desc : UInt16
  value : UInt
} derive(Eq, Show)

///|
pub impl @binary.Readable for Nlist32 with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> Nlist32 raise {
  Nlist32::{
    name: @binary.read(r, byte_order),
    type_: @binary.read(r, byte_order),
    sect: @binary.read(r, byte_order),
    desc: @binary.read(r, byte_order),
    value: @binary.read(r, byte_order),
  }
}

///|
// An `Nlist64` is a Mach-O 64-bit symbol table entry.
pub struct Nlist64 {
  name : UInt
  type_ : Byte
  sect : Byte
  desc : UInt16
  value : UInt64
} derive(Eq, Show)

///|
pub impl @binary.Readable for Nlist64 with read(
  r : &@io.Reader,
  byte_order : @binary.ByteOrder,
) -> Nlist64 raise {
  Nlist64::{
    name: @binary.read(r, byte_order),
    type_: @binary.read(r, byte_order),
    sect: @binary.read(r, byte_order),
    desc: @binary.read(r, byte_order),
    value: @binary.read(r, byte_order),
  }
}

///|
// `Regs386` is the Mach-O 386 register structure.
pub struct Regs386 {
  ax : UInt
  bx : UInt
  cx : UInt
  dx : UInt
  di : UInt
  si : UInt
  bp : UInt
  sp : UInt
  ss : UInt
  flags : UInt
  ip : UInt
  cs : UInt
  ds : UInt
  es : UInt
  fs : UInt
  gs : UInt
} derive(Eq, Show)

///|
// `RegsAMD64` is the Mach-O AMD64 register structure.
pub struct RegsAMD64 {
  ax : UInt64
  bx : UInt64
  cx : UInt64
  dx : UInt64
  di : UInt64
  si : UInt64
  bp : UInt64
  sp : UInt64
  r8 : UInt64
  r9 : UInt64
  r10 : UInt64
  r11 : UInt64
  r12 : UInt64
  r13 : UInt64
  r14 : UInt64
  r15 : UInt64
  ip : UInt64
  flags : UInt64
  cs : UInt64
  fs : UInt64
  gs : UInt64
} derive(Eq, Show)
