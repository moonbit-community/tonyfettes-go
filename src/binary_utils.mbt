///| Binary utility functions for Mach-O parsing

///| These provide low-level binary data reading and parsing capabilities

///|
/// Read a UInt from bytes at offset with given byte order
pub fn read_uint(data : Bytes, offset : Int, byte_order : ByteOrder) -> UInt {
  if offset + 4 > data.length() {
    abort("Buffer overflow reading UInt")
  }
  match byte_order {
    Little =>
      data[offset].to_uint() |
      (data[offset + 1].to_uint() << 8) |
      (data[offset + 2].to_uint() << 16) |
      (data[offset + 3].to_uint() << 24)
    Big =>
      (data[offset].to_uint() << 24) |
      (data[offset + 1].to_uint() << 16) |
      (data[offset + 2].to_uint() << 8) |
      data[offset + 3].to_uint()
  }
}

///|
/// Read a UInt64 from bytes at offset with given byte order
pub fn read_uint64(
  data : Bytes,
  offset : Int,
  byte_order : ByteOrder,
) -> UInt64 {
  if offset + 8 > data.length() {
    abort("Buffer overflow reading UInt64")
  }
  let low = read_uint(data, offset, byte_order).to_uint64()
  let high = read_uint(data, offset + 4, byte_order).to_uint64()
  match byte_order {
    Little => low | (high << 32)
    Big => high | (low << 32)
  }
}

///|
/// Create new bytes as a subset of another byte array - simulate a slice
pub fn read_bytes(data : Bytes, offset : Int, length : Int) -> Bytes {
  if offset + length > data.length() {
    abort("Buffer overflow reading bytes")
  }
  // Create a bytes array from the slice by converting to string and back
  // This is not the most efficient but works with available APIs
  let mut result_str = ""
  for i = 0; i < length; i = i + 1 {
    result_str = result_str + data[offset + i].to_int().to_char().to_string()
  }
  result_str.to_bytes()
}

///|
/// Copy bytes from source to fixed array (simplified approach using Int array)
pub fn copy_to_fixed_array(
  data : Bytes,
  offset : Int,
  size : Int,
) -> FixedArray[Int] {
  let result = FixedArray::make(size, 0)
  for i = 0; i < size && offset + i < data.length(); i = i + 1 {
    result[i] = data[offset + i].to_int()
  }
  result
}

///|
/// Determine byte order from magic number
pub fn determine_byte_order(magic : UInt) -> ByteOrder? {
  if magic == magic_32 || magic == magic_64 {
    Some(Little)
  } else if magic == 0xfacefeed_U || magic == 0xcffaedfe_U { // Big endian versions
    Some(Big)
  } else {
    None
  }
}

///|
/// Check if magic number is valid
pub fn is_valid_magic(magic : UInt) -> Bool {
  magic == magic_32 ||
  magic == magic_64 ||
  magic == 0xfacefeed_U ||
  magic == 0xcffaedfe_U ||
  magic == magic_fat
}

///|
fn Bytes::contains(self : Bytes, byte : Byte) -> Bool {
  loop self[:] {
    [b, ..] if b == byte => true
    [_, .. rest] => continue rest
    [] => false
  }
}
