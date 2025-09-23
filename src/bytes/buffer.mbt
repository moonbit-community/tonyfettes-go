///|
/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

// Simple byte buffer for marshaling data.

// smallBufferSize is an initial allocation minimal capacity.
const SmallBufferSize = 64

///|
/// A Buffer is a variable-sized buffer of bytes with `Buffer.Read` and `Buffer.Write` methods.
/// The zero value for Buffer is an empty buffer ready to use.
struct Buffer {
  mut buf : FixedArray[Byte]
  mut len : Int
  mut off : Int
  mut last_read : ReadOp
} derive(Default)

///|
/// The ReadOp constants describe the last action performed on
/// the buffer, so that UnreadRune and UnreadByte can check for
/// invalid usage. opReadRuneX constants are chosen such that
/// converted to int they correspond to the rune size that was read.
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
pub suberror TooLarge

///|
pub impl Show for TooLarge with output(_ : TooLarge, logger : &Logger) -> Unit {
  logger.write_string("bytes.Buffer: too large")
}

///|
priv suberror NegativeRead

///|
impl Show for NegativeRead with output(_ : NegativeRead, logger : &Logger) -> Unit {
  logger.write_string("bytes.Buffer: reader returned negative count from Read")
}

///|
/// `bytes` returns a slice of length `b.len()` holding the unread portion of the buffer.
/// The slice is valid for use only until the next buffer modification (that is,
/// only until the next call to a method like [Buffer.Read], [Buffer.Write], [Buffer.Reset], or [Buffer.Truncate]).
/// The slice aliases the buffer content at least until the next buffer modification,
/// so immediate changes to the slice will affect the result of future reads.
pub fn Buffer::bytes(self : Buffer) -> @slice.Slice[Byte] {
  @slice.fixedarray(self.buf)[self.off:self.len]
}

///|
/// `available_buffer` returns an empty buffer with b.Available() capacity.
/// This buffer is intended to be appended to and
/// passed to an immediately succeeding [Buffer.Write] call.
/// The buffer is only valid until the next write operation on b.
pub fn Buffer::available_buffer(self : Buffer) -> @slice.Slice[Byte] {
  @slice.fixedarray(self.buf)[self.len:self.buf.length()]
}

///|
/// `string` returns the contents of the unread portion of the buffer
/// as a string.
pub fn Buffer::string(self : Buffer) -> String {
  @utf8.decode_lossy(@slice.fixedarray(self.buf)[self.off:self.len])
}

///|
/// `empty` reports whether the unread portion of the buffer is empty.
fn Buffer::empty(b : Buffer) -> Bool {
  return b.buf.length() <= b.off
}

///|
/// `len` returns the number of bytes of the unread portion of the buffer;
/// `b.len() == len(b.bytes())`.
pub impl @builtin.Len for Buffer with len(b : Buffer) -> Int {
  return b.len - b.off
}

///|
pub fn Buffer::cap(b : Buffer) -> Int {
  return b.buf.length()
}

///|
pub fn Buffer::available(self : Buffer) -> Int {
  return self.buf.length() - self.len
}

///|
pub fn Buffer::truncate(self : Buffer, n : Int) -> Unit {
  if n == 0 {
    self.reset()
    return
  }
  self.last_read = ReadOp::Invalid
  if n < 0 || n > self.len() {
    abort("bytes.Buffer: truncation out of range")
  }
  self.len = self.off + n
}

///|
pub fn Buffer::reset(b : Buffer) -> Unit {
  b.off = 0
  b.last_read = ReadOp::Invalid
}

///|
pub fn Buffer::grow(b : Buffer, n : Int) -> Unit {
  if n < 0 {
    abort("@bytes.Buffer::grow: negative count")
  }
  let m = b.len()
  if m == 0 && b.off != 0 {
    b.reset()
  }
  if n <= b.buf.length() - b.len {
    b.len += n
    return
  }
  let c = b.buf.length()
  if n <= c / 2 - m {
    b.buf.unsafe_blit(b.off, b.buf, 0, b.len)
  } else if c > @int.max_value - c - n {
    abort(TooLarge.to_string())
  } else {
    let mut c = b.len + n
    if c < 2 * b.buf.length() {
      c = 2 * b.buf.length()
    }
    let b2 : FixedArray[Byte] = FixedArray::make(c, 0)
    b2.unsafe_blit(b.off, b.buf, 0, b.len)
    b.buf = b2
  }
}

///|
pub impl @io.Writer for Buffer with write(b : Buffer, p : @slice.Slice[Byte]) -> Int raise {
  b.last_read = ReadOp::Invalid
  let n = p.length()
  if n == 0 {
    return 0
  }
  if n > @int.max_value - b.len {
    abort(TooLarge.to_string())
  }
  if n > b.buf.length() - b.len {
    b.grow(n)
  }
  for i in 0..<n {
    b.buf[b.len + i] = p[i]
  }
  b.len += n
  return n
}

///|
pub impl @io.WriterTo for Buffer with write_to(b : Buffer, w : &@io.Writer) -> Int64 raise {
  let mut n : Int64 = 0
  b.last_read = ReadOp::Invalid
  if b.len() is n_bytes && n_bytes > 0 {
    let m = w.write(@slice.fixedarray(b.buf)[b.off:b.len])
    if m > n_bytes {
      abort("@bytes.Buffer::write_to: invalid write count")
    }
    b.off += m
    n = int64(m)
    if m != n_bytes {
      return n
    }
  }
  b.reset()
  return n
}

///|
pub impl @io.Reader for Buffer with read(b : Buffer, p : @slice.Slice[Byte]) -> Int raise {
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
pub fn new_buffer(bytes : @slice.Slice[Byte]) -> Buffer {
  let buf : FixedArray[Byte] = FixedArray::make(bytes.length(), 0)
  for i in 0..<bytes.length() {
    buf[i] = bytes[i]
  }
  Buffer::{ buf, len: len(bytes), off: 0, last_read: ReadOp::Invalid }
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

///|
pub fn index_byte(s : @slice.Slice[Byte], c : Byte) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == c {
      return i
    }
  }
  return -1
}
