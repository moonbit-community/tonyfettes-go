///|
/// Reader is the trait that wraps the basic read method.
/// read reads up to bytes.length() bytes into bytes. It returns the number of bytes
/// read (0 <= n <= bytes.length()) and any error encountered.
pub(open) trait Reader {
  read(self : Self, bytes : @slice.Slice[Byte]) -> Int raise
}

///|
/// Writer is the trait that wraps the basic write method.
/// write writes bytes.length() bytes from bytes to the underlying data stream.
/// It returns the number of bytes written from bytes (0 <= n <= bytes.length())
/// and any error encountered that caused the write to stop early.
pub(open) trait Writer {
  write(self : Self, bytes : @slice.Slice[Byte]) -> Int raise
}

///|
pub impl Writer for @buffer.T with write(
  self : @buffer.T,
  bytes : @slice.Slice[Byte],
) -> Int {
  for i in 0..<bytes.length() {
    self.write_byte(bytes[i])
  }
  bytes.length()
}

///|
/// ByteReader is the trait that wraps the read_byte method.
/// read_byte reads and returns the next byte from the input or
/// any error encountered. If read_byte returns an error, no input
/// byte was consumed.
pub(open) trait ByteReader {
  read_byte(self : Self) -> Byte raise
}

///|
/// ReaderAt is the trait that wraps the basic read_at method.
/// read_at reads bytes.length() bytes into bytes starting at offset off in the
/// underlying input source. It returns the number of bytes read and any error encountered.
pub(open) trait ReaderAt {
  read_at(self : Self, bytes : @slice.Slice[Byte], off : Int64) -> Int raise
}

///|
struct SectionReader {
  r : &ReaderAt
  base : Int64
  mut off : Int64
  limit : Int64
  n : Int64
}

///|
pub fn SectionReader::new(
  r : &ReaderAt,
  off : Int64,
  n : Int64,
) -> SectionReader {
  let remaining = if off <= @int64.max_value - n {
    n + off
  } else {
    @int64.max_value
  }
  SectionReader::{ r, base: off, off, limit: remaining, n }
}

///|
pub fn SectionReader::read(
  s : SectionReader,
  p : @slice.Slice[Byte],
) -> Int raise {
  if s.off >= s.limit {
    return 0
  }
  let max = s.limit - s.off
  let p = if p.length().to_int64() > max { p[0:max.to_int()] } else { p }
  let n = s.r.read_at(p, s.off)
  s.off += n.to_int64()
  return n
}

///|
suberror SeekError {
  InvalidOffset(Int64)
}

///|
pub(all) enum SeekWhence {
  Start
  Current
  End
}

///|
pub fn SectionReader::seek(
  s : SectionReader,
  offset : Int64,
  whence : SeekWhence,
) -> Int64 raise SeekError {
  let offset = match whence {
    Start => offset + s.base
    Current => offset + s.off
    End => offset + s.limit
  }
  if offset < s.base {
    raise SeekError::InvalidOffset(offset)
  }
  s.off = offset
  return offset - s.base
}

///|
/// Standard io errors
pub(all) suberror EOF

///|
pub(all) suberror UnexpectedEof

///|
pub(all) suberror ShortWrite

///|
pub(all) suberror ShortBuffer

///|
/// read_full reads exactly bytes.length() bytes from r into bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
pub fn[R : Reader] read_full(r : R, bytes : @slice.Slice[Byte]) -> Int raise {
  let mut total = 0
  let mut remaining = bytes
  while remaining.length() > 0 {
    let n = r.read(remaining) catch {
      EOF if total > 0 => raise UnexpectedEof
      e => raise e
    }
    if n == 0 {
      if total == 0 {
        raise EOF
      } else {
        raise UnexpectedEof
      }
    }
    total += n
    remaining = remaining[n:]
  }
  total
}

///|
pub fn SectionReader::read_at(
  s : SectionReader,
  p : @slice.Slice[Byte],
  off : Int64,
) -> Int raise {
  if off < 0 || off >= s.size() {
    raise EOF
  }
  let max = s.limit - off
  if p.length().to_int64() > max {
    let p = p[0:max.to_int()]
    return s.r.read_at(p, off)
  } else {
    return s.r.read_at(p, off)
  }
}

///|
pub fn SectionReader::size(s : SectionReader) -> Int64 {
  return s.limit - s.base
}

///|
pub(open) trait Closer {
  close(self : Self) -> Unit raise
}

///|
/// ReadCloser is the interface that groups the basic Read and Close methods.
pub(open) trait ReadCloser: Reader + Closer {}

///|
/// WriteCloser is the interface that groups the basic Write and Close methods.
pub(open) trait WriteCloser: Writer + Closer {}

///|
/// ByteWriter is the trait that wraps the write_byte method.
/// write_byte writes a single byte.
pub(open) trait ByteWriter {
  write_byte(self : Self, b : Byte) -> Unit raise
}

