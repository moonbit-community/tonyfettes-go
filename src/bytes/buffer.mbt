///|
struct Buffer {
  buf : FixedArray[Byte]
  mut off : Int
  mut last_read : ReadOp
}

///|
priv enum ReadOp {
  Read
  Invalid
  ReadRune1
  ReadRune2
  ReadRune3
  ReadRune4
}

///|
impl Default for ReadOp with default() -> ReadOp {
  ReadOp::Invalid
}

///|
fn Buffer::empty(b : Buffer) -> Bool {
  return b.buf.length() <= b.off
}

///|
pub fn Buffer::reset(b : Buffer) -> Unit {
  b.off = 0
  b.last_read = ReadOp::Invalid
}

///|
pub impl @io.Reader for Buffer with read(b : Buffer, p : ArrayView[Byte]) -> Int raise {
  b.last_read = ReadOp::Invalid
  if b.empty() {
    b.reset()
    if p.length() == 0 {
      return 0
    }
    raise @io.EOF
  }
  let n = @cmp.minimum(p.length(), b.buf.length() - b.off)
  for i in 0..<n {
    p[i] = b.buf[b.off + i]
  }
  b.off += n
  if n > 0 {
    b.last_read = ReadOp::Read
  }
  return n
}

///|
pub fn new_buffer(bytes : ArrayView[Byte]) -> Buffer {
  let buf : FixedArray[Byte] = FixedArray::make(bytes.length(), 0)
  for i in 0..<bytes.length() {
    buf[i] = bytes[i]
  }
  Buffer::{ buf, off: 0, last_read: ReadOp::Invalid }
}

///|
pub impl @io.ByteReader for Buffer with read_byte(self : Buffer) -> Byte raise {
  if self.empty() {
    raise @io.EOF
  }
  let b = self.buf[self.off]
  self.off += 1
  b
}
