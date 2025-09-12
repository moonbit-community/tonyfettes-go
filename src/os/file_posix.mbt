///|
fn syscall_mode(i : FileMode) -> UInt {
  let mut o = i.perm().to_uint()
  if i.is_setuid() {
    o = o | @syscall.S_ISUID.reinterpret_as_uint()
  }
  if i.is_setgid() {
    o = o | @syscall.S_ISGID.reinterpret_as_uint()
  }
  if i.is_sticky() {
    o = o | @syscall.S_ISVTX.reinterpret_as_uint()
  }
  o
}

///|
fn[T] ignoring_EINTR(f : () -> T raise) -> T raise {
  for {
    return f() catch {
      @syscall.Errno::EINTR => continue
      err => raise err
    }
  }
}
