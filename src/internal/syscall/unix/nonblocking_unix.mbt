///|
pub fn has_nonblock_flag(flag : Int) -> Bool {
  return (flag & @syscall.O_NONBLOCK) != 0
}
