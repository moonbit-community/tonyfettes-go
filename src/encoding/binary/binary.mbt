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
pub impl Show for LittleEndian with output(_ : LittleEndian, logger : &Logger) -> Unit {
  logger.write_string("LittleEndian")
}

///|
pub impl ToJson for LittleEndian with to_json(self : LittleEndian) -> Json {
  "LittleEndian"
}

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
pub impl Show for BigEndian with output(_ : BigEndian, logger : &Logger) -> Unit {
  logger.write_string("BigEndian")
}

///|
pub impl ToJson for BigEndian with to_json(self : BigEndian) -> Json {
  "BigEndian"
}

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
  read(r : &@io.Reader, order : &ByteOrder, data : Self) -> Self raise
}

///|
pub impl Readable for Byte with read(r : &@io.Reader, _ : &ByteOrder, _ : Byte) -> Byte raise {
  let buf = @slice.make(1)
  let n = r.read(buf)
  if n != 1 {
    raise BufferTooSmall
  }
  buf[0]
}

///|
pub impl Readable for UInt16 with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : UInt16,
) -> UInt16 raise {
  let buf = @slice.make(2)
  let n = r.read(buf)
  if n != 2 {
    raise BufferTooSmall
  }
  order.uint16(buf)
}

///|
pub impl Readable for Int16 with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : Int16,
) -> Int16 raise {
  let buf = @slice.make(2)
  let n = r.read(buf)
  if n != 2 {
    raise BufferTooSmall
  }
  order.uint16(buf).to_int().to_int16()
}

///|
pub impl Readable for Int with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : Int,
) -> Int raise {
  let buf = @slice.make(4)
  let n = r.read(buf)
  if n != 4 {
    raise BufferTooSmall
  }
  order.uint32(buf).reinterpret_as_int()
}

///|
pub impl Readable for UInt with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : UInt,
) -> UInt raise {
  let buf = @slice.make(4)
  let n = r.read(buf)
  if n != 4 {
    raise BufferTooSmall
  }
  order.uint32(buf)
}

///|
pub impl Readable for Int64 with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : Int64,
) -> Int64 raise {
  let buf = @slice.make(8)
  let n = r.read(buf)
  if n != 8 {
    raise BufferTooSmall
  }
  order.uint64(buf).reinterpret_as_int64()
}

///|
pub impl Readable for UInt64 with read(
  r : &@io.Reader,
  order : &ByteOrder,
  _ : UInt64,
) -> UInt64 raise {
  let buf = @slice.make(8)
  let n = r.read(buf)
  if n != 8 {
    raise BufferTooSmall
  }
  order.uint64(buf)
}

///|
/// `read` reads structured binary data from `r`:
/// 1. into `data`, if `data` is mutable;
/// 2. and returns a value of type `T` if `data` is immutable.
///
/// Bytes read from `r` are decoded using the specified byte order
/// and written to successive fields of the data.
/// When decoding boolean values, a zero byte is decoded as false, and
/// any other non-zero byte is decoded as true.
///
/// The error is `@io.EOF` only if no bytes were read.
/// If an `@io.EOF` happens after reading some but not all the bytes,
/// `read` returns `@io.ErrUnexpectedEOF`.
pub fn[T : Readable] read(
  r : &@io.Reader,
  order : &ByteOrder,
  data : T,
) -> T raise {
  T::read(r, order, data)
}

///|
pub impl[T : Readable] Readable for FixedArray[T] with read(
  r : &@io.Reader,
  order : &ByteOrder,
  data : FixedArray[T],
) -> FixedArray[T] raise {
  for i = 0; i < data.length(); i = i + 1 {
    data[i] = T::read(r, order, data[i])
  }
  data
}

///|
pub impl[T : Readable] Readable for Array[T] with read(
  r : &@io.Reader,
  order : &ByteOrder,
  data : Array[T],
) -> Array[T] raise {
  for i = 0; i < data.length(); i = i + 1 {
    data[i] = T::read(r, order, data[i])
  }
  data
}

///|
pub impl[T : Readable] Readable for Ref[T] with read(
  r : &@io.Reader,
  order : &ByteOrder,
  data : Ref[T],
) -> Ref[T] raise {
  data.val = T::read(r, order, data.val)
  data
}

///|
pub impl[T : Readable] Readable for @slice.Slice[T] with read(
  r : &@io.Reader,
  order : &ByteOrder,
  data : @slice.Slice[T],
) -> @slice.Slice[T] raise {
  for i = 0; i < data.length(); i = i + 1 {
    data[i] = T::read(r, order, data[i])
  }
  data
}

///|
pub(open) trait Sized {
  size() -> Int
}

///|
pub fn[T : Sized] size(value : T) -> Int {
  ignore(value)
  T::size()
}

///|
pub impl Sized for UInt16 with size() -> Int {
  2
}
