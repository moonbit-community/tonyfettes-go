///|
/// Whitebox tests for DeflateFast implementation

///|
/// Test DeflateFast creation
test "DeflateFast::new" {
  let df = DeflateFast::new()
  inspect(df.cur, content="65535")
  inspect(df.table.length(), content="16384")
  inspect(df.prev.length(), content="65535")
}

///|
/// Test DeflateFast with empty input
test "DeflateFast encode empty" {
  let df = DeflateFast::new()
  let dst = []
  df.encode(dst, @slice.new())
  inspect(dst.length(), content="0")
}

///|
/// Test DeflateFast with small input (below minimum)
test "DeflateFast encode small input" {
  let df = DeflateFast::new()
  let dst = []
  df.encode(dst, @slice.bytes("abc"))
  // Should emit literals for small input
  inspect(dst.length(), content="3")
}

///|
/// Test DeflateFast with larger input
test "DeflateFast encode larger input" {
  let df = DeflateFast::new()
  let dst = []

  // Create input with some repeated patterns
  let src = @slice.bytes(
    "Hello, World! This is a test string with some repeated patterns. Hello, World!",
  )
  df.encode(dst, src)
  // Should have some matches found
  inspect(dst.length() > 0, content="true")
  inspect(dst.length() <= src.length(), content="true") // Some compression or same size
}

///|
/// Test DeflateFast with highly repetitive input
test "DeflateFast encode repetitive input" {
  let df = DeflateFast::new()
  let dst = []
  let src = []

  // Create highly repetitive input
  for i = 0; i < 100; i = i + 1 {
    src.push(b'a')
    src.push(b'b')
    src.push(b'c')
    src.push(b'd')
  }
  df.encode(dst, @slice.bytes(@bytes.from_array(src)))
  // Should find many matches
  inspect(dst.length() > 0, content="true")
  inspect(dst.length() <= src.length(), content="true") // Should compress well
}

///|
/// Test DeflateFast reset functionality
test "DeflateFast reset" {
  let df = DeflateFast::new()
  let dst = []
  let mut src = @slice.new()
  for i = 0; i < 20; i = i + 1 {
    src = src.append(b'x')
  }
  ignore(df.encode(dst, src))

  // Reset should clear previous data
  df.reset()
  inspect(df.prev.length(), content="0")
  inspect(df.cur > MaxMatchOffset, content="true")
}

///|
/// Test emit_literal function
test "emit_literal" {
  let dst = []
  let lit = @slice.bytes("Hi")
  emit_literal(dst, lit)
  inspect(dst.length(), content="2")
}

///|
/// Test load32 function
test "load32" {
  let bytes : @slice.Slice[Byte] = @slice.fixedarray([0x01, 0x02, 0x03, 0x04])
  let result = load32(bytes, 0)
  // Little endian: 0x04030201
  inspect(result, content="67305985")
}

///|
/// Test load64 function
test "load64" {
  let bytes : @slice.Slice[Byte] = @slice.fixedarray([
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  ])
  let result = load64(bytes, 0)
  // Little endian: 0x0807060504030201
  inspect(result, content="578437695752307201")
}

///|
/// Test hash function
test "hash function" {
  let h1 = hash(0x12345678)
  let h2 = hash(0x12345679)

  // Different inputs should produce different hashes
  inspect(h1 != h2, content="true")

  // Hash should be within table range
  inspect(h1 < TableSize.reinterpret_as_uint(), content="true")
  inspect(h2 < TableSize.reinterpret_as_uint(), content="true")
}

///|
/// Test match_len function with various scenarios
test "DeflateFast match_len" {
  let df = DeflateFast::new()

  // Add test data
  let src = @slice.bytes("abcdefghijklmnopqrstuvwxyz")

  // Test match within current block
  let match_len1 = df.match_len(0, 0, src)
  inspect(match_len1 >= 0, content="true")

  // Test no match scenario
  let match_len2 = df.match_len(0, 10, src)
  inspect(match_len2 >= 0, content="true")
}

///|
/// Test DeflateFast with cross-block matching
test "DeflateFast cross block matching" {
  let df = DeflateFast::new()

  // First block
  let src1 = @slice.bytes("pattern")
  let dst1 = []
  df.encode(dst1, src1)

  // Second block with same pattern - should find matches in previous block
  let src2 = @slice.bytes("pattern")
  let dst2 = []
  df.encode(dst2, src2)
  inspect(dst2.length() > dst1.length(), content="false")
}

///|
/// Test TableEntry structure
test "TableEntry" {
  let entry = TableEntry::{ val: 0x12345678, offset: 100 }
  inspect(entry.val, content="305419896")
  inspect(entry.offset, content="100")
}

///|
/// Test buffer reset constant
test "BufferReset constant" {
  inspect(BufferReset > 0, content="true")
  inspect(BufferReset == 2147483647 - MaxStoreBlockSize * 2, content="true")
}

///|
/// Test table size constants
test "Table constants" {
  inspect(TableBits, content="14")
  inspect(TableSize, content="16384")
  inspect(TableMask, content="16383")
  inspect(TableShift, content="18")
}

///|
/// Test shift offsets functionality
test "DeflateFast shift_offsets" {
  let df = DeflateFast::new()

  // Set up some table entries
  df.table[0] = TableEntry::{ val: 0x12345678, offset: 1000000 }
  df.table[100] = TableEntry::{ val: 0xABCDEF00, offset: 2000000 }
  df.cur = BufferReset + 1000

  // This should trigger shift_offsets
  df.shift_offsets()

  // After shifting, cur should be reset
  inspect(df.cur, content="32769") // MaxMatchOffset + 1
}

///|
/// Test DeflateFast with exact minimum input size
test "DeflateFast minimum input size" {
  let df = DeflateFast::new()
  let dst = []
  let mut src = @slice.new()

  // Create input exactly at minimum size
  for i = 0; i < MinNonLiteralBlockSize; i = i + 1 {
    src = src.append((i % 256).to_byte())
  }
  df.encode(dst, src)
  inspect(dst.length() >= MinNonLiteralBlockSize, content="true")
}
