///|
/// ELF32 File header.
pub struct Header32 {
  /// File identification. [16]
  /// File type.
  /// Machine architecture.
  /// ELF format version.
  /// Entry point.
  /// Program header file offset.
  /// Section header file offset.
  /// Architecture-specific flags.
  /// Size of ELF header in bytes.
  /// Size of program header entry.
  /// Number of program header entries.
  /// Size of section header entry.
  /// Number of section header entries.
  /// Section name strings section.
  ident : FixedArray[Byte]
  type_ : UInt
  machine : UInt
  version : UInt
  entry : UInt
  phoff : UInt
  shoff : UInt
  flags : UInt
  ehsize : UInt
  phentsize : UInt
  phnum : UInt
  shentsize : UInt
  shnum : UInt
  shstrndx : UInt
} derive(Show, ToJson)

///|
/// ELF32 Section header.
pub struct Section32 {
  /// Section name (index into the section header string table).
  /// Section type.
  /// Section flags.
  /// Address in memory image.
  /// Offset in file.
  /// Size in bytes.
  /// Index of a related section.
  /// Depends on section type.
  /// Alignment in bytes.
  /// Size of each entry in section.
  name : UInt
  type_ : UInt
  flags : UInt
  addr : UInt
  off : UInt
  size : UInt
  link : UInt
  info : UInt
  addralign : UInt
  entsize : UInt
} derive(Show, ToJson)

///|
/// ELF32 Program header.
pub struct Prog32 {
  /// Entry type.
  /// File offset of contents.
  /// Virtual address in memory image.
  /// Physical address (not used).
  /// Size of contents in file.
  /// Size of contents in memory.
  /// Access permission flags.
  /// Alignment in memory and file.
  type_ : UInt
  off : UInt
  vaddr : UInt
  paddr : UInt
  filesz : UInt
  memsz : UInt
  flags : UInt
  align : UInt
} derive(Show, ToJson)

///|
/// ELF32 Dynamic structure. The ".dynamic" section contains an array of them.
pub struct Dyn32 {
  /// Entry type.
  /// Integer/Address value.
  tag : Int
  val : UInt
} derive(Show, ToJson)

///|
/// ELF32 Compression header.
pub struct Chdr32 {
  type_ : UInt
  size : UInt
  addralign : UInt
} derive(Show, ToJson)

///|
/// ELF32 Relocations that don't need an addend field.
pub struct Rel32 {
  /// Location to be relocated.
  /// Relocation type and symbol index.
  off : UInt
  info : UInt
} derive(Show, ToJson)

///|
/// ELF32 Relocations that need an addend field.
pub struct Rela32 {
  /// Location to be relocated.
  /// Relocation type and symbol index.
  /// Addend.
  off : UInt
  info : UInt
  addend : Int
} derive(Show, ToJson)

///|
/// ELF32 Symbol.
pub struct Sym32 {
  name : UInt
  value : UInt
  size : UInt
  info : Byte
  other : Byte
  shndx : UInt
} derive(Show, ToJson)

///|
pub const Sym32Size : Int = 16

///|
/// ELF64 file header.
pub struct Header64 {
  /// File identification. [16]
  /// File type.
  /// Machine architecture.
  /// ELF format version.
  /// Entry point.
  /// Program header file offset.
  /// Section header file offset.
  /// Architecture-specific flags.
  /// Size of ELF header in bytes.
  /// Size of program header entry.
  /// Number of program header entries.
  /// Size of section header entry.
  /// Number of section header entries.
  /// Section name strings section.
  ident : FixedArray[Byte]
  type_ : UInt
  machine : UInt
  version : UInt
  entry : UInt64
  phoff : UInt64
  shoff : UInt64
  flags : UInt
  ehsize : UInt
  phentsize : UInt
  phnum : UInt
  shentsize : UInt
  shnum : UInt
  shstrndx : UInt
} derive(Show, ToJson)

///|
/// ELF64 Section header.
pub struct Section64 {
  /// Section name (index into the section header string table).
  /// Section type.
  /// Section flags.
  /// Address in memory image.
  /// Offset in file.
  /// Size in bytes.
  /// Index of a related section.
  /// Depends on section type.
  /// Alignment in bytes.
  /// Size of each entry in section.
  name : UInt
  type_ : UInt
  flags : UInt64
  addr : UInt64
  off : UInt64
  size : UInt64
  link : UInt
  info : UInt
  addralign : UInt64
  entsize : UInt64
} derive(Show, ToJson)

