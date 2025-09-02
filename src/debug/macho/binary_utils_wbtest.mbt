///|
test "read_uint little endian" {
  let data : Bytes = "\x01\x02\x03\x04"
  let result = read_uint(data, 0, Little)
  assert_eq(result, 67305985_U)
}

///|
test "read_uint big endian" {
  let data : Bytes = "\x01\x02\x03\x04"
  let result = read_uint(data, 0, Big)
  assert_eq(result, 16909060_U)
}

///|
test "determine_byte_order" {
  assert_eq(determine_byte_order(Magic32), Some(Little))
  assert_eq(determine_byte_order(Magic64), Some(Little))
  assert_eq(determine_byte_order(0xfacefeed_U), Some(Big))
  assert_eq(determine_byte_order(0xcffaedfe_U), Some(Big))
  assert_eq(determine_byte_order(0x12345678_U), None)
}

///|
test "read_uint buffer overflow" {
  let data : Bytes = "12"
  try {
    let _ = read_uint(data, 0, Little)
    fail("Expected buffer overflow error")
  } catch {
    BufferOverflowError::ReadOverflow(
      offset~,
      length~,
      buffer_size~,
      operation~
    ) => {
      assert_eq(offset, 0)
      assert_eq(length, 4)
      assert_eq(buffer_size, 2)
      assert_eq(operation, "read_uint")
    }
    _ => fail("Expected ReadOverflow error")
  }
}

///|
test "read_bytes buffer overflow" {
  let data : Bytes = "hello"
  try {
    let _ = read_bytes(data, 0, 10)
    fail("Expected buffer overflow error")
  } catch {
    BufferOverflowError::ReadOverflow(
      offset~,
      length~,
      buffer_size~,
      operation~
    ) => {
      assert_eq(offset, 0)
      assert_eq(length, 10)
      assert_eq(buffer_size, 5)
      assert_eq(operation, "read_bytes")
    }
    _ => fail("Expected ReadOverflow error")
  }
}

///|
test "read_uint64 little endian" {
  let data : Bytes = "\x01\x02\x03\x04\x05\x06\x07\x08"
  let result = read_uint64(data, 0, Little)
  assert_eq(result, 578437695752307201_UL)
}

///|
test "read_uint64 big endian" {
  let data : Bytes = "\x01\x02\x03\x04\x05\x06\x07\x08"
  let result = read_uint64(data, 0, Big)
  assert_eq(result, 72623859790382856_UL)
}

///|
test "read_uint64 buffer overflow" {
  let data : Bytes = "1234567"
  try {
    let _ = read_uint64(data, 0, Little)
    fail("Expected buffer overflow error")
  } catch {
    BufferOverflowError::ReadOverflow(
      offset~,
      length~,
      buffer_size~,
      operation~
    ) => {
      assert_eq(offset, 0)
      assert_eq(length, 8)
      assert_eq(buffer_size, 7)
      assert_eq(operation, "read_uint64")
    }
    _ => fail("Expected ReadOverflow error")
  }
}

///|
test "Bytes contains" {
  let data : Bytes = "hello world"
  assert_true(data.contains(b'h'))
  assert_true(data.contains(b'o'))
  assert_true(data.contains(b' '))
  assert_false(data.contains(b'x'))
  assert_false(data.contains(b'z'))
}
