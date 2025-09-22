///|
/// one_byte_reader returns a Reader that implements
/// each non-empty Read by reading one byte from r.
pub fn one_byte_reader(r : &@io.Reader) -> &@io.Reader {
  OneByteReader::{ r, }
}

///|
priv struct OneByteReader {
  r : &@io.Reader
}

///|
impl @io.Reader for OneByteReader with read(
  self : OneByteReader,
  p : @slice.Slice[Byte],
) -> Int raise {
  if len(p) == 0 {
    return 0
  }
  return self.r.read(p[0:1])
}

///|
priv struct HalfReader {
  r : &@io.Reader
}

///|
/// half_reader returns a Reader that implements Read
/// by reading half as many requested bytes from r.
pub fn half_reader(r : &@io.Reader) -> &@io.Reader {
  HalfReader::{ r, }
}

///|
impl @io.Reader for HalfReader with read(
  self : HalfReader,
  p : @slice.Slice[Byte],
) -> Int raise {
  return self.r.read(p[0:(len(p) + 1) / 2])
}

///|
pub suberror Timeout

///|
/// TimeoutReader returns [ErrTimeout] on the second read
/// with no data. Subsequent calls to read succeed.
pub fn timeout_reader(r : &@io.Reader) -> &@io.Reader {
  TimeoutReader::{ r, count: 0 }
}

///|
struct TimeoutReader {
  r : &@io.Reader
  mut count : Int
}

///|
pub impl @io.Reader for TimeoutReader with read(
  self : TimeoutReader,
  p : @slice.Slice[Byte],
) -> Int raise {
  self.count += 1
  if self.count == 2 {
    raise Timeout
  }
  return self.r.read(p)
}
