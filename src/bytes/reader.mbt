///|
fnalias @slice.copy

///|
fnalias @builtin.len

///|
struct Reader {
  s : @slice.Slice[Byte]
  mut i : Int64
  mut prev_rune : Int
}

///|
pub impl @builtin.Len for Reader with len(self : Reader) -> Int {
  return self.s.length()
}

///|
pub fn Reader::size(self : Reader) -> Int64 {
  return self.s.length().to_int64()
}

///|
pub impl @io.Reader for Reader with read(self : Reader, b : @slice.Slice[Byte]) -> Int raise {
  if self.i >= self.s.length().to_int64() {
    raise @io.EOF
  }
  let n = copy(b, self.s[self.i.to_int():])
  self.i += n.to_int64()
  self.prev_rune = -1
  return n
}

///|
suberror NegativeOffset

///|
pub impl Show for NegativeOffset with output(
  _ : NegativeOffset,
  logger : &Logger,
) -> Unit {
  logger.write_string("impl @io.ReaderAt for @bytes.Reader: negative offset")
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
  if off >= self.s.length().to_int64() {
    raise @io.EOF
  }
  let n = copy(b, self.s[off.to_int():])
  return n
}

///|
pub impl @io.ByteReader for Reader with read_byte(self : Reader) -> Byte raise {
  self.prev_rune = -1
  if self.i >= self.s.length().to_int64() {
    raise @io.EOF
  }
  let b = self.s[self.i.to_int()]
  self.i += 1
  return b
}

///|
priv suberror AtBeginningOfSlice derive(Show)

///|
pub impl @io.ByteScanner for Reader with unread_byte(self : Reader) -> Unit raise {
  if self.i <= 0 {
    raise AtBeginningOfSlice
  }
  self.prev_rune = -1
  self.i -= 1
}

///|
pub impl @io.RuneReader for Reader with read_rune(self : Reader) -> (Rune, Int) raise {
  if self.i >= self.s.length().to_int64() {
    self.prev_rune = -1
    raise @io.EOF
  }
  self.prev_rune = int(self.i)
  if self.s[int(self.i)] is c && c < @utf8.RuneSelf.to_int().to_byte() {
    self.i += 1
    return (c.to_char(), 1)
  }
  let (ch, size) = @utf8.decode_rune(self.s[self.i.to_int():])
  self.i += size.to_int64()
  return (ch, size)
}

///|
priv suberror PreviousOperationWasNotReadRune derive(Show)

///|
pub impl @io.RuneScanner for Reader with unread_rune(self : Reader) -> Unit raise {
  if self.i <= 0 {
    raise AtBeginningOfSlice
  }
  if self.prev_rune < 0 {
    raise PreviousOperationWasNotReadRune
  }
  self.i = int64(self.prev_rune)
  self.prev_rune = -1
  return
}

///|
priv suberror NegativePosition derive(Show)

///|
pub impl @io.Seeker for Reader with seek(
  self : Reader,
  offset : Int64,
  whence : @io.SeekWhence,
) -> Int64 raise {
  self.prev_rune = -1
  let abs = match whence {
    @io.SeekStart => offset
    @io.SeekCurrent => self.i + offset
    @io.SeekEnd => self.s.length().to_int64() + offset
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
    return 0L
  }
  let b = self.s[self.i.to_int():]
  let m = w.write(b)
  if m > len(b) {
    abort("impl @io.WriteTo for @bytes.Reader: invalid write count")
  }
  let n = int64(m)
  self.i += n
  n
}

///|
/// `reset` resets the `Reader` to be reading from b.
pub fn Reader::reset(self : Reader) -> Unit {
  self.i = 0L
  self.prev_rune = -1
}

///|
/// `NewReader` returns a new `Reader` reading from b.
pub fn new_reader(b : @slice.Slice[Byte]) -> Reader {
  Reader::{ s: b, i: 0L, prev_rune: -1 }
}
