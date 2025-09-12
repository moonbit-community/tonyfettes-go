///|
pub const O_RDONLY : Int = @syscall.O_RDONLY

///|
pub const O_APPEND : Int = @syscall.O_APPEND

///|
pub const O_CREATE : Int = @syscall.O_CREAT

///|
pub fn open(name : String) -> File raise {
  return open_file(name, O_RDONLY, FileMode::default())
}

///|
pub fn open_file(name : String, flag : Int, perm : FileMode) -> File raise {
  let f = open_file_no_log(name, flag, perm)
  f.append_mode = (flag & O_APPEND) != 0
  return f
}

///|
priv suberror PathEscapes

///|
fn set_sticky_bit(_ : String) -> Unit {

}
