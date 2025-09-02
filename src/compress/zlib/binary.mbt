///|
/// Binary encoding utilities for big-endian operations
/// ZLIB (RFC 1950) is big-endian, unlike GZIP (RFC 1952).

///|
/// Extract a big-endian UInt16 from a byte array at the given offset
pub fn get_uint16_be_array(data : FixedArray[Byte], offset : Int) -> UInt {
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  (b0 << 8) | b1
}

///|
/// Extract a big-endian UInt32 from a byte array at the given offset
pub fn get_uint32_be_array(data : FixedArray[Byte], offset : Int) -> UInt {
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
/// Extract a big-endian UInt16 from a byte view at the given offset
pub fn get_uint16_be(data : @bytes.View, offset : Int) -> UInt {
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  (b0 << 8) | b1
}

///|
/// Extract a big-endian UInt32 from a byte view at the given offset
pub fn get_uint32_be(data : @bytes.View, offset : Int) -> UInt {
  let b0 = data[offset].to_uint()
  let b1 = data[offset + 1].to_uint()
  let b2 = data[offset + 2].to_uint()
  let b3 = data[offset + 3].to_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
/// Write a big-endian UInt16 to a mutable byte buffer at the given offset
pub fn put_uint16_be(
  data : FixedArray[Byte],
  offset : Int,
  value : UInt,
) -> Unit {
  data[offset] = (value >> 8).to_byte()
  data[offset + 1] = value.to_byte()
}

///|
/// Write a big-endian UInt32 to a mutable byte buffer at the given offset
pub fn put_uint32_be(
  data : FixedArray[Byte],
  offset : Int,
  value : UInt,
) -> Unit {
  data[offset] = (value >> 24).to_byte()
  data[offset + 1] = (value >> 16).to_byte()
  data[offset + 2] = (value >> 8).to_byte()
  data[offset + 3] = value.to_byte()
}
