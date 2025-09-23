///|
/// errorReader returns error from all operations.
priv struct ErrorReader {
  error : Error
}

///|
fn ErrorReader::new(error : Error) -> ErrorReader {
  ErrorReader::{ error, }
}

///|
/// ErrorReader implements io.Reader
impl @io.Reader for ErrorReader with read(self, _ : @slice.Slice[Byte]) -> Int raise {
  raise self.error
}

///|
/// ErrorReader implements io.ReaderAt
impl @io.ReaderAt for ErrorReader with read_at(
  self : ErrorReader,
  _ : @slice.Slice[Byte],
  _ : Int64,
) -> Int raise {
  raise self.error
}

///|
impl @io.Seeker for ErrorReader with seek(
  self : ErrorReader,
  _ : Int64,
  _ : @io.SeekWhence,
) -> Int64 raise {
  raise self.error
}

///|
/// ErrorReader implements io.Closer
impl @io.Closer for ErrorReader with close(self : ErrorReader) -> Unit raise {
  raise self.error
}

///|
/// readSeekerFromReader converts an io.Reader into an io.ReadSeeker.
/// In general Seek may not be efficient, but it is optimized for
/// common cases such as seeking to the end to find the length of the
/// data.
priv struct ReadSeekerFromReader {
  reset : () -> &@io.Reader raise
  mut r : &@io.Reader?
  size : Int64
  mut offset : Int64
}

///|
fn ReadSeekerFromReader::new(
  reset~ : () -> &@io.Reader raise,
  size~ : Int64,
) -> ReadSeekerFromReader {
  ReadSeekerFromReader::{ reset, r: None, size, offset: 0L }
}

///|
fn ReadSeekerFromReader::start(self : ReadSeekerFromReader) -> &@io.Reader {
  try {
    let x = (self.reset)()
    self.r = Some(x)
    self.offset = 0L
    x
  } catch {
    err => {
      let r = ErrorReader::{ error: err } as &@io.Reader
      self.r = Some(r)
      self.offset = 0L
      r
    }
  }
}

///|
/// ReadSeekerFromReader implements io.Reader
impl @io.Reader for ReadSeekerFromReader with read(self, p) {
  let r : &@io.Reader = match self.r {
    None => self.start()
    Some(r) => r
  }
  let n = r.read(p)
  self.offset = self.offset + n.to_int64()
  n
}

///|
/// ReadSeekerFromReader implements io.ReadSeeker
impl @io.Seeker for ReadSeekerFromReader with seek(r, offset, whence) {
  let new_offset = match whence {
    @io.SeekStart => offset
    @io.SeekCurrent => r.offset + offset
    @io.SeekEnd => r.size + offset
  }
  if new_offset == r.offset {
    return new_offset
  }
  if new_offset < 0L || new_offset > r.size {
    raise @io.InvalidOffset(new_offset)
  }
  if new_offset == 0L {
    r.r = None
    r.offset = 0L
    return new_offset
  }
  if new_offset == r.size {
    r.r = Some(ErrorReader::{ error: @io.EOF } as &@io.Reader)
    r.offset = new_offset
    return new_offset
  }
  if new_offset < r.offset {
    // Restart at the beginning.
    r.start() |> ignore()
  }
  // Read until we reach offset.
  let buf : FixedArray[Byte] = FixedArray::make(512, 0)
  while r.offset < new_offset {
    let buf = @slice.fixedarray(buf)
    let b = if new_offset - r.offset < buf.length().to_int64() {
      buf[:(new_offset - r.offset).to_int()]
    } else {
      buf
    }
    r.read(b) |> ignore
  }
  r.offset = new_offset
  new_offset
}
