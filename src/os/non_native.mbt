///|
pub const O_RDONLY : Int = 0x0

///|
pub const O_WRONLY : Int = 0x1

///|
pub const O_RDWR : Int = 0x2

///|
pub const O_APPEND : Int = 0x4

///|
pub const O_CREATE : Int = 0x8

///|
pub const O_EXCL : Int = 0x10

///|
pub const O_SYNC : Int = 0x20

///|
pub const O_TRUNC : Int = 0x40

///|
type File

///|
pub fn open(_name : String) -> File raise {
  raise Invalid
}

///|
pub fn open_file(_name : String, _flag : Int, _perm : FileMode) -> File raise {
  raise Invalid
}

///|
pub impl @io.Reader for File with read(_self : File, _b : @slice.Slice[Byte]) -> Int raise {
  raise Invalid
}

///|
pub impl @io.ReaderAt for File with read_at(
  _self : File,
  _b : @slice.Slice[Byte],
  _off : Int64,
) -> Int raise {
  raise Invalid
}

///|
pub impl @io.Closer for File with close(_self : File) -> Unit raise {
  raise Invalid
}

///|
pub fn temp_dir() -> String {
  ""
}

///|
pub fn getenv(_key : String) -> String {
  ""
}

///|
pub fn is_path_separator(c : Char) -> Bool {
  c == '/'
}

///|
pub fn create_temp(_dir : String, _pattern : String) -> File raise {
  raise Invalid
}

///|
pub fn join_path(dir : String, name : StringView) -> String {
  if dir is [.., '/'] {
    [..dir, ..name]
  } else {
    [..dir, '/', ..name]
  }
}
