///|
/// Test NewWriterDict functionality (white-box tests)

///|
/// Simple buffer writer for testing
struct TestWriter {
  buffer : Ref[Array[Byte]]
} derive(Show)

///|
impl @io.Writer for TestWriter with write(self, bytes) {
  for i = 0; i < bytes.length(); i = i + 1 {
    self.buffer.val.push(bytes[i])
  }
  bytes.length()
}

///|
fn TestWriter::new() -> TestWriter {
  { buffer: Ref::new(Array::new()) }
}

///|
fn TestWriter::to_bytes(self : TestWriter) -> Array[Byte] {
  self.buffer.val
}

///|
test "new_writer_dict basic functionality" {
  let w = TestWriter::new()
  let dict : Array[Byte] = Array::new()
  for i = 0; i < 10; i = i + 1 {
    dict.push(i.to_byte())
  }
  let writer = new_writer_dict(w, 6, dict)

  // Verify that dictionary was stored
  inspect(writer.dict.length(), content="10")
  inspect(writer.dict[0], content="b'\\x00'")
  inspect(writer.dict[9], content="b'\\x09'")

  // Verify that compressor window was filled
  inspect(writer.d.window_end, content="10")
  inspect(writer.d.index, content="10")
}

///|
test "new_writer_dict empty dictionary" {
  let w = TestWriter::new()
  let empty_dict : Array[Byte] = Array::new()
  let writer = new_writer_dict(w, 6, empty_dict)

  // Verify empty dictionary handling
  inspect(writer.dict.length(), content="0")
  inspect(writer.d.window_end, content="0")
  inspect(writer.d.index, content="0")
}

///|
test "new_writer_dict large dictionary" {
  let w = TestWriter::new()
  let large_dict : Array[Byte] = Array::new()
  for i = 0; i < WindowSize + 100; i = i + 1 {
    large_dict.push((i % 256).to_byte())
  }
  let writer = new_writer_dict(w, 6, large_dict)

  // Verify dictionary was stored (entire dictionary)
  inspect(writer.dict.length(), content="32868")

  // Verify that compressor window was filled (truncated to WindowSize)
  inspect(writer.d.window_end, content="32768")
  inspect(writer.d.index, content="32768")
}

///|
test "new_writer_dict different compression levels" {
  let w1 = TestWriter::new()
  let w2 = TestWriter::new()
  let dict : Array[Byte] = Array::new()
  for i = 0; i < 20; i = i + 1 {
    dict.push(i.to_byte())
  }

  // Test with store-only mode (level 0)
  let writer1 = new_writer_dict(w1, 0, dict)
  inspect(writer1.dict.length(), content="20")
  inspect(writer1.d.window_end, content="0") // Store mode doesn't fill window

  // Test with compression mode (level 6)
  let writer2 = new_writer_dict(w2, 6, dict)
  inspect(writer2.dict.length(), content="20")
  inspect(writer2.d.window_end, content="20") // Compression mode fills window
}

///|
test "DictWriter functionality" {
  let w = TestWriter::new()
  let dict_writer = DictWriter::new(w)
  let test_data : Bytes = "hello world"
  ignore(dict_writer.write(test_data))

  // Verify data was written through to underlying writer
  inspect(w.buffer.val.length(), content="11")
  inspect(w.buffer.val[0], content="b'\\x68'")
  inspect(w.buffer.val[10], content="b'\\x64'")
}

///|
test "Writer reset with dictionary" {
  let w1 = TestWriter::new()
  let w2 = TestWriter::new()
  let dict : Array[Byte] = Array::new()
  for i = 0; i < 15; i = i + 1 {
    dict.push((i + 97).to_byte()) // 'a' to 'o'
  }

  // Create writer with dictionary
  let writer = new_writer_dict(w1, 6, dict)

  // Verify initial state
  inspect(writer.dict.length(), content="15")
  inspect(writer.d.window_end, content="15")

  // Reset with new writer (should preserve dictionary)
  writer.reset(w2)

  // Verify dictionary was preserved and window refilled
  inspect(writer.dict.length(), content="15")
  inspect(writer.d.window_end, content="15")
  inspect(writer.d.index, content="15")
}

///|
test "Writer reset without dictionary" {
  let w1 = TestWriter::new()
  let w2 = TestWriter::new()

  // Create writer without dictionary
  let writer = new_writer(w1, 6)

  // Verify initial state
  inspect(writer.dict.length(), content="0")
  inspect(writer.d.window_end, content="0")

  // Reset with new writer
  writer.reset(w2)

  // Verify no dictionary and clean state
  inspect(writer.dict.length(), content="0")
  inspect(writer.d.window_end, content="0")
  inspect(writer.d.index, content="0")
}

///|
test "Compressor reset functionality" {
  let w1 = TestWriter::new()
  let w2 = TestWriter::new()
  let compressor = Compressor::new(w1)
  compressor.init(w1, 6)

  // Modify some state
  compressor.sync = true
  compressor.window_end = 100
  compressor.index = 50
  compressor.chain_head = 123
  compressor.hash_offset = 456

  // Reset
  compressor.reset(w2)

  // Verify reset state
  inspect(compressor.sync, content="false")
  inspect(compressor.window_end, content="0")
  inspect(compressor.index, content="0")
  inspect(compressor.chain_head, content="-1")
  inspect(compressor.hash_offset, content="1")
  inspect(compressor.err is None, content="true")
}
