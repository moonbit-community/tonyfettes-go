///|
priv suberror BufferTooSmall

///|
impl Show for BufferTooSmall with output(_ : BufferTooSmall, output : &Logger) -> Unit {
  output.write_string("buffer too small")
}

///|
pub trait ByteOrder: Show + ToJson {
  uint16(self : Self, b : @slice.Slice[Byte]) -> UInt16
  uint32(self : Self, b : @slice.Slice[Byte]) -> UInt
  uint64(self : Self, b : @slice.Slice[Byte]) -> UInt64
  put_uint16(self : Self, b : @slice.Slice[Byte], v : UInt16) -> Unit
  put_uint32(self : Self, b : @slice.Slice[Byte], v : UInt) -> Unit
  put_uint64(self : Self, b : @slice.Slice[Byte], v : UInt64) -> Unit
}

///|
pub trait AppendByteOrder: Show {
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
priv struct LittleEndian {} derive(Show)

///|
pub let little_endian : &ByteOrder = LittleEndian::{  }

///|
impl ToJson for LittleEndian with to_json(_ : LittleEndian) -> Json {
  "LittleEndian"
}

///|
impl ByteOrder for LittleEndian with uint16(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
) -> UInt16 {
  b[0].to_uint16() | (b[1].to_int() << 8).to_uint16()
}

///|
impl ByteOrder for LittleEndian with put_uint16(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
  v : UInt16,
) -> Unit {
  b[0] = (v & 0xff).to_byte()
  b[1] = ((v >> 8) & 0xff).to_byte()
}

///|
impl AppendByteOrder for LittleEndian with append_uint16(
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
impl ByteOrder for LittleEndian with uint32(
  _ : LittleEndian,
  b : @slice.Slice[Byte],
) -> UInt {
  b[0].to_uint() |
  (b[1].to_uint() << 8) |
  (b[2].to_uint() << 16) |
  (b[3].to_uint() << 24)
}

///|
impl ByteOrder for LittleEndian with put_uint32(
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
impl AppendByteOrder for LittleEndian with append_uint32(
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
impl ByteOrder for LittleEndian with uint64(
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
impl ByteOrder for LittleEndian with put_uint64(
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
impl AppendByteOrder for LittleEndian with append_uint64(
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
