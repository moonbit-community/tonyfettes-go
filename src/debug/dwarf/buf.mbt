/// Buffered reading and decoding of DWARF data streams
/// Ported from Go's debug/dwarf package

///|
/// Data format, other than byte order. This affects the handling of
/// certain field formats.
priv trait DataFormat {
  /// DWARF version number. Zero means unknown.
  version(self : Self) -> Int
  /// 64-bit DWARF format?
  dwarf64(self : Self) -> (Bool, Bool) // (dwarf64, isKnown)
  /// Size of an address, in bytes. Zero means unknown.
  addrsize(self : Self) -> Int
}

///|
/// Some parts of DWARF have no data format, e.g., abbrevs.
priv struct UnknownFormat {}

///|
fn UnknownFormat::new() -> UnknownFormat {
  UnknownFormat::{  }
}

///|
impl DataFormat for UnknownFormat with version(_) {
  0
}

///|
impl DataFormat for UnknownFormat with dwarf64(_) {
  (false, false)
}

///|
impl DataFormat for UnknownFormat with addrsize(_) {
  0
}

///|
/// Data struct is now defined in data.mbt

///|
/// Data buffer being decoded.
priv struct Buf {
  dwarf : Data
  order : ByteOrder
  format : &DataFormat
  name : String
  mut off : Offset
  mut data : @slice.Slice[Byte]
  mut err : DecodeError?
}

///|
impl Default for Buf with default() -> Buf {
  Buf::{
    dwarf: Data::default(),
    order: LittleEndian,
    format: UnknownFormat::new(),
    name: "",
    off: 0,
    data: @slice.new(),
    err: None,
  }
}

///|
/// Byte order enumeration
pub enum ByteOrder {
  LittleEndian
  BigEndian
} derive(Show, Eq)

///|
fn[DataFormat : DataFormat] make_buf(
  d : Data,
  format : DataFormat,
  name : String,
  off : Offset,
  data : @slice.Slice[Byte],
) -> Buf {
  { dwarf: d, order: d.order, format, name, off, data, err: None }
}

///|
/// Decode error
pub suberror DecodeError {
  DecodeError(name~ : String, offset~ : Offset, String)
}

///|
/// Create a new DecodeError
pub fn DecodeError::new(
  name : String,
  offset : Offset,
  err : String,
) -> DecodeError {
  DecodeError(name~, offset~, err)
}

///|
/// Convert to string
pub impl Show for DecodeError with output(self : DecodeError, logger : &Logger) -> @unit.T {
  let DecodeError(name~, offset~, err) = self
  logger.write_string(
    "decoding dwarf section \{name} at offset 0x\{offset}: \{err}",
  )
}

///|
/// Read a uint8
fn Buf::uint8(self : Buf) -> UInt raise {
  if self.data.length() < 1 {
    raise self.error("underflow")
  }
  let val = self.data[0].to_uint()
  self.data = self.data[1:]
  self.off += 1
  val
}

///|
/// Read n bytes
fn Buf::bytes(self : Buf, n : Int) -> @slice.Slice[Byte] raise {
  if n < 0 || self.data.length() < n {
    raise self.error("underflow")
  }
  let data = self.data[:n]
  self.data = self.data[n:]
  self.off += n.reinterpret_as_uint()
  data
}

///|
/// Skip n bytes
fn Buf::skip(self : Buf, n : Int) -> @unit.T raise {
  ignore(self.bytes(n))
}

///|
/// Read a null-terminated string
fn Buf::string(self : Buf) -> String raise {
  let i = @bytes.index_byte(self.data, 0)
  if i < 0 {
    raise self.error("underflow")
  }
  let s = self.data[:i]
  self.data = self.data[i + 1:]
  self.off += (i + 1).reinterpret_as_uint()
  @encoding.decoder(UTF8).decode_lossy(s.bytesview())
}

///|
/// Read a uint16
fn Buf::uint16(self : Buf) -> UInt raise {
  let a = self.bytes(2)
  if a.length() == 0 {
    return 0U
  }
  match self.order {
    LittleEndian => a[0].to_uint() | (a[1].to_uint() << 8)
    BigEndian => (a[0].to_uint() << 8) | a[1].to_uint()
  }
}

