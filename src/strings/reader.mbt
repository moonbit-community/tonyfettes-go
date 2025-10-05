///|
/// A Reader implements the [io.Reader], [io.ReaderAt], [io.ByteReader], [io.ByteScanner],
/// [io.RuneReader], [io.RuneScanner], [io.Seeker], and [io.WriterTo] interfaces by reading
/// from a string.
/// The zero value for Reader operates like a Reader of an empty string.
struct Reader {
  s : Bytes
  /// current reading index
  mut i : Int64
  /// index of previous rune; or < 0
  mut prev_rune : Int
}

///|
pub impl @builtin.Len for Reader with len(self : Reader) -> Int {
  if self.i >= int64(len(self.s)) {
    return 0
  }
  return int(int64(len(self.s)) - self.i)
}

///|
pub fn Reader::size(self : Reader) -> Int64 {
  return int64(len(self.s))
}

///|
pub impl @io.Reader for Reader with read(self : Reader, b : @slice.Slice[Byte]) -> Int raise {
  if self.i >= int64(len(self.s)) {
    raise @io.EOF
  }
  self.prev_rune = -1
  let n = b.copy_from_bytesview(self.s[int(self.i):])
  self.i += int64(n)
  return n
}

///|
priv suberror NegativeOffset

///|
impl Show for NegativeOffset with output(_ : NegativeOffset, logger : &Logger) -> Unit {
  logger.write_string("@strings.Reader::ReaderAt: negative offset")
}

///|
pub impl @io.ReaderAt for Reader with read_at(
  self : Reader,
  b : @slice.Slice[Byte],
  off : Int64,
) -> Int raise {
  if off < 0 {
    raise NegativeOffset
  }
  if off >= int64(len(self.s)) {
    raise @io.EOF
  }
  let n = b.copy_from_bytesview(self.s[int(off):])
  return n
}

///|
pub impl @io.ByteReader for Reader with read_byte(self : Reader) -> Byte raise {
  self.prev_rune = -1
  if self.i >= int64(len(self.s)) {
    raise @io.EOF
  }
  let b = self.s[int(self.i)]
  self.i += 1
  return b
}

///|
pub impl @io.ByteScanner for Reader with unread_byte(self : Reader) -> Unit raise {
  if self.i <= 0 {
    raise @io.EOF
  }
  self.prev_rune = -1
  self.i -= 1
}

///|
pub impl @io.RuneReader for Reader with read_rune(self : Reader) -> (Rune, Int) raise {
  if self.i >= int64(len(self.s)) {
    self.prev_rune = -1
    raise @io.EOF
  }
  self.prev_rune = int(self.i)
  if self.s[int(self.i)] is c && c < @utf8.RuneSelf {
    self.i += 1
    return (c.to_char(), 1)
  }
  let (ch, size) = @utf8.decode_rune(@slice.bytes(self.s)[int(self.i):])
  self.i += int64(size)
  return (ch, size)
}

///|
priv suberror AtBeginningOfString

///|
priv suberror PreviousOperationWasNotReadRune

///|
pub impl @io.RuneScanner for Reader with unread_rune(self : Reader) -> Unit raise {
  if self.i <= 0 {
    raise AtBeginningOfString
  }
  if self.prev_rune < 0 {
    raise PreviousOperationWasNotReadRune
  }
  self.i = int64(self.prev_rune)
  self.prev_rune = -1
}

///|
priv suberror NegativePosition

///|
pub impl @io.Seeker for Reader with seek(
  self : Reader,
  offset : Int64,
  whence : @io.SeekWhence,
) -> Int64 raise {
  self.prev_rune = -1
  let abs = match whence {
    SeekCurrent => self.i + offset
    SeekStart => offset
    SeekEnd => int64(len(self.s)) + offset
  }
  if abs < 0 {
    raise NegativePosition
  }
  self.i = abs
  return abs
}

///|
pub impl @io.WriterTo for Reader with write_to(self : Reader, w : &@io.Writer) -> Int64 raise {
  self.prev_rune = -1
  if self.i >= int64(len(self.s)) {
    return 0
  }
  let s = @slice.bytes(self.s)[int(self.i):]
  let n = w.write(s)
  if n > len(s) {
    abort("@strings.Reader::write_to: invalid write count")
  }
  self.i += int64(n)
  return int64(n)
}

///|
/// new_reader returns a new [Reader] reading from s.
/// It is similar to [bytes.new_buffer_string] but more efficient and non-writable.
pub fn new_reader(s : String) -> Reader {
  Reader::{ s: @utf8.encode(s), i: 0, prev_rune: -1 }
}