///|
/// ELF64 Program header.
pub struct Prog64 {
  /// Entry type.
  /// Access permission flags.
  /// File offset of contents.
  /// Virtual address in memory image.
  /// Physical address (not used).
  /// Size of contents in file.
  /// Size of contents in memory.
  /// Alignment in memory and file.
  type_ : UInt
  flags : UInt
  off : UInt64
  vaddr : UInt64
  paddr : UInt64
  filesz : UInt64
  memsz : UInt64
  align : UInt64
} derive(Show, ToJson)

///|
/// ELF64 Dynamic structure. The ".dynamic" section contains an array of them.
pub struct Dyn64 {
  /// Entry type.
  /// Integer/address value
  tag : Int64
  val : UInt64
} derive(Show, ToJson)

///|
/// ELF64 Compression header.
pub struct Chdr64 {
  type_ : UInt
  /// reserved : UInt  /// Reserved. (padding)
  size : UInt64
  addralign : UInt64
} derive(Show, ToJson)

///|
/// ELF64 relocations that don't need an addend field.
pub struct Rel64 {
  /// Location to be relocated.
  /// Relocation type and symbol index.
  off : UInt64
  info : UInt64
} derive(Show, ToJson)

///|
/// ELF64 relocations that need an addend field.
pub struct Rela64 {
  /// Location to be relocated.
  /// Relocation type and symbol index.
  /// Addend.
  off : UInt64
  info : UInt64
  addend : Int64
} derive(Show, ToJson)

///|
/// ELF64 symbol table entries.
pub struct Sym64 {
  /// String table index of name.
  /// Type and binding information.
  /// Reserved (not used).
  /// Section index of symbol.
  /// Symbol value.
  /// Size of associated object.
  name : UInt
  info : Byte
  other : Byte
  shndx : UInt
  value : UInt64
  size : UInt64
} derive(Show, ToJson)

///|
pub const Sym64Size : Int = 24

///|
/// Helper functions for relocation info manipulation

///|
/// R_SYM32 extracts symbol index from 32-bit relocation info
pub fn r_sym32(info : UInt) -> UInt {
  info >> 8
}

///|
/// R_TYPE32 extracts relocation type from 32-bit relocation info
pub fn r_type32(info : UInt) -> UInt {
  info & 0xff
}

///|
/// R_INFO32 constructs 32-bit relocation info from symbol and type
pub fn r_info32(sym : UInt, typ : UInt) -> UInt {
  (sym << 8) | typ
}

///|
/// R_SYM64 extracts symbol index from 64-bit relocation info
pub fn r_sym64(info : UInt64) -> UInt {
  (info >> 32).to_uint()
}

///|
/// R_TYPE64 extracts relocation type from 64-bit relocation info
pub fn r_type64(info : UInt64) -> UInt {
  (info & 0xffffffff).to_uint()
}

///|
/// R_INFO constructs 64-bit relocation info from symbol and type
pub fn r_info(sym : UInt, typ : UInt) -> UInt64 {
  (sym.to_uint64() << 32) | typ.to_uint64()
}

///|
/// Helper functions for symbol info manipulation

///|
/// ST_BIND extracts binding from symbol info
pub fn st_bind(info : Byte) -> SymBind {
  SymBind::from_int((info >> 4).to_int())
}

///|
/// ST_TYPE extracts type from symbol info
pub fn st_type(info : Byte) -> SymType {
  SymType::from_int((info & 0xF).to_int())
}

///|
/// ST_INFO constructs symbol info from binding and type
pub fn st_info(bind : SymBind, typ : SymType) -> Byte {
  ((bind.to_int() << 4) | (typ.to_int() & 0xf)).to_byte()
}

///|
/// Symbol visibility - st_other
pub(all) enum SymVis {
  /// 0 Default visibility (see binding).
  STV_DEFAULT
  /// 1 Processor specific hidden class.
  STV_INTERNAL
  /// 2 Sym unavailable in other modules.
  STV_HIDDEN
  /// 3 Not preemptible, not exported.
  STV_PROTECTED
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn SymVis::to_int(self : SymVis) -> Int {
  match self {
    STV_DEFAULT => 0
    STV_INTERNAL => 1
    STV_HIDDEN => 2
    STV_PROTECTED => 3
  }
}

///|
pub fn SymVis::from_int(i : Int) -> SymVis {
  match i {
    0 => STV_DEFAULT
    1 => STV_INTERNAL
    2 => STV_HIDDEN
    3 => STV_PROTECTED
    _ => STV_DEFAULT
  }
}

///|
/// ST_VISIBILITY extracts visibility from symbol other field
pub fn st_visibility(other : Byte) -> SymVis {
  SymVis::from_int((other & 3).to_int())
}
