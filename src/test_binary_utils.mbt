///|
test "read_uint little endian" {
  let data = "\u{01}\u{02}\u{03}\u{04}".to_bytes()
  let result = read_uint(data, 0, Little)
  assert_eq(result, 67305985_U) // 0x04030201
}

///|
test "read_uint big endian" {
  let data = "\u{01}\u{02}\u{03}\u{04}".to_bytes()
  let result = read_uint(data, 0, Big)
  assert_eq(result, 16909060_U) // 0x01020304
}

///|
test "copy_to_fixed_array" {
  let data = "hello world".to_bytes()
  let arr = copy_to_fixed_array(data, 6, 5) // "world"
  assert_eq(arr.length(), 5)
  assert_eq(arr[0], 119) // 'w'
  assert_eq(arr[1], 111) // 'o'
  assert_eq(arr[2], 114) // 'r'
  assert_eq(arr[3], 108) // 'l'
  assert_eq(arr[4], 100) // 'd'
}

///|
test "determine_byte_order" {
  assert_eq(determine_byte_order(magic_32), Some(Little))
  assert_eq(determine_byte_order(magic_64), Some(Little))
  assert_eq(determine_byte_order(0xfacefeed_U), Some(Big))
  assert_eq(determine_byte_order(0xcffaedfe_U), Some(Big))
  assert_eq(determine_byte_order(0x12345678_U), None)
}

///|
test "is_valid_magic" {
  assert_true(is_valid_magic(magic_32))
  assert_true(is_valid_magic(magic_64))
  assert_true(is_valid_magic(magic_fat))
  assert_true(is_valid_magic(0xfacefeed_U))
  assert_true(is_valid_magic(0xcffaedfe_U))
  assert_false(is_valid_magic(0x12345678_U))
}

///|
test "read_uint buffer overflow" {
  let data = "12".to_bytes() // Only 2 bytes
  try {
    let _ = read_uint(data, 0, Little) // Needs 4 bytes
    fail("Expected buffer overflow error")
  } catch {
    BufferOverflowError::ReadOverflow(offset~, length~, buffer_size~, operation~) => {
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
  let data = "hello".to_bytes() // Only 5 bytes
  try {
    let _ = read_bytes(data, 0, 10) // Try to read 10 bytes
    fail("Expected buffer overflow error")
  } catch {
    BufferOverflowError::ReadOverflow(offset~, length~, buffer_size~, operation~) => {
      assert_eq(offset, 0)
      assert_eq(length, 10)
      assert_eq(buffer_size, 5)
      assert_eq(operation, "read_bytes")
    }
    _ => fail("Expected ReadOverflow error")
  }
}
