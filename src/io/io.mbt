///|
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
pub suberror Eof

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
