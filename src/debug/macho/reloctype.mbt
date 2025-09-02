/// Relocation Types
/// 
/// Defines architecture-specific relocation types for Mach-O binary format.
/// Based on Apple's Mach-O specification and Go's debug/macho implementation.

///|
/// Generic relocation types - used by all architectures
pub enum RelocTypeGeneric {
  Vanilla = 0
  Pair = 1
  Sectdiff = 2
  PbLaPtr = 3
  LocalSectdiff = 4
  Tlv = 5
}

///|
pub fn RelocTypeGeneric::to_int(self : RelocTypeGeneric) -> Int {
  match self {
    Vanilla => 0
    Pair => 1
    Sectdiff => 2
    PbLaPtr => 3
    LocalSectdiff => 4
    Tlv => 5
  }
}

///|
pub fn RelocTypeGeneric::from_int(value : Int) -> RelocTypeGeneric? {
  match value {
    0 => Some(Vanilla)
    1 => Some(Pair)
    2 => Some(Sectdiff)
    3 => Some(PbLaPtr)
    4 => Some(LocalSectdiff)
    5 => Some(Tlv)
    _ => None
  }
}

///|
pub fn RelocTypeGeneric::to_string(self : RelocTypeGeneric) -> String {
  match self {
    Vanilla => "Vanilla"
    Pair => "Pair"
    Sectdiff => "Sectdiff"
    PbLaPtr => "PbLaPtr"
    LocalSectdiff => "LocalSectdiff"
    Tlv => "Tlv"
  }
}

///|
/// x86_64 architecture relocation types
pub enum RelocTypeX86_64 {
  Unsigned // 0
  Signed // 1
  Branch // 2
  GotLoad // 3
  Got // 4
  Subtractor // 5
  Signed1 // 6
  Signed2 // 7
  Signed4 // 8
  Tlv // 9
}

///|
pub fn RelocTypeX86_64::to_int(self : RelocTypeX86_64) -> Int {
  match self {
    Unsigned => 0
    Signed => 1
    Branch => 2
    GotLoad => 3
    Got => 4
    Subtractor => 5
    Signed1 => 6
    Signed2 => 7
    Signed4 => 8
    Tlv => 9
  }
}

///|
pub fn RelocTypeX86_64::from_int(value : Int) -> RelocTypeX86_64? {
  match value {
    0 => Some(Unsigned)
    1 => Some(Signed)
    2 => Some(Branch)
    3 => Some(GotLoad)
    4 => Some(Got)
    5 => Some(Subtractor)
    6 => Some(Signed1)
    7 => Some(Signed2)
    8 => Some(Signed4)
    9 => Some(Tlv)
    _ => None
  }
}

///|
pub fn RelocTypeX86_64::to_string(self : RelocTypeX86_64) -> String {
  match self {
    Unsigned => "Unsigned"
    Signed => "Signed"
    Branch => "Branch"
    GotLoad => "GotLoad"
    Got => "Got"
    Subtractor => "Subtractor"
    Signed1 => "Signed1"
    Signed2 => "Signed2"
    Signed4 => "Signed4"
    Tlv => "Tlv"
  }
}

///|
/// ARM architecture relocation types
pub enum RelocTypeARM {
  Vanilla // 0
  Pair // 1
  Sectdiff // 2
  LocalSectdiff // 3
  PbLaPtr // 4
  Br24 // 5
  ThumbBr22 // 6
  Thumb32BitBranch // 7
  Half // 8
  HalfSectdiff // 9
}

///|
pub fn RelocTypeARM::to_int(self : RelocTypeARM) -> Int {
  match self {
    Vanilla => 0
    Pair => 1
    Sectdiff => 2
    LocalSectdiff => 3
    PbLaPtr => 4
    Br24 => 5
    ThumbBr22 => 6
    Thumb32BitBranch => 7
    Half => 8
    HalfSectdiff => 9
  }
}

///|
pub fn RelocTypeARM::from_int(value : Int) -> RelocTypeARM? {
  match value {
    0 => Some(Vanilla)
    1 => Some(Pair)
    2 => Some(Sectdiff)
    3 => Some(LocalSectdiff)
    4 => Some(PbLaPtr)
    5 => Some(Br24)
    6 => Some(ThumbBr22)
    7 => Some(Thumb32BitBranch)
    8 => Some(Half)
    9 => Some(HalfSectdiff)
    _ => None
  }
}

///|
pub fn RelocTypeARM::to_string(self : RelocTypeARM) -> String {
  match self {
    Vanilla => "Vanilla"
    Pair => "Pair"
    Sectdiff => "Sectdiff"
    LocalSectdiff => "LocalSectdiff"
    PbLaPtr => "PbLaPtr"
    Br24 => "Br24"
    ThumbBr22 => "ThumbBr22"
    Thumb32BitBranch => "Thumb32BitBranch"
    Half => "Half"
    HalfSectdiff => "HalfSectdiff"
  }
}

///|
/// ARM64 architecture relocation types
pub enum RelocTypeARM64 {
  Unsigned = 0
  Subtractor = 1
  Branch26 = 2
  Page21 = 3
  Pageoff12 = 4
  GotLoadPage21 = 5
  GotLoadPageoff12 = 6
  PointerToGot = 7
  TlvpLoadPage21 = 8
  TlvpLoadPageoff12 = 9
  Addend = 10
}

///|
pub fn RelocTypeARM64::to_int(self : RelocTypeARM64) -> Int {
  match self {
    Unsigned => 0
    Subtractor => 1
    Branch26 => 2
    Page21 => 3
    Pageoff12 => 4
    GotLoadPage21 => 5
    GotLoadPageoff12 => 6
    PointerToGot => 7
    TlvpLoadPage21 => 8
    TlvpLoadPageoff12 => 9
    Addend => 10
  }
}

///|
pub fn RelocTypeARM64::from_int(value : Int) -> RelocTypeARM64? {
  match value {
    0 => Some(Unsigned)
    1 => Some(Subtractor)
    2 => Some(Branch26)
    3 => Some(Page21)
    4 => Some(Pageoff12)
    5 => Some(GotLoadPage21)
    6 => Some(GotLoadPageoff12)
    7 => Some(PointerToGot)
    8 => Some(TlvpLoadPage21)
    9 => Some(TlvpLoadPageoff12)
    10 => Some(Addend)
    _ => None
  }
}

///|
pub fn RelocTypeARM64::to_string(self : RelocTypeARM64) -> String {
  match self {
    Unsigned => "Unsigned"
    Subtractor => "Subtractor"
    Branch26 => "Branch26"
    Page21 => "Page21"
    Pageoff12 => "Pageoff12"
    GotLoadPage21 => "GotLoadPage21"
    GotLoadPageoff12 => "GotLoadPageoff12"
    PointerToGot => "PointerToGot"
    TlvpLoadPage21 => "TlvpLoadPage21"
    TlvpLoadPageoff12 => "TlvpLoadPageoff12"
    Addend => "Addend"
  }
}
