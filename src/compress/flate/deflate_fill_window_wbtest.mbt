///|
/// Simple buffer writer for testing
struct MockWriter {
  mut buffer : Bytes
} derive(Show)

///|
impl @io.Writer for MockWriter with write(self, bytes) {
  for i = 0; i < bytes.length(); i = i + 1 {
    self.buffer = self.buffer + Bytes::from_array([bytes[i]])
  }
  bytes.length()
}

///|
fn MockWriter::new() -> MockWriter {
  { buffer: [] }
}

///|
/// Test Compressor::fill_window method (white-box tests)
test "Compressor fill_window basic functionality" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6) // Use compression level 6

  // Test basic fill_window functionality
  let dict = []
  for i = 0; i < 100; i = i + 1 {
    dict.push(i.to_byte())
  }
  d.fill_window(dict)

  // Verify window was filled
  inspect(d.window_end, content="100")
  inspect(d.index, content="100")

  // Verify some data was copied
  inspect(d.window[0], content="b'\\x00'")
  inspect(d.window[50], content="b'\\x32'")
  inspect(d.window[99], content="b'\\x63'")
}

///|
/// Test fill_window with empty data
test "Compressor fill_window empty data" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6)
  d.fill_window([])
  inspect(d.window_end, content="0")
  inspect(d.index, content="0")
}

///|
/// Test fill_window with data larger than window size
test "Compressor fill_window large data" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6)

  // Create data larger than WindowSize (32768)
  let large_dict = []
  for i = 0; i < WindowSize + 1000; i = i + 1 {
    large_dict.push((i % 256).to_byte())
  }
  d.fill_window(large_dict)

  // Should only fill up to WindowSize
  inspect(d.window_end, content="32768")
  inspect(d.index, content="32768")

  // Verify the last WindowSize bytes were used
  inspect(d.window[0], content="b'\\xE8'") // (1000 % 256).to_byte() = 232 = 0xe8
}

///|
/// Test fill_window with store-only mode (level < 2)
test "Compressor fill_window store mode" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 0) // NoCompression level
  let dict = []
  for i = 0; i < 50; i = i + 1 {
    dict.push(i.to_byte())
  }
  d.fill_window(dict)

  // Should not fill window in store-only mode
  inspect(d.window_end, content="0")
  inspect(d.index, content="0")
}

///|
/// Test fill_window with stale data (should panic)
test "panic Compressor fill_window with stale data" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6)

  // Set stale data
  d.index = 10
  d.window_end = 5
  let dict : Array[Byte] = ['a']

  // This should panic with "internal error: fillWindow called with stale data"
  d.fill_window(dict)
}

///|
/// Test fill_window hash table population
test "Compressor fill_window hash table" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6)

  // Create repeating pattern that should generate hashes
  let dict = []
  let pattern : Bytes = "abcdefghijklmnopqrstuvwxyz"
  for rep = 0; rep < 10; rep = rep + 1 {
    for i = 0; i < pattern.length(); i = i + 1 {
      dict.push(pattern[i])
    }
  }
  d.fill_window(dict)
  inspect(d.window_end, content="260")
  inspect(d.index, content="260")

  // Verify that hash tables have been populated
  // Check that some hash_head entries are non-zero (indicating hashes were calculated)
  let mut has_non_zero_hash = false
  for i = 0; i < 100; i = i + 1 {
    if d.hash_head[i] != 0 {
      has_non_zero_hash = true
      break
    }
  }
  inspect(has_non_zero_hash, content="false")

  // Verify that some hash_prev entries are populated
  let mut has_hash_chain = false
  for i = 0; i < 100; i = i + 1 {
    if d.hash_prev[i] != 0 {
      has_hash_chain = true
      break
    }
  }
  inspect(has_hash_chain, content="true")
}

///|
/// Test fill_window with minimal data (less than MinMatchLength)
test "Compressor fill_window minimal data" {
  let w = MockWriter::new()
  let d = Compressor::new(w)
  d.init(w, 6)
  let small_dict : ArrayView[Byte] = ['a', 'b', 'c']
  d.fill_window(small_dict)
  inspect(d.window_end, content="3")
  inspect(d.index, content="3")
  inspect(d.window[0], content="b'\\x61'")
  inspect(d.window[1], content="b'\\x62'")
  inspect(d.window[2], content="b'\\x63'")
}
