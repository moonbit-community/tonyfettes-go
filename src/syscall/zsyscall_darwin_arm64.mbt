///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
#borrow(path)
extern "c" fn libc_open(path : Bytes, mode : Int, perm : UInt) -> Int = "moonbit_tonyfettes_go_libc_open"

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
