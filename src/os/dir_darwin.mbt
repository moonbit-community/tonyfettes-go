///|
priv struct DirInfo(@builtin.UIntPtr)

fn DirInfo::close(self : DirInfo) -> Unit {
  if self.0.to_uint64() == 0 {
    return
  }
}
