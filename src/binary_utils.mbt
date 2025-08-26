///| Binary utility functions for Mach-O parsing

///| These provide low-level binary data reading and parsing capabilities

///|
/// Extract a null-terminated C string from bytes
pub fn cstring(data : Bytes) -> String {
  let mut i = 0
  let len = data.length()
  while i < len && data[i] != 0 {
    i = i + 1
  }
  // Convert bytes to string up to null terminator
  let mut result = ""
  for j = 0; j < i; j = j + 1 {
    result = result + data[j].to_int().to_char().to_string()
  }
  result
}

///|
/// Extract a null-terminated C string from a fixed array of bytes (for section/segment names)
pub fn cstring_from_fixed_array(data : FixedArray[Byte]) -> String {
  let mut result = ""
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    let byte = data[i]
    if byte == 0 {
      break
    }
    result = result + byte.to_int().to_char().to_string()
  }
  result
}

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
/// Extract C string from fixed Int array (for compatibility)
pub fn cstring_from_fixed_int_array(data : FixedArray[Int]) -> String {
  let mut result = ""
  let len = data.length()
  for i = 0; i < len; i = i + 1 {
    let byte = data[i]
    if byte == 0 {
      break
    }
    result = result + byte.to_char().to_string()
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
