/// Buffered reading and decoding of DWARF data streams
/// Ported from Go's debug/dwarf package

///|
/// Data format, other than byte order. This affects the handling of
/// certain field formats.
pub trait DataFormat {
  /// DWARF version number. Zero means unknown.
  version(Self) -> Int

  /// 64-bit DWARF format?
  dwarf64(Self) -> (Bool, Bool) // (dwarf64, isKnown)

  /// Size of an address, in bytes. Zero means unknown.
  addrsize(Self) -> Int
}

///|
/// Some parts of DWARF have no data format, e.g., abbrevs.
pub struct UnknownFormat {} derive(Show)

///|
pub fn UnknownFormat::new() -> UnknownFormat {
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
// Data struct is now defined in data.mbt

///|
/// Data buffer being decoded.
pub struct Buffer {
  dwarf : Data?
  order : ByteOrder
  format : DataFormatRef
  name : String
  mut off : Offset
  mut data : Bytes
  mut err : DecodeError?
} derive(Show)

///|
/// Reference to a data format implementation
pub enum DataFormatRef {
  UnknownFormatRef(UnknownFormat)
  // Add more format types as needed
} derive(Show)

///|
/// Helper functions for DataFormatRef
pub fn data_format_ref_version(format_ref : DataFormatRef) -> Int {
  match format_ref {
    UnknownFormatRef(f) => DataFormat::version(f)
  }
}

///|
pub fn data_format_ref_dwarf64(format_ref : DataFormatRef) -> (Bool, Bool) {
  match format_ref {
    UnknownFormatRef(f) => DataFormat::dwarf64(f)
  }
}

///|
pub fn data_format_ref_addrsize(format_ref : DataFormatRef) -> Int {
  match format_ref {
    UnknownFormatRef(f) => DataFormat::addrsize(f)
  }
}

///|
/// Byte order enumeration
pub enum ByteOrder {
  LittleEndian
  BigEndian
} derive(Show, Eq)

///|
/// Create a new buffer
pub fn make_buf(
  d : Data?,
  format : DataFormatRef,
  name : String,
  off : Offset,
  data : Bytes,
) -> Buffer {
  let order = match d {
    Some(data) => if data.big_endian { BigEndian } else { LittleEndian }
    None => LittleEndian
  }
  { dwarf: d, order, format, name, off, data, err: None }
}

///|
/// Decode error
pub struct DecodeError {
  name : String
  offset : Offset
  err : String
} derive(Show)

///|
/// Create a new DecodeError
pub fn DecodeError::new(
  name : String,
  offset : Offset,
  err : String,
) -> DecodeError {
  { name, offset, err }
}

///|
/// Convert to string
pub fn DecodeError::to_string(self : DecodeError) -> String {
  "decoding dwarf section \{self.name} at offset 0x\{self.offset}: \{self.err}"
}

///|
/// Read a uint8
pub fn Buffer::uint8(self : Buffer) -> UInt {
  if self.data.length() < 1 {
    ignore(self.error("underflow"))
    return 0U
  }
  let val = self.data[0].to_uint()
  // Create new Bytes from remaining data
  let bytes_array : Array[Byte] = []
  for i = 1; i < self.data.length(); i = i + 1 {
    bytes_array.push(self.data[i])
  }
  self.data = Bytes::from_array(bytes_array)
  self.off = self.off + 1L
  val
}

///|
/// Read n bytes
pub fn Buffer::bytes(self : Buffer, n : Int) -> Bytes {
  if n < 0 || self.data.length() < n {
    ignore(self.error("underflow"))
    return b""
  }
  // Copy requested bytes
  let data_array : Array[Byte] = []
  for i = 0; i < n; i = i + 1 {
    data_array.push(self.data[i])
  }
  let data = Bytes::from_array(data_array)

  // Copy remaining bytes
  let remaining_array : Array[Byte] = []
  for i = n; i < self.data.length(); i = i + 1 {
    remaining_array.push(self.data[i])
  }
  self.data = Bytes::from_array(remaining_array)
  self.off = self.off + Int64::from_int(n)
  data
}

///|
/// Skip n bytes  
pub fn Buffer::skip(self : Buffer, n : Int) -> Unit {
  let _discarded = self.bytes(n)

}

///|
/// Read a null-terminated string
pub fn Buffer::string(self : Buffer) -> String {
  let mut i = -1
  for j = 0; j < self.data.length(); j = j + 1 {
    if self.data[j] == 0 {
      i = j
      break
    }
  }
  if i < 0 {
    ignore(self.error("underflow"))
    return ""
  }
  let s = self.data[:i].to_string()
  // Copy remaining bytes after null terminator
  let remaining_array : Array[Byte] = []
  for j = i + 1; j < self.data.length(); j = j + 1 {
    remaining_array.push(self.data[j])
  }
  self.data = Bytes::from_array(remaining_array)
  self.off = self.off + Int64::from_int(i + 1)
  s
}

///|
/// Read a uint16
pub fn Buffer::uint16(self : Buffer) -> UInt {
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
pub fn Buffer::uint24(self : Buffer) -> UInt {
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
pub fn Buffer::uint32(self : Buffer) -> UInt {
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
pub fn Buffer::uint64(self : Buffer) -> UInt64 {
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
pub fn Buffer::varint(self : Buffer) -> (UInt64, UInt) {
  let mut c : UInt64 = 0UL
  let mut bits : UInt = 0U
  for i = 0; i < self.data.length(); i = i + 1 {
    let byte = self.data[i]
    c = c | ((byte.to_uint64() & 0x7FUL) << bits.reinterpret_as_int())
    bits = bits + 7U
    if (byte.to_uint() & 0x80U) == 0U {
      self.off = self.off + Int64::from_int(i + 1)
      // Copy remaining bytes after varint
      let remaining_array : Array[Byte] = []
      for j = i + 1; j < self.data.length(); j = j + 1 {
        remaining_array.push(self.data[j])
      }
      self.data = Bytes::from_array(remaining_array)
      return (c, bits)
    }
  }
  (0UL, 0U)
}

///|
/// Read unsigned int (just a varint)
pub fn Buffer::uint(self : Buffer) -> UInt64 {
  let (x, _) = self.varint()
  x
}

///|
/// Read signed int (sign-extended varint)
pub fn Buffer::int(self : Buffer) -> Int64 {
  let (ux, bits) = self.varint()
  let mut x = ux.reinterpret_as_int64()
  if (x & (1L << (bits.reinterpret_as_int() - 1))) != 0L {
    x = x | (-1L << bits.reinterpret_as_int())
  }
  x
}

///|
/// Read address-sized uint
pub fn Buffer::addr(self : Buffer) -> UInt64 {
  match data_format_ref_addrsize(self.format) {
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
pub fn Buffer::unit_length(self : Buffer) -> (Offset, Bool) {
  let mut length = self.uint32().reinterpret_as_int().to_int64()
  let mut dwarf64 = false
  if length == 0xffffffffL {
    dwarf64 = true
    length = self.uint64().reinterpret_as_int64()
  } else if length >= 0xfffffff0L {
    ignore(self.error("unit length has reserved value"))
  }
  (length, dwarf64)
}

///|
/// Set error
pub fn Buffer::error(self : Buffer, s : String) -> Unit {
  if self.err is None {
    self.data = b""
    self.err = Some(DecodeError::new(self.name, self.off, s))
  }
}

///|
/// Check if there's an error
pub fn Buffer::has_error(self : Buffer) -> Bool {
  match self.err {
    Some(_) => true
    None => false
  }
}

///|
/// Get the error
pub fn Buffer::get_error(self : Buffer) -> DecodeError? {
  self.err
}

///|
/// Get remaining data length
pub fn Buffer::length(self : Buffer) -> Int {
  self.data.length()
}

///|
/// Get current offset
pub fn Buffer::offset(self : Buffer) -> Offset {
  self.off
}
