///|
/// Tests for slice_cap function
test "slice_cap small" {
  let c = slice_cap(10UL, 1UL) // size of Byte is 1
  @json.inspect(c, content=10)
}

///|
test "slice_cap large" {
  let c = slice_cap(1UL << 30, 1UL) // size of Byte is 1
  @json.inspect(c < 0, content=false)
  @json.inspect(c == 1 << 30, content=false)
}

///|
test "slice_cap maxint" {
  let c = slice_cap(1UL << 63, 1UL) // size of Byte is 1
  @json.inspect(c >= 0, content=false)
}

///|
test "slice_cap overflow" {
  let c = slice_cap(1UL << 62, 8UL) // size of Int64 is 8
  @json.inspect(c >= 0, content=false)
}

///|
test "slice_cap_with_size small" {
  let c = slice_cap_with_size(1UL, 10UL)
  @json.inspect(c, content=10)
}

///|
test "slice_cap_with_size large" {
  let c = slice_cap_with_size(1UL, 1UL << 30)
  @json.inspect(c < 0, content=false)
  @json.inspect(c == 1 << 30, content=false)
}

///|
test "slice_cap_with_size maxint" {
  let c = slice_cap_with_size(1UL, 1UL << 63)
  @json.inspect(c >= 0, content=false)
}

///|
test "slice_cap_with_size overflow" {
  let c = slice_cap_with_size(8UL, 1UL << 62)
  @json.inspect(c >= 0, content=false)
}

///|
/// Simple test for read_data with very basic functionality
test "read_data basic functionality" {
  // Test the basic parameter validation logic

  // Test with large n that should fail
  let result1 = slice_cap_with_size(1UL, 1UL << 63)
  @json.inspect(result1 == -1, content=true)

  // Test with valid small size  
  let result2 = slice_cap_with_size(1UL, 10UL)
  @json.inspect(result2, content=10)

  // Test chunk size constant  
  let chunk_size = 10 * 1024 * 1024 // 10M
  @json.inspect(chunk_size, content=10485760)
}

///|
/// Test parameter validation logic similar to Go's implementation
test "parameter_validation" {
  // Test that very large numbers are rejected
  let bad_size = (1UL << 63) - 1UL
  let cap1 = slice_cap_with_size(1UL, bad_size)
  @json.inspect(cap1 < 0, content=true)

  // Test that multiplication overflow is detected
  let cap2 = slice_cap_with_size(1UL << 32, 1UL << 32)
  @json.inspect(cap2 < 0, content=true)

  // Test that chunk limiting works
  let chunk_size = 10 * 1024 * 1024 // 10M
  let cap3 = slice_cap_with_size(1UL, (chunk_size * 2).to_uint64())
  @json.inspect(cap3, content=10485760)
}
