///|
/// ELF32 File header.
pub struct Header32 {
  /// File identification. [16]
  ident : FixedArray[Byte]
  /// File type.
  type_ : UInt
  /// Machine architecture.
  machine : UInt
  /// ELF format version.
  version : UInt
  /// Entry point.
  entry : UInt
  /// Program header file offset.
  phoff : UInt
  /// Section header file offset.
  shoff : UInt
  /// Architecture-specific flags.
  flags : UInt
  /// Size of ELF header in bytes.
  ehsize : UInt
  /// Size of program header entry.
  phentsize : UInt
  /// Number of program header entries.
  phnum : UInt
  /// Size of section header entry.
  shentsize : UInt
  /// Number of section header entries.
  shnum : UInt
  /// Section name strings section.
  shstrndx : UInt
} derive(Show, ToJson, Default)

///|
/// ELF32 Section header.
pub struct Section32 {
  /// Section name (index into the section header string table).
  name : UInt
  /// Section type.
  type_ : UInt
  /// Section flags.
  flags : UInt
  /// Address in memory image.
  addr : UInt
  /// Offset in file.
  off : UInt
  /// Size in bytes.
  size : UInt
  /// Index of a related section.
  link : UInt
  /// Depends on section type.
  info : UInt
  /// Alignment in bytes.
  addralign : UInt
  /// Size of each entry in section.
  entsize : UInt
} derive(Show, ToJson)

///|
/// ELF32 Program header.
pub struct Prog32 {
  /// Entry type.
  type_ : UInt
  /// File offset of contents.
  off : UInt
  /// Virtual address in memory image.
  vaddr : UInt
  /// Physical address (not used).
  paddr : UInt
  /// Size of contents in file.
  filesz : UInt
  /// Size of contents in memory.
  memsz : UInt
  /// Access permission flags.
  flags : UInt
  /// Alignment in memory and file.
  align : UInt
} derive(Show, ToJson)

///|
/// ELF32 Dynamic structure. The ".dynamic" section contains an array of them.
pub struct Dyn32 {
  /// Entry type.
  tag : Int
  /// Integer/Address value.
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
  off : UInt
  /// Relocation type and symbol index.
  info : UInt
} derive(Show, ToJson)

///|
/// ELF32 Relocations that need an addend field.
pub struct Rela32 {
  /// Location to be relocated.
  off : UInt
  /// Relocation type and symbol index.
  info : UInt
  /// Addend.
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
  ident : FixedArray[Byte]
  /// File type.
  type_ : UInt
  /// Machine architecture.
  machine : UInt
  /// ELF format version.
  version : UInt
  /// Entry point.
  entry : UInt64
  /// Program header file offset.
  phoff : UInt64
  /// Section header file offset.
  shoff : UInt64
  /// Architecture-specific flags.
  flags : UInt
  /// Size of ELF header in bytes.
  ehsize : UInt
  /// Size of program header entry.
  phentsize : UInt
  /// Number of program header entries.
  phnum : UInt
  /// Size of section header entry.
  shentsize : UInt
  /// Number of section header entries.
  shnum : UInt
  /// Section name strings section.
  shstrndx : UInt
} derive(Show, ToJson)

///|
/// ELF64 Section header.
pub struct Section64 {
  /// Section name (index into the section header string table).
  name : UInt
  /// Section type.
  type_ : UInt
  /// Section flags.
  flags : UInt64
  /// Address in memory image.
  addr : UInt64
  /// Offset in file.
  off : UInt64
  /// Size in bytes.
  size : UInt64
  /// Index of a related section.
  link : UInt
  /// Depends on section type.
  info : UInt
  /// Alignment in bytes.
  addralign : UInt64
  /// Size of each entry in section.
  entsize : UInt64
} derive(Show, ToJson)

///|
/// ELF64 Program header.
pub struct Prog64 {
  /// Entry type.
  type_ : UInt
  /// Access permission flags.
  flags : UInt
  /// File offset of contents.
  off : UInt64
  /// Virtual address in memory image.
  vaddr : UInt64
  /// Physical address (not used).
  paddr : UInt64
  /// Size of contents in file.
  filesz : UInt64
  /// Size of contents in memory.
  memsz : UInt64
  /// Alignment in memory and file.
  align : UInt64
} derive(Show, ToJson)

///|
/// ELF64 Dynamic structure. The ".dynamic" section contains an array of them.
pub struct Dyn64 {
  /// Entry type.
  tag : Int64
  /// Integer/address value
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
  off : UInt64
  /// Relocation type and symbol index.
  info : UInt64
} derive(Show, ToJson)

///|
/// ELF64 relocations that need an addend field.
pub struct Rela64 {
  /// Location to be relocated.
  off : UInt64
  /// Relocation type and symbol index.
  info : UInt64
  /// Addend.
  addend : Int64
} derive(Show, ToJson)

///|
/// ELF64 symbol table entries.
pub struct Sym64 {
  /// String table index of name.
  name : UInt
  /// Type and binding information.
  info : Byte
  /// Reserved (not used).
  other : Byte
  /// Section index of symbol.
  shndx : UInt
  /// Symbol value.
  value : UInt64
  /// Size of associated object.
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
} derive(Eq, Show, ToJson)

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
