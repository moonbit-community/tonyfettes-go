///| Binary utility functions for Mach-O parsing

///| These provide low-level binary data reading and parsing capabilities

///|
/// Read a UInt from bytes at offset with given byte order
pub fn read_uint(
  data : Bytes,
  offset : Int,
  byte_order : ByteOrder,
) -> UInt raise {
  if offset + 4 > data.length() {
    raise BufferOverflowError::ReadOverflow(
      offset~,
      length=4,
      buffer_size=data.length(),
      operation="read_uint",
    )
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
) -> UInt64 raise {
  if offset + 8 > data.length() {
    raise BufferOverflowError::ReadOverflow(
      offset~,
      length=8,
      buffer_size=data.length(),
      operation="read_uint64",
    )
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
pub fn read_bytes(data : Bytes, offset : Int, length : Int) -> Bytes raise {
  if offset + length > data.length() {
    raise BufferOverflowError::ReadOverflow(
      offset~,
      length~,
      buffer_size=data.length(),
      operation="read_bytes",
    )
  }
  [..data[offset:offset + length]]
}

///|
/// Copy bytes from source to fixed array (simplified approach using Int array)
pub fn copy_to_fixed_array(
  data : Bytes,
  offset : Int,
  size : Int,
) -> FixedArray[Int] raise {
  if offset + size > data.length() {
    raise BufferOverflowError::ReadOverflow(
      offset~,
      length=size,
      buffer_size=data.length(),
      operation="copy_to_fixed_array",
    )
  }
  let result = FixedArray::make(size, 0)
  for i = 0; i < size; i = i + 1 {
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
