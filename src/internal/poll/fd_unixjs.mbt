///|
struct SysFile {}

///|
pub fn SysFile::new() -> SysFile {
  SysFile::{  }
}

///|
pub fn SysFile::destroy(_ : SysFile, fd : Int) -> Unit raise {
  /// We don't use ignoringEINTR here because POSIX does not define
  /// whether the descriptor is closed if close returns EINTR.
  /// If the descriptor is indeed closed, using a loop would race
  /// with some other goroutine opening a new descriptor.
  /// (The Linux kernel guarantees that it is closed on an EINTR error.)
  return close_func(fd)
}
