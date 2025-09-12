///|
/// Simple test reader that provides a fixed byte sequence
struct TestReader {
  data : Bytes
  mut pos : Int
}

///|
fn TestReader::new(data : Bytes) -> TestReader {
  TestReader::{ data, pos: 0 }
}

///|
impl @io.Reader for TestReader with read(self, p) {
  if self.pos >= self.data.length() {
    raise @io.EOF
  }
  let n = if p.length() > self.data.length() - self.pos {
    self.data.length() - self.pos
  } else {
    p.length()
  }
  for i = 0; i < n; i = i + 1 {
    p[i] = self.data[self.pos + i]
  }
  self.pos += n
  n
}

/// Simple test writer that accumulates written bytes

///|
struct TestWriter {
  mut data : @slice.Slice[Byte]
}

///|
fn TestWriter::new() -> TestWriter {
  TestWriter::{ data: @slice.make(0) }
}

///|
impl @io.Writer for TestWriter with write(self, p) {
  let old_len = self.data.length()
  let new_data = @slice.make(old_len + p.length())
  for i = 0; i < old_len; i = i + 1 {
    new_data[i] = self.data[i]
  }
  for i = 0; i < p.length(); i = i + 1 {
    new_data[old_len + i] = p[i]
  }
  self.data = new_data
  p.length()
}

///|
fn TestWriter::bytes(self : TestWriter) -> @slice.Slice[Byte] {
  self.data
}

///|
test "reader basic functionality" {
  let test_data : Bytes = "Hello, World!"
  let tr = TestReader::new(test_data)
  let reader = new_reader(tr)
  let buf : @slice.Slice[Byte] = @slice.make(5)
  let n = reader.read(buf)
  inspect(n, content="5")
  inspect(
    buf,
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']"
    ),
  )
}

///|
test "Reader::peek" {
  let test_data : Bytes = "Hello, World!"
  let tr = TestReader::new(test_data)
  let reader = new_reader(tr)
  let peeked = reader.peek(5)
  inspect(
    peeked,
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']"
    ),
  )

  // Data should still be available for reading
  let buf : @slice.Slice[Byte] = @slice.make(5)
  let n = reader.read(buf)
  inspect(n, content="5")
  inspect(
    buf,
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']"
    ),
  )
}

///|
test "reader read_slice functionality" {
  let test_data : Bytes = "line1\nline2\r\nline3"
  let tr = TestReader::new(test_data)
  let reader = new_reader(tr)
  let line1 = reader.read_slice(b'\n')
  inspect(
    line1,
    content=(
      "[b'\\x6C', b'\\x69', b'\\x6E', b'\\x65', b'\\x31', b'\\x0A']"
    ),
  )
  let line2 = reader.read_slice(b'\n')
  inspect(
    line2,
    content=(
      "[b'\\x6C', b'\\x69', b'\\x6E', b'\\x65', b'\\x32', b'\\x0D', b'\\x0A']"
    ),
  )
}

///|
test "reader read_bytes functionality" {
  let test_data : Bytes = "Hello|World|Test"
  let tr = TestReader::new(test_data)
  let reader = new_reader(tr)
  let bytes1 = reader.read_bytes(b'|')
  inspect(
    bytes1,
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F', b'\\x7C']"
    ),
  )
  let bytes2 = reader.read_bytes(b'|')
  inspect(
    bytes2,
    content=(
      "[b'\\x57', b'\\x6F', b'\\x72', b'\\x6C', b'\\x64', b'\\x7C']"
    ),
  )
  let bytes3 = reader.read_bytes(b'|')
  inspect(
    bytes3,
    content=(
      #|b""
    ),
  )
}

///|
test "reader buffered functionality" {
  let test_data : Bytes = "Hello"
  let tr = TestReader::new(test_data)
  let reader = new_reader(tr)

  // Initially no data is buffered
  inspect(reader.buffered(), content="0")

  // Peek some data to fill buffer
  let _ = reader.peek(3)
  inspect(reader.buffered() >= 3, content="true")
}