///|
/// ReadSeeker is the interface that groups the basic Read and Seek methods.
pub(open) trait ReadSeeker: Reader {
  seek(self : Self, offset : Int64, whence : SeekWhence) -> Int64 raise SeekError
}

///|
/// WriteSeeker is the interface that groups the basic Write and Seek methods.
pub(open) trait WriteSeeker: Writer {
  seek(self : Self, offset : Int64, whence : SeekWhence) -> Int64 raise SeekError
}

///|
/// ReadWriteSeeker is the interface that groups the basic Read, Write and Seek methods.
pub(open) trait ReadWriteSeeker: Reader + Writer {
  seek(self : Self, offset : Int64, whence : SeekWhence) -> Int64 raise SeekError
}

///|
/// StringWriter is the interface that wraps the write_string method.
pub(open) trait StringWriter {
  write_string(self : Self, s : String) -> Int raise
}

///|
/// Resetter is the interface that wraps the Reset method.
pub(open) trait Resetter {
  reset(self : Self, r : &Reader) -> Unit raise
}

///|
/// NoProgress is returned by some clients of a Reader when
/// many calls to Read have failed to return any data or error,
/// usually the sign of a broken Reader implementation.
pub(all) suberror NoProgress

///|
/// InvalidWrite means that a write returned an impossible count.
pub(all) suberror InvalidWrite

///|
/// ReadWriteCloser is the interface that groups the basic Read, Write and Close methods.
pub(open) trait ReadWriteCloser: Reader + Writer + Closer {}

///|
/// WriterAt is the trait that wraps the basic write_at method.
/// write_at writes bytes.length() bytes from bytes to the underlying data stream
/// at offset off. It returns the number of bytes written from bytes and any error encountered.
pub(open) trait WriterAt {
  write_at(self : Self, bytes : @slice.Slice[Byte], off : Int64) -> Int raise
}

///|
/// ReadWriter is the interface that groups the basic Read and Write methods.
pub(open) trait ReadWriter: Reader + Writer {}

///|
/// LimitedReader reads from R but limits the amount of
/// data returned to just N bytes.
struct LimitedReader {
  r : &Reader
  mut n : Int64
}

///|
/// LimitReader returns a Reader that reads from r
/// but stops with EOF after n bytes.
pub fn limit_reader(r : &Reader, n : Int64) -> LimitedReader {
  LimitedReader::{ r, n }
}

///|
pub impl Reader for LimitedReader with read(self, p) {
  if self.n <= 0 {
    raise EOF
  }
  let max = p.length().to_int64()
  let to_read = if max > self.n { self.n.to_int() } else { p.length() }
  let n = self.r.read(p[0:to_read])
  self.n -= n.to_int64()
  n
}

///|
/// read_at_least reads from r into buf until it has read at least min bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
pub fn[R : Reader] read_at_least(
  r : R,
  buf : @slice.Slice[Byte],
  min : Int,
) -> Int raise {
  if buf.length() < min {
    raise ShortBuffer
  }
  let mut n = 0
  let mut buf = buf
  while n < min {
    let nn = r.read(buf) catch {
      EOF if n > 0 => raise UnexpectedEof
      e => raise e
    }
    if nn == 0 {
      if n == 0 {
        raise EOF
      } else {
        raise UnexpectedEof
      }
    }
    n += nn
    buf = buf[nn:]
  }
  n
}

///|
pub(open) trait ReaderFrom {
  read_from(r : &Reader) -> Int64 raise
}

///|
pub(open) trait WriteTo {
  write_to(w : &Writer) -> Int64 raise
}

///|
/// copy_n copies n bytes (or until an error) from src to dst.
/// It returns the number of bytes copied and the first error encountered while copying, if any.
pub fn[R : Reader, W : Writer] copy_n(
  dst : W,
  src : R,
  n : Int64,
) -> Int64 raise {
  let mut written = 0L
  let mut remaining = n
  let buf : @slice.Slice[Byte] = @slice.make(8192) // 8KB buffer
  while remaining > 0 {
    let to_read = if remaining > buf.length().to_int64() {
      buf.length()
    } else {
      remaining.to_int()
    }
    let nr = src.read(buf[0:to_read]) catch {
      EOF => break
      e => raise e
    }
    if nr == 0 {
      break
    }
    let nw = dst.write(buf[0:nr])
    if nw < 0 || nr < nw {
      raise InvalidWrite
    }
    written += nw.to_int64()
    if nw != nr {
      raise ShortWrite
    }
    remaining -= nr.to_int64()
  }
  written
}

///|
/// NewSectionReader returns a SectionReader that reads from r
/// starting at offset off and stops with EOF after n bytes.
pub fn new_section_reader(
  r : &ReaderAt,
  off : Int64,
  n : Int64,
) -> SectionReader {
  SectionReader::new(r, off, n)
}
