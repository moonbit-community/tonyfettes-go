///|
/// open the file read-only.
pub const O_RDONLY : Int = 0x0

///|
/// open the file write-only.
pub const O_WRONLY : Int = 0x1

///|
/// open the file read-write.
pub const O_RDWR : Int = 0x2

///|
/// append data to the file when writing.
pub const O_APPEND : Int = 0x4

///|
/// create a new file if none exists.
pub const O_CREATE : Int = 0x8

///|
/// used with O_CREATE, file must not exist.
pub const O_EXCL : Int = 0x10

///|
/// open for synchronous I/O.
pub const O_SYNC : Int = 0x20

///|
/// truncate regular writable file when opened.
pub const O_TRUNC : Int = 0x40

///|
struct File {
  pfd : @uv.File
  name : String
  append_mode : Bool
}

///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
pub fn open(name : String) -> File raise {
  return open_file(name, O_RDONLY, FileMode::default())
}

///|
pub fn open_file(name : String, flag : Int, perm : FileMode) -> File raise {
  let flags = if (flag & O_RDWR) != 0 {
    @uv.OpenFlags::read_write(
      append=(flag & O_APPEND) != 0,
      create=(flag & O_CREATE) != 0,
      truncate=(flag & O_TRUNC) != 0,
    )
  } else if (flag & O_WRONLY) != 0 {
    @uv.OpenFlags::write_only(
      append=(flag & O_APPEND) != 0,
      create=(flag & O_CREATE) != 0,
      truncate=(flag & O_TRUNC) != 0,
    )
  } else {
    @uv.OpenFlags::read_only()
  }
  let pfd = uv
    .unwrap_or_error()
    .fs_open_sync(
      @utf8.encode(name),
      flags,
      perm.to_uint().reinterpret_as_int(),
    )
  return File::{ pfd, name, append_mode: (flag & O_APPEND) != 0 }
}

///|
fn File::wrap_error(self : File, op : String, err : Error) -> Error {
  if err is @io.EOF {
    return err
  }
  if err is @poll.FileClosing {
    return @oserror.Closed
  }
  return @fs.PathError::new(op~, path=self.name, err)
}

///|
/// ReadAt reads len(b) bytes from the File starting at byte offset off.
/// It returns the number of bytes read and the error, if any.
/// ReadAt always returns a non-nil error when n < len(b).
/// At end of file, that error is io.EOF.
pub impl @io.ReaderAt for File with read_at(
  self : File,
  b : @slice.Slice[Byte],
  off : Int64,
) -> Int raise {
  if off < 0 {
    raise @fs.PathError::new(
      op="readat",
      path=self.name,
      Failure("negative offset"),
    )
  }
  let mut b = b
  let mut n = 0
  let mut off = off
  while b.length() > 0 {
    let m = uv
    .unwrap_or_error()
    .fs_read_sync(self.pfd, [b.bytesview()], offset=off) catch {
      err => raise self.wrap_error("read", err)
    }
    n += m
    b = b[m:]
    off += m.to_int64()
  }
  return n
}

///|
pub impl @io.Closer for File with close(self : File) -> Unit raise {
  uv.unwrap_or_error().fs_close_sync(self.pfd) catch {
    err => raise self.wrap_error("close", err)
  }
  return
}
