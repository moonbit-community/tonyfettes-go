///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
#borrow(path)
extern "c" fn libc_open(path : Bytes, mode : Int, perm : UInt) -> Int = "moonbit_tonyfettes_go_syscall_libc_open"

///|
pub fn open(path : String, mode : Int, perm : UInt) -> Int raise {
  let p0 = bytes_from_string(path)
  let r0 = libc_open(p0, mode, perm)
  if r0 < 0 {
    raise Errno::of_int(r0)
  } else {
    r0
  }
}

///|
extern "c" fn libc_fcntl(fd : Int, cmd : Int, arg : Int) -> Int = "moonbit_tonyfettes_go_syscall_libc_fcntl"

///|
pub fn fcntl(fd : Int, cmd : Int, arg : Int) -> Int raise {
  let r = libc_fcntl(fd, cmd, arg)
  if r < 0 {
    raise Errno::of_int(r)
  } else {
    r
  }
}

///|
extern "c" fn libc_close(fd : Int) -> Int = "moonbit_tonyfettes_go_syscall_libc_close"

///|
pub fn close(fd : Int) -> Unit raise {
  let r = libc_close(fd)
  if r < 0 {
    raise Errno::of_int(r)
  }
}

///|
extern "c" fn libc_closedir(dir : @builtin.UIntPtr) -> Int = "moonbit_tonyfettes_go_syscall_libc_closedir"

///|
pub fn closedir(dir : @builtin.UIntPtr) -> Unit raise {
  let r = libc_closedir(dir)
  if r < 0 {
    raise Errno::of_int(r)
  }
}

///|
extern "c" fn libc_pread(
  fd : Int,
  p : @slice.Slice[Byte],
  offset : Int64,
) -> Int = "moonbit_tonyfettes_go_syscall_libc_pread"

///|
pub fn pread(fd : Int, p : @slice.Slice[Byte], off : Int64) -> Int raise {
  let r = libc_pread(fd, p, off)
  if r < 0 {
    raise Errno::of_int(r)
  } else {
    r
  }
}
