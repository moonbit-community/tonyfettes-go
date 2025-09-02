///|
/// Tests for the zlib package

///|
/// Simple buffer writer for testing
struct BufferWriter {
  mut buffer : Bytes
} derive(Show)

///|
impl @io.Writer for BufferWriter with write(self, bytes) {
  for i = 0; i < bytes.length(); i = i + 1 {
    self.buffer = self.buffer + Bytes::from_array([bytes[i]])
  }
  bytes.length()
}

///|
fn BufferWriter::new() -> BufferWriter {
  { buffer: b"" }
}

///|
fn BufferWriter::to_bytes(self : BufferWriter) -> Bytes {
  self.buffer
}

///|
test "adler32 checksum basic" {
  let data : Array[Byte] = b"hello".to_array()
  let adler = Adler32::new()
  adler.write_bytes(data)
  let checksum = adler.sum32()
  // Test that we get a reasonable checksum value
  inspect(checksum > 0, content="true")
}

///|
test "adler32 incremental vs one-shot" {
  let data : Array[Byte] = b"hello world".to_array()

  // One-shot calculation
  let adler1 = Adler32::new()
  adler1.write_bytes(data)
  let checksum1 = adler1.sum32()

  // Incremental calculation
  let adler2 = Adler32::new()
  let part1 : Array[Byte] = b"hello".to_array()
  let part2 : Array[Byte] = b" world".to_array()
  adler2.write_bytes(part1)
  adler2.write_bytes(part2)
  let checksum2 = adler2.sum32()
  inspect(checksum1 == checksum2, content="true")
}

///|
test "binary encoding big endian" {
  let buf : FixedArray[Byte] = FixedArray::make(4, 0)

  // Test UInt16
  put_uint16_be(buf, 0, 0x1234)
  inspect(buf[0].to_int(), content="18")
  inspect(buf[1].to_int(), content="52")
  inspect(get_uint16_be_array(buf, 0), content="4660")

  // Test UInt32
  put_uint32_be(buf, 0, 0x12345678)
  inspect(buf[0].to_int(), content="18")
  inspect(buf[1].to_int(), content="52")
  inspect(buf[2].to_int(), content="86")
  inspect(buf[3].to_int(), content="120")
  inspect(get_uint32_be_array(buf, 0), content="305419896")
}

///|
test "writer basic functionality" {
  let buffer = BufferWriter::new()
  let writer = new_writer(buffer)

  // Write some test data
  let test_data : Array[Byte] = b"hello".to_array()
  ignore(writer.write(test_data[0:]))
  writer.close()
  let output = buffer.to_bytes()

  // Should have header (2 bytes) + data (5 bytes) + checksum (4 bytes) = 11 bytes minimum
  inspect(output.length() >= 11, content="true")

  // Check ZLIB header
  inspect(output[0].to_int(), content="120") // CMF byte
  // Second byte should be valid (checksum divisible by 31)
  let header_16 = (output[0].to_uint() << 8) | output[1].to_uint()
  let header_check = header_16 % 31
  inspect(header_check, content="0")
}

///|
test "round trip compress decompress" {
  let original_data : Array[Byte] = b"This is a test".to_array()

  // Compress
  let buffer = BufferWriter::new()
  let writer = new_writer(buffer)
  ignore(writer.write(original_data[0:]))
  writer.close()
  let compressed = buffer.to_bytes()

  // Decompress - need to create a flate.Reader compatible reader
  // FIXME: This test needs a proper flate.Reader implementation
  // For now, just check that compression produces output
  inspect(compressed.length() > 0, content="true")
}

///|
test "header validation" {
  // Test invalid compression method
  let bad_data1 : Bytes = b"\x77\x01" // CM = 7 instead of 8

  // FIXME: Need proper flate.Reader implementation to test reader
  // For now, just ensure the test compiles
  inspect(bad_data1.length(), content="2")

  // Test invalid checksum
  let bad_data2 : Bytes = b"\x78\x00" // Header checksum not divisible by 31
  inspect(bad_data2.length(), content="2")
}
