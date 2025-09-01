///|
/// Simple test writer for testing
struct DummyTestWriter {
  mut bytes_written : Int
} derive(Show)

///|
fn DummyTestWriter::new() -> DummyTestWriter {
  DummyTestWriter::{ bytes_written: 0 }
}

///|
test "test_token_creation" {
  // Test literal token creation
  let lit_token = literal_token(65) // 'A'
  inspect(lit_token.literal(), content="65")

  // Test match token creation
  let match_tok = match_token(10, 5)
  inspect(match_tok.length(), content="10")
  inspect(match_tok.offset(), content="5")
}

///|
test "test_writer_creation" {
  // Test that we can create a writer with a simple dummy writer
  let dummy_writer = DummyTestWriter::new()
  let flate_writer = new_writer(dummy_writer, NoCompression) catch {
    _ => {
      fail("Failed to create flate writer")
      return
    }
  }

  // Basic write test - call the public write method
  let test_data = b"Hello, World!"
  let result = flate_writer.write(test_data) catch {
    _ => {
      fail("Failed to write data")
      return
    }
  }
  inspect(result, content="13") // Should return number of bytes written
}

///|
impl @io.Writer for DummyTestWriter with write(self, bytes) {
  self.bytes_written += bytes.length()
  bytes.length()
}
