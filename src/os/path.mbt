///|
let sysname : Bytes = try! @uv.os_uname().sysname().to_bytes()

///|
let path_separator : Char = if sysname is "Windows_NT" { '\\' } else { '/' }

///|
pub fn is_path_separator(c : Char) -> Bool {
  c == path_separator
}