///|
test "writer basic functionality" {
  let tw = TestWriter::new()
  let writer = new_writer(tw)
  let test_data : @slice.Slice[Byte] = @slice.bytes("Hello, World!")
  let n = writer.write(test_data)
  inspect(n, content="13")

  // Flush to make sure data is written
  writer.flush()
  inspect(
    tw.bytes(),
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F', b'\\x2C', b'\\x20', b'\\x57', b'\\x6F', b'\\x72', b'\\x6C', b'\\x64', b'\\x21']"
    ),
  )
}

///|
test "writer buffered functionality" {
  let tw = TestWriter::new()
  let writer = new_writer(tw)

  // Initially no data is buffered
  inspect(writer.buffered(), content="0")
  let test_data : @slice.Slice[Byte] = @slice.bytes("Hello")
  let _ = writer.write(test_data)

  // Data should be buffered
  inspect(writer.buffered(), content="5")

  // After flush, buffer should be empty
  writer.flush()
  inspect(writer.buffered(), content="0")
}

///|
test "writer write_byte functionality" {
  let tw = TestWriter::new()
  let writer = new_writer(tw)
  writer.write_byte(b'H')
  writer.write_byte(b'i')
  writer.flush()
  inspect(
    tw.bytes(),
    content=(
      "[b'\\x48', b'\\x69']"
    ),
  )
}

///|
test "writer write_string functionality" {
  let tw = TestWriter::new()
  let writer = new_writer(tw)
  let n = writer.write_string("Hello, World!")
  @json.inspect(n, content=26)
  writer.flush()
  @json.inspect(tw.bytes(), content=[
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ])
}

///|
test "scanner basic functionality" {
  let test_data : Bytes = "line1\nline2\nline3\n"
  let tr = TestReader::new(test_data)
  let scanner = new_scanner(tr)
  let lines : Array[String] = []
  while scanner.scan() {
    lines.push(scanner.text())
  }
  inspect(lines.length(), content="3")
  inspect(
    lines[0],
    content=(
      "[b'\\x6C', b'\\x69', b'\\x6E', b'\\x65', b'\\x31', b'\\x0A']"
    ),
  )
  inspect(
    lines[1],
    content=(
      "[b'\\x6C', b'\\x69', b'\\x6E', b'\\x65', b'\\x32', b'\\x0A']"
    ),
  )
  inspect(
    lines[2],
    content=(
      "[b'\\x6C', b'\\x69', b'\\x6E', b'\\x65', b'\\x33', b'\\x0A']"
    ),
  )
}

///|
test "scanner with custom split function" {
  let test_data : Bytes = "word1 word2 word3"
  let tr = TestReader::new(test_data)
  let scanner = new_scanner(tr)
  scanner.split(scan_words)
  let words : Array[String] = []
  while scanner.scan() {
    words.push(scanner.text())
  }
  inspect(words.length(), content="3")
  inspect(
    words[0],
    content=(
      "[b'\\x77', b'\\x6F', b'\\x72', b'\\x64', b'\\x31']"
    ),
  )
  inspect(
    words[1],
    content=(
      "[b'\\x77', b'\\x6F', b'\\x72', b'\\x64', b'\\x32']"
    ),
  )
  inspect(
    words[2],
    content=(
      "[b'\\x77', b'\\x6F', b'\\x72', b'\\x64', b'\\x33']"
    ),
  )
}

///|
test "read_writer functionality" {
  let test_data : Bytes = "Hello"
  let tr = TestReader::new(test_data)
  let tw = TestWriter::new()
  let reader = new_reader(tr)
  let writer = new_writer(tw)
  let rw = new_read_writer(reader, writer)
  let buf = @slice.make(5)
  let n = rw.read(buf)
  inspect(n, content="5")
  let n2 = rw.write(buf)
  inspect(n2, content="5")
  rw.writer.flush()
  inspect(
    tw.bytes(),
    content=(
      "[b'\\x48', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']"
    ),
  )
}
