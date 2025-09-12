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
    let m = self.pread(b, off) catch {
      err => raise self.wrap_error("read", err)
    }
    n += m
    b = b[m:]
    off += m.to_int64()
  }
  return n
}
