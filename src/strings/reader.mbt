///|
/// A Reader implements the [io.Reader], [io.ReaderAt], [io.ByteReader], [io.ByteScanner],
/// [io.RuneReader], [io.RuneScanner], [io.Seeker], and [io.WriterTo] interfaces by reading
/// from a string.
/// The zero value for Reader operates like a Reader of an empty string.
struct Reader {
  s : Bytes
  mut i : Int64
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
/// new_reader returns a new [Reader] reading from s.
/// It is similar to [bytes.new_buffer_string] but more efficient and non-writable.
pub fn new_reader(s : String) -> Reader {
  Reader::{ s: @utf8.encode(s), i: 0, prev_rune: -1 }
}
