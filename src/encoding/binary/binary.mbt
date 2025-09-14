///|
priv suberror BufferTooSmall

///|
impl Show for BufferTooSmall with output(_ : BufferTooSmall, output : &Logger) -> Unit {
  output.write_string("buffer too small")
}

///|
pub trait ByteOrder {
  uint16(self : Self, b : @slice.Slice[Byte]) -> UInt16
  uint32(self : Self, b : @slice.Slice[Byte]) -> UInt
  uint64(self : Self, b : @slice.Slice[Byte]) -> UInt64
  put_uint16(self : Self, b : @slice.Slice[Byte], v : UInt16) -> Unit
  put_uint32(self : Self, b : @slice.Slice[Byte], v : UInt) -> Unit
  put_uint64(self : Self, b : @slice.Slice[Byte], v : UInt64) -> Unit
}

///|
pub trait AppendByteOrder {
  append_uint16(self : Self, b : @slice.Slice[Byte], v : UInt16) -> @slice.Slice[
    Byte,
  ]
  append_uint32(self : Self, b : @slice.Slice[Byte], v : UInt) -> @slice.Slice[
    Byte,
  ]
  append_uint64(self : Self, b : @slice.Slice[Byte], v : UInt64) -> @slice.Slice[
    Byte,
  ]
}

///|
struct LittleEndian {}

///|
pub let little_endian : LittleEndian = LittleEndian::{  }

///|
pub impl ByteOrder for LittleEndian with uint16(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
) -> UInt16 {
  b[0].to_uint16() | (b[1].to_int() << 8).to_uint16()
}