///|
/// Read a uint24
fn Buf::uint24(self : Buf) -> UInt raise {
  let a = self.bytes(3)
  if a.length() == 0 {
    return 0U
  }
  match self.order {
    LittleEndian =>
      a[0].to_uint() | (a[1].to_uint() << 8) | (a[2].to_uint() << 16)
    BigEndian => (a[0].to_uint() << 16) | (a[1].to_uint() << 8) | a[2].to_uint()
  }
}

///|
/// Read a uint32
fn Buf::uint32(self : Buf) -> UInt raise {
  let a = self.bytes(4)
  if a.length() == 0 {
    return 0U
  }
  match self.order {
    LittleEndian =>
      a[0].to_uint() |
      (a[1].to_uint() << 8) |
      (a[2].to_uint() << 16) |
      (a[3].to_uint() << 24)
    BigEndian =>
      (a[0].to_uint() << 24) |
      (a[1].to_uint() << 16) |
      (a[2].to_uint() << 8) |
      a[3].to_uint()
  }
}

///|
/// Read a uint64
fn Buf::uint64(self : Buf) -> UInt64 raise {
  let a = self.bytes(8)
  if a.length() == 0 {
    return 0UL
  }
  match self.order {
    LittleEndian => {
      let low = a[0].to_uint64() |
        (a[1].to_uint64() << 8) |
        (a[2].to_uint64() << 16) |
        (a[3].to_uint64() << 24)
      let high = a[4].to_uint64() |
        (a[5].to_uint64() << 8) |
        (a[6].to_uint64() << 16) |
        (a[7].to_uint64() << 24)
      low | (high << 32)
    }
    BigEndian => {
      let high = (a[0].to_uint64() << 24) |
        (a[1].to_uint64() << 16) |
        (a[2].to_uint64() << 8) |
        a[3].to_uint64()
      let low = (a[4].to_uint64() << 24) |
        (a[5].to_uint64() << 16) |
        (a[6].to_uint64() << 8) |
        a[7].to_uint64()
      (high << 32) | low
    }
  }
}

///|
/// Read a varint (7 bits per byte, little endian, 0x80 bit means read another byte)
fn Buf::varint(self : Buf) -> (UInt64, UInt) {
  let mut c : UInt64 = 0UL
  let mut bits : UInt = 0U
  for i = 0; i < self.data.length(); i = i + 1 {
    let byte = self.data[i]
    c = c | ((byte.to_uint64() & 0x7FUL) << bits.reinterpret_as_int())
    bits = bits + 7U
    if (byte.to_uint() & 0x80U) == 0U {
      self.off += (i + 1).reinterpret_as_uint()
      self.data = self.data[i + 1:]
      return (c, bits)
    }
  }
  (0UL, 0U)
}

///|
/// Read unsigned int (just a varint)
fn Buf::uint(self : Buf) -> UInt64 {
  let (x, _) = self.varint()
  x
}

///|
/// Read signed int (sign-extended varint)
fn Buf::int(self : Buf) -> Int64 {
  let (ux, bits) = self.varint()
  let mut x = ux.reinterpret_as_int64()
  if (x & (1L << (bits.reinterpret_as_int() - 1))) != 0L {
    x = x | (-1L << bits.reinterpret_as_int())
  }
  x
}

///|
/// Read address-sized uint
fn Buf::addr(self : Buf) -> UInt64 raise {
  match self.format.addrsize() {
    1 => self.uint8().to_uint64()
    2 => self.uint16().to_uint64()
    4 => self.uint32().to_uint64()
    8 => self.uint64()
    _ => {
      ignore(self.error("unknown address size"))
      0UL
    }
  }
}

///|
/// Read unit length
fn Buf::unit_length(self : Buf) -> (Offset, Bool) raise {
  let mut length = self.uint32().reinterpret_as_int().to_int64()
  let mut dwarf64 = false
  if length == 0xffffffffL {
    dwarf64 = true
    length = self.uint64().reinterpret_as_int64()
  } else if length >= 0xfffffff0L {
    ignore(self.error("unit length has reserved value"))
  }
  (length.to_int().reinterpret_as_uint(), dwarf64)
}

///|
/// Set error
fn Buf::error(self : Buf, s : String) -> DecodeError {
  if self.err is Some(err) {
    return err
  } else {
    self.data = @slice.new()
    let err = DecodeError::new(self.name, self.off, s)
    self.err = Some(err)
    return err
  }
}

///|
/// Get remaining data length
fn Buf::length(self : Buf) -> Int {
  self.data.length()
}

///|
/// Get current offset
fn Buf::offset(self : Buf) -> Offset {
  self.off
}
