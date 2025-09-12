///|
fn _open(path : String, flag : Int, perm : UInt) -> (Int, @poll.SysFile) raise {
  let fd = @syscall.open(path, flag, perm)
  return (fd, @poll.SysFile::new())
}
