///|
/// Reader is the trait that wraps the basic read method.
/// read reads up to bytes.length() bytes into bytes. It returns the number of bytes
/// read (0 <= n <= bytes.length()) and any error encountered.
pub(open) trait Reader {
  read(self : Self, bytes : @bytes.View) -> Int raise
}

///|
/// Writer is the trait that wraps the basic write method.
/// write writes bytes.length() bytes from bytes to the underlying data stream.
/// It returns the number of bytes written from bytes (0 <= n <= bytes.length())
/// and any error encountered that caused the write to stop early.
pub(open) trait Writer {
  write(self : Self, bytes : Bytes) -> Int raise
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
  read_at(self : Self, bytes : @bytes.View, off : Int64) -> Int raise
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
pub fn SectionReader::read(s : SectionReader, p : @bytes.View) -> Int raise {
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
pub suberror Eof

///|
pub suberror UnexpectedEof

///|
pub suberror ShortWrite

///|
pub suberror ShortBuffer

///|
/// read_full reads exactly bytes.length() bytes from r into bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
pub fn[R : Reader] read_full(r : R, bytes : @bytes.View) -> Int raise {
  let mut total = 0
  let mut remaining = bytes
  while remaining.length() > 0 {
    let n = r.read(remaining) catch {
      Eof if total > 0 => raise UnexpectedEof
      e => raise e
    }
    if n == 0 {
      if total == 0 {
        raise Eof
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
  p : @bytes.View,
  off : Int64,
) -> Int raise {
  if off < 0 || off >= s.size() {
    raise Eof
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
  close() -> Unit raise
}
