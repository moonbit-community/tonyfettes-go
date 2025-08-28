///|
pub fn is_64bit(file : File) -> Bool {
  file.header.magic == Magic64
}

///|
pub fn is_32bit(file : File) -> Bool {
  file.header.magic == Magic32
}

///|
pub fn get_architecture(file : File) -> String {
  match file.header.cpu {
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
pub fn get_file_type(file : File) -> String {
  match file.header.type_ {
    Object => "Object"
    Exec => "Executable"
    Dylib => "Dynamic Library"
    Bundle => "Bundle"
    Unknown(val) => "Unknown(" + val.to_string() + ")"
  }
}

///|
pub fn has_flag(file : File, flag : UInt) -> Bool {
  (file.header.flags & flag) != 0_U
}
