/// Relocation Types
/// 
/// Defines architecture-specific relocation types for Mach-O binary format.
/// Based on Apple's Mach-O specification and Go's debug/macho implementation.

///|
/// Generic relocation types - used by all architectures
pub enum RelocTypeGeneric {
  GENERIC_RELOC_VANILLA // 0
  GENERIC_RELOC_PAIR // 1
  GENERIC_RELOC_SECTDIFF // 2
  GENERIC_RELOC_PB_LA_PTR // 3
  GENERIC_RELOC_LOCAL_SECTDIFF // 4
  GENERIC_RELOC_TLV // 5
}

///|
pub fn RelocTypeGeneric::to_int(self : RelocTypeGeneric) -> Int {
  match self {
    GENERIC_RELOC_VANILLA => 0
    GENERIC_RELOC_PAIR => 1
    GENERIC_RELOC_SECTDIFF => 2
    GENERIC_RELOC_PB_LA_PTR => 3
    GENERIC_RELOC_LOCAL_SECTDIFF => 4
    GENERIC_RELOC_TLV => 5
  }
}

///|
pub fn RelocTypeGeneric::from_int(value : Int) -> RelocTypeGeneric? {
  match value {
    0 => Some(GENERIC_RELOC_VANILLA)
    1 => Some(GENERIC_RELOC_PAIR)
    2 => Some(GENERIC_RELOC_SECTDIFF)
    3 => Some(GENERIC_RELOC_PB_LA_PTR)
    4 => Some(GENERIC_RELOC_LOCAL_SECTDIFF)
    5 => Some(GENERIC_RELOC_TLV)
    _ => None
  }
}

///|
/// x86_64 architecture relocation types
pub enum RelocTypeX86_64 {
  X86_64_RELOC_UNSIGNED // 0
  X86_64_RELOC_SIGNED // 1
  X86_64_RELOC_BRANCH // 2
  X86_64_RELOC_GOT_LOAD // 3
  X86_64_RELOC_GOT // 4
  X86_64_RELOC_SUBTRACTOR // 5
  X86_64_RELOC_SIGNED_1 // 6
  X86_64_RELOC_SIGNED_2 // 7
  X86_64_RELOC_SIGNED_4 // 8
  X86_64_RELOC_TLV // 9
}

///|
pub fn RelocTypeX86_64::to_int(self : RelocTypeX86_64) -> Int {
  match self {
    X86_64_RELOC_UNSIGNED => 0
    X86_64_RELOC_SIGNED => 1
    X86_64_RELOC_BRANCH => 2
    X86_64_RELOC_GOT_LOAD => 3
    X86_64_RELOC_GOT => 4
    X86_64_RELOC_SUBTRACTOR => 5
    X86_64_RELOC_SIGNED_1 => 6
    X86_64_RELOC_SIGNED_2 => 7
    X86_64_RELOC_SIGNED_4 => 8
    X86_64_RELOC_TLV => 9
  }
}

///|
pub fn RelocTypeX86_64::from_int(value : Int) -> RelocTypeX86_64? {
  match value {
    0 => Some(X86_64_RELOC_UNSIGNED)
    1 => Some(X86_64_RELOC_SIGNED)
    2 => Some(X86_64_RELOC_BRANCH)
    3 => Some(X86_64_RELOC_GOT_LOAD)
    4 => Some(X86_64_RELOC_GOT)
    5 => Some(X86_64_RELOC_SUBTRACTOR)
    6 => Some(X86_64_RELOC_SIGNED_1)
    7 => Some(X86_64_RELOC_SIGNED_2)
    8 => Some(X86_64_RELOC_SIGNED_4)
    9 => Some(X86_64_RELOC_TLV)
    _ => None
  }
}

///|
/// ARM architecture relocation types
pub enum RelocTypeARM {
  ARM_RELOC_VANILLA // 0
  ARM_RELOC_PAIR // 1
  ARM_RELOC_SECTDIFF // 2
  ARM_RELOC_LOCAL_SECTDIFF // 3
  ARM_RELOC_PB_LA_PTR // 4
  ARM_RELOC_BR24 // 5
  ARM_THUMB_RELOC_BR22 // 6
  ARM_THUMB_32BIT_BRANCH // 7
  ARM_RELOC_HALF // 8
  ARM_RELOC_HALF_SECTDIFF // 9
}