///|
pub impl ByteOrder for LittleEndian with put_uint16(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt16,
) -> Unit {
  b[0] = (v & 0xff).to_byte()
  b[1] = ((v >> 8) & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for LittleEndian with append_uint16(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt16,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 2)
  let _ = nb.copy(b)
  nb[n] = (v & 0xff).to_byte()
  nb[n + 1] = ((v >> 8) & 0xff).to_byte()
  nb
}

///|
pub impl ByteOrder for LittleEndian with uint32(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
) -> UInt {
  b[0].to_uint() |
  (b[1].to_uint() << 8) |
  (b[2].to_uint() << 16) |
  (b[3].to_uint() << 24)
}

///|
pub impl ByteOrder for LittleEndian with put_uint32(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt,
) -> Unit {
  b[0] = (v & 0xff).to_byte()
  b[1] = ((v >> 8) & 0xff).to_byte()
  b[2] = ((v >> 16) & 0xff).to_byte()
  b[3] = ((v >> 24) & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for LittleEndian with append_uint32(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 4)
  let _ = nb.copy(b)
  nb[n] = (v & 0xff).to_byte()
  nb[n + 1] = ((v >> 8) & 0xff).to_byte()
  nb[n + 2] = ((v >> 16) & 0xff).to_byte()
  nb[n + 3] = ((v >> 24) & 0xff).to_byte()
  nb
}

///|
pub impl ByteOrder for LittleEndian with uint64(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
) -> UInt64 {
  let lo = b[0].to_uint() |
    (b[1].to_uint() << 8) |
    (b[2].to_uint() << 16) |
    (b[3].to_uint() << 24)
  let hi = b[4].to_uint() |
    (b[5].to_uint() << 8) |
    (b[6].to_uint() << 16) |
    (b[7].to_uint() << 24)
  lo.to_uint64() | (hi.to_uint64() << 32)
}

///|
pub impl ByteOrder for LittleEndian with put_uint64(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt64,
) -> Unit {
  let lo = (v & 0xffffffff).to_uint()
  let hi = (v >> 32).to_uint()
  b[0] = (lo & 0xff).to_byte()
  b[1] = ((lo >> 8) & 0xff).to_byte()
  b[2] = ((lo >> 16) & 0xff).to_byte()
  b[3] = ((lo >> 24) & 0xff).to_byte()
  b[4] = (hi & 0xff).to_byte()
  b[5] = ((hi >> 8) & 0xff).to_byte()
  b[6] = ((hi >> 16) & 0xff).to_byte()
  b[7] = ((hi >> 24) & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for LittleEndian with append_uint64(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt64,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 8)
  let _ = nb.copy(b)
  let lo = (v & 0xffffffff).to_uint()
  let hi = (v >> 32).to_uint()
  nb[n] = (lo & 0xff).to_byte()
  nb[n + 1] = ((lo >> 8) & 0xff).to_byte()
  nb[n + 2] = ((lo >> 16) & 0xff).to_byte()
  nb[n + 3] = ((lo >> 24) & 0xff).to_byte()
  nb[n + 4] = (hi & 0xff).to_byte()
  nb[n + 5] = ((hi >> 8) & 0xff).to_byte()
  nb[n + 6] = ((hi >> 16) & 0xff).to_byte()
  nb[n + 7] = ((hi >> 24) & 0xff).to_byte()
  nb
}

///|
struct BigEndian {}

///|
pub let big_endian : BigEndian = BigEndian::{  }

///|
pub impl ByteOrder for BigEndian with uint16(
  _ : BigEndian,
  b : @slice.Slice[Byte],
) -> UInt16 {
  (b[0].to_int() << 8).to_uint16() | b[1].to_uint16()
}

///|
pub impl ByteOrder for BigEndian with put_uint16(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt16,
) -> Unit {
  b[0] = ((v >> 8) & 0xff).to_byte()
  b[1] = (v & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for BigEndian with append_uint16(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt16,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 2)
  let _ = nb.copy(b)
  nb[n] = ((v >> 8) & 0xff).to_byte()
  nb[n + 1] = (v & 0xff).to_byte()
  nb
}

///|
pub impl ByteOrder for BigEndian with uint32(
  _ : BigEndian,
  b : @slice.Slice[Byte],
) -> UInt {
  (b[0].to_uint() << 24) |
  (b[1].to_uint() << 16) |
  (b[2].to_uint() << 8) |
  b[3].to_uint()
}

///|
pub impl ByteOrder for BigEndian with put_uint32(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt,
) -> Unit {
  b[0] = ((v >> 24) & 0xff).to_byte()
  b[1] = ((v >> 16) & 0xff).to_byte()
  b[2] = ((v >> 8) & 0xff).to_byte()
  b[3] = (v & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for BigEndian with append_uint32(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 4)
  let _ = nb.copy(b)
  nb[n] = ((v >> 24) & 0xff).to_byte()
  nb[n + 1] = ((v >> 16) & 0xff).to_byte()
  nb[n + 2] = ((v >> 8) & 0xff).to_byte()
  nb[n + 3] = (v & 0xff).to_byte()
  nb
}

///|
pub impl ByteOrder for BigEndian with uint64(
  _ : BigEndian,
  b : @slice.Slice[Byte],
) -> UInt64 {
  let hi = (b[0].to_uint() << 24) |
    (b[1].to_uint() << 16) |
    (b[2].to_uint() << 8) |
    b[3].to_uint()
  let lo = (b[4].to_uint() << 24) |
    (b[5].to_uint() << 16) |
    (b[6].to_uint() << 8) |
    b[7].to_uint()
  lo.to_uint64() | (hi.to_uint64() << 32)
}

///|
pub impl ByteOrder for BigEndian with put_uint64(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt64,
) -> Unit {
  let hi = (v >> 32).to_uint()
  let lo = (v & 0xffffffff).to_uint()
  b[0] = ((hi >> 24) & 0xff).to_byte()
  b[1] = ((hi >> 16) & 0xff).to_byte()
  b[2] = ((hi >> 8) & 0xff).to_byte()
  b[3] = (hi & 0xff).to_byte()
  b[4] = ((lo >> 24) & 0xff).to_byte()
  b[5] = ((lo >> 16) & 0xff).to_byte()
  b[6] = ((lo >> 8) & 0xff).to_byte()
  b[7] = (lo & 0xff).to_byte()
}

///|
pub impl AppendByteOrder for BigEndian with append_uint64(
  _ : BigEndian,
  b : @slice.Slice[Byte],
  v : UInt64,
) -> @slice.Slice[Byte] {
  let n = b.length()
  let nb = @slice.make(n + 8)
  let _ = nb.copy(b)
  let hi = (v >> 32).to_uint()
  let lo = (v & 0xffffffff).to_uint()
  nb[n] = ((hi >> 24) & 0xff).to_byte()
  nb[n + 1] = ((hi >> 16) & 0xff).to_byte()
  nb[n + 2] = ((hi >> 8) & 0xff).to_byte()
  nb[n + 3] = (hi & 0xff).to_byte()
  nb[n + 4] = ((lo >> 24) & 0xff).to_byte()
  nb[n + 5] = ((lo >> 16) & 0xff).to_byte()
  nb[n + 6] = ((lo >> 8) & 0xff).to_byte()
  nb[n + 7] = (lo & 0xff).to_byte()
  nb
}

///|
pub(open) trait Readable {
  read(r : &@io.Reader, order : &ByteOrder) -> Self raise
}

///|
impl Readable for Int with read(r : &@io.Reader, order : &ByteOrder) -> Int raise {
  let buf = @slice.make(4)
  let n = r.read(buf)
  if n != 4 {
    raise BufferTooSmall
  }
  order.uint32(buf).reinterpret_as_int()
}
