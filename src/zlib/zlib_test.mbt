///|
/// Tests for the zlib package

///|
test "adler32 checksum basic" {
  let data = [b'h', b'e', b'l', b'l', b'o']
  let checksum = @zlib.checksum_array(data)
  // Test that we get a reasonable checksum value
  assert_true(checksum > 0)
}

///|
test "adler32 incremental vs one-shot" {
  let data = [b'h', b'e', b'l', b'l', b'o', b' ', b'w', b'o', b'r', b'l', b'd']

  // One-shot calculation
  let checksum1 = @zlib.checksum_array(data)

  // Incremental calculation
  let adler = @zlib.Adler32::new()
  let part1 = [b'h', b'e', b'l', b'l', b'o']
  let part2 = [b' ', b'w', b'o', b'r', b'l', b'd']
  adler.write_array(part1) // "hello"
  adler.write_array(part2) // " world"
  let checksum2 = adler.sum32()
  assert_eq(checksum1, checksum2)
}

///|
test "binary encoding big endian" {
  let buf : FixedArray[Byte] = FixedArray::make(4, 0)

  // Test UInt16
  @zlib.put_uint16_be(buf, 0, 0x1234)
  assert_eq(buf[0], 0x12)
  assert_eq(buf[1], 0x34)
  assert_eq(@zlib.get_uint16_be_array(buf, 0), 0x1234)

  // Test UInt32
  @zlib.put_uint32_be(buf, 0, 0x12345678)
  assert_eq(buf[0], 0x12)
  assert_eq(buf[1], 0x34)
  assert_eq(buf[2], 0x56)
  assert_eq(buf[3], 0x78)
  assert_eq(@zlib.get_uint32_be_array(buf, 0), 0x12345678)
}

///|
test "writer basic functionality" {
  let writer = @zlib.Writer::new()

  // Write some test data
  let test_data : Bytes = "hello"
  writer.write(test_data)
  writer.close()
  let output = writer.to_bytes()

  // Should have header (2 bytes) + data (5 bytes) + checksum (4 bytes) = 11 bytes minimum
  assert_true(output.length() >= 11)

  // Check ZLIB header
  assert_eq(output[0], b'\x78') // CMF byte
  // Second byte should be valid (checksum divisible by 31)
  let header_check = ((output[0].to_uint() << 8) | output[1].to_uint()) % 31
  assert_eq(header_check, 0)
}

///|
test "reader basic functionality" {
  // Create a minimal valid ZLIB stream
  let writer = @zlib.Writer::new()
  let test_data : Bytes = "hello"
  writer.write(test_data)
  writer.close()
  let zlib_data = writer.to_bytes()

  // Now try to read it back
  let reader = @zlib.Reader::new(zlib_data)
  let buf : FixedArray[Byte] = FixedArray::make(10, 0)
  try {
    let n = reader.read(buf)
    assert_eq(n, 5) // Should read the 5 bytes we wrote

    // Check the first 5 bytes match
    for i = 0; i < 5; i = i + 1 {
      assert_eq(buf[i], test_data[i])
    }
  } catch {
    _ => fail("reader should not fail on valid data")
  }
}

///|
test "round trip compress decompress" {
  let original_data : Bytes = "This is a test"

  // Compress
  let writer = @zlib.Writer::new()
  writer.write(original_data)
  writer.close()
  let compressed = writer.to_bytes()

  // Decompress
  let reader = @zlib.Reader::new(compressed)
  let buf : FixedArray[Byte] = FixedArray::make(20, 0)
  try {
    let n = reader.read(buf)
    assert_eq(n, original_data.length())

    // Check all bytes match
    for i = 0; i < n; i = i + 1 {
      assert_eq(buf[i], original_data[i])
    }
  } catch {
    _ => fail("round trip should work")
  }
}

///|
test "writer with dictionary" {
  let dict : Bytes = "dict"
  let writer = @zlib.Writer::new_dict(dict)
  let test_data : Bytes = "hello"
  writer.write(test_data)
  writer.close()
  let output = writer.to_bytes()

  // Should have header (2 bytes) + dict checksum (4 bytes) + data (5 bytes) + checksum (4 bytes) = 15 bytes minimum
  assert_true(output.length() >= 15)

  // Check FDICT flag is set (bit 5 of second header byte)
  assert_eq(output[1].to_uint() & 0x20, 0x20)
}

///|
test "header validation" {
  // Test invalid compression method
  let bad_data1 : Bytes = "\x77\x01" // CM = 7 instead of 8
  let reader1 = @zlib.Reader::new(bad_data1)
  let buf : FixedArray[Byte] = FixedArray::make(1, 0)
  try {
    let _ = reader1.read(buf)
    fail("should reject invalid compression method")
  } catch {
    @zlib.HeaderError(_) => () // Expected
    _ => fail("wrong error type")
  }

  // Test invalid checksum
  let bad_data2 : Bytes = b"\x78\x00" // Header checksum not divisible by 31
  let reader2 = @zlib.Reader::new(bad_data2)
  try {
    let _ = reader2.read(buf)
    fail("should reject invalid header checksum")
  } catch {
    @zlib.HeaderError(_) => () // Expected
    _ => fail("wrong error type")
  }
}