///|
pub fn RelocTypeARM::to_int(self : RelocTypeARM) -> Int {
  match self {
    ARM_RELOC_VANILLA => 0
    ARM_RELOC_PAIR => 1
    ARM_RELOC_SECTDIFF => 2
    ARM_RELOC_LOCAL_SECTDIFF => 3
    ARM_RELOC_PB_LA_PTR => 4
    ARM_RELOC_BR24 => 5
    ARM_THUMB_RELOC_BR22 => 6
    ARM_THUMB_32BIT_BRANCH => 7
    ARM_RELOC_HALF => 8
    ARM_RELOC_HALF_SECTDIFF => 9
  }
}

///|
pub fn RelocTypeARM::from_int(value : Int) -> RelocTypeARM? {
  match value {
    0 => Some(ARM_RELOC_VANILLA)
    1 => Some(ARM_RELOC_PAIR)
    2 => Some(ARM_RELOC_SECTDIFF)
    3 => Some(ARM_RELOC_LOCAL_SECTDIFF)
    4 => Some(ARM_RELOC_PB_LA_PTR)
    5 => Some(ARM_RELOC_BR24)
    6 => Some(ARM_THUMB_RELOC_BR22)
    7 => Some(ARM_THUMB_32BIT_BRANCH)
    8 => Some(ARM_RELOC_HALF)
    9 => Some(ARM_RELOC_HALF_SECTDIFF)
    _ => None
  }
}

///|
/// ARM64 architecture relocation types
pub enum RelocTypeARM64 {
  ARM64_RELOC_UNSIGNED // 0
  ARM64_RELOC_SUBTRACTOR // 1
  ARM64_RELOC_BRANCH26 // 2
  ARM64_RELOC_PAGE21 // 3
  ARM64_RELOC_PAGEOFF12 // 4
  ARM64_RELOC_GOT_LOAD_PAGE21 // 5
  ARM64_RELOC_GOT_LOAD_PAGEOFF12 // 6
  ARM64_RELOC_POINTER_TO_GOT // 7
  ARM64_RELOC_TLVP_LOAD_PAGE21 // 8
  ARM64_RELOC_TLVP_LOAD_PAGEOFF12 // 9
  ARM64_RELOC_ADDEND // 10
}

///|
pub fn RelocTypeARM64::to_int(self : RelocTypeARM64) -> Int {
  match self {
    ARM64_RELOC_UNSIGNED => 0
    ARM64_RELOC_SUBTRACTOR => 1
    ARM64_RELOC_BRANCH26 => 2
    ARM64_RELOC_PAGE21 => 3
    ARM64_RELOC_PAGEOFF12 => 4
    ARM64_RELOC_GOT_LOAD_PAGE21 => 5
    ARM64_RELOC_GOT_LOAD_PAGEOFF12 => 6
    ARM64_RELOC_POINTER_TO_GOT => 7
    ARM64_RELOC_TLVP_LOAD_PAGE21 => 8
    ARM64_RELOC_TLVP_LOAD_PAGEOFF12 => 9
    ARM64_RELOC_ADDEND => 10
  }
}

///|
pub fn RelocTypeARM64::from_int(value : Int) -> RelocTypeARM64? {
  match value {
    0 => Some(ARM64_RELOC_UNSIGNED)
    1 => Some(ARM64_RELOC_SUBTRACTOR)
    2 => Some(ARM64_RELOC_BRANCH26)
    3 => Some(ARM64_RELOC_PAGE21)
    4 => Some(ARM64_RELOC_PAGEOFF12)
    5 => Some(ARM64_RELOC_GOT_LOAD_PAGE21)
    6 => Some(ARM64_RELOC_GOT_LOAD_PAGEOFF12)
    7 => Some(ARM64_RELOC_POINTER_TO_GOT)
    8 => Some(ARM64_RELOC_TLVP_LOAD_PAGE21)
    9 => Some(ARM64_RELOC_TLVP_LOAD_PAGEOFF12)
    10 => Some(ARM64_RELOC_ADDEND)
    _ => None
  }
}
