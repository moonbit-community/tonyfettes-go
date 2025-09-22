///|
fnalias @builtin.len

///|
/// Reads from a reader and rot13s the result.
priv struct Rot13Reader {
  r : &@io.Reader
}

///|
fn new_rot13_reader(r : &@io.Reader) -> Rot13Reader {
  Rot13Reader::{ r, }
}

///|
impl @io.Reader for Rot13Reader with read(
  self : Rot13Reader,
  p : @slice.Slice[Byte],
) -> Int raise {
  let n = self.r.read(p)
  for i in 0..<n {
    let c = p[i] | 0x20 // lowercase byte
    if c is ('a'..='m') {
      p[i] += 13
    } else if c is ('n'..='z') {
      p[i] -= 13
    }
  }
  return n
}

///|
fn read_bytes(buf : Reader) -> String {
  let b : FixedArray[Byte] = FixedArray::make(1000, 0)
  let mut nb = 0
  for {
    try {
      let c = buf.read_byte()
      b[nb] = c
      nb += 1
    } catch {
      @io.EOF => break
      @iotest.Timeout => ()
      err => abort("Data: \{err}")
    }
  }
  return @utf8.decode_lossy(@slice.array(b)[0:nb])
}

///|
test "TestReaderSimple" {
  let data = "hello world"
  let b = new_reader(@strings.new_reader(data))
  let s = read_bytes(b)
  @json.inspect(s == "hello world", content=true)
  let b = new_reader(new_rot13_reader(@strings.new_reader(data)))
  let s = read_bytes(b)
  @json.inspect(s == "uryyb jbeyq", content=true)
}

///|
priv struct ReadMaker {
  name : String
  func : (&@io.Reader) -> &@io.Reader
}

///|
let read_makers : FixedArray[ReadMaker] = [
  { name: "full", func: r => r },
  { name: "byte", func: @iotest.one_byte_reader },
  { name: "half", func: @iotest.half_reader },
  // There is no data+err return pattern in MoonBit.
  { name: "timeout", func: @iotest.timeout_reader },
]

///|
/// Call ReadString (which ends up calling everything else)
/// to accumulate the text of a file.
fn read_lines(b : Reader) -> String {
  let s = StringBuilder::new()
  for {
    try {
      let s1 = b.read_string(b'\n')
      s.write_string(s1)
    } catch {
      @io.EOF => break
      @iotest.Timeout => ()
      err => abort("GetLines: \{err}")
    }
  }
  s.to_string()
}

///|
/// Call Read to accumulate the text of a file
fn reads(buf : Reader, m : Int) -> String {
  let b : FixedArray[Byte] = FixedArray::make(1000, 0)
  let mut nb = 0
  for {
    let slice = @slice.array(b)
    let view = slice[nb:nb + m]
    try {
      let n = buf.read(view)
      nb += n
    } catch {
      @io.EOF => break
      _ => ()
    }
  }
  @utf8.decode_lossy(@slice.array(b)[0:nb])
}

///|
priv struct BufReader {
  name : String
  func : (Reader) -> String
}

///|
let buf_readers : Array[BufReader] = [
  BufReader::{ name: "1", func: fn(b) { reads(b, 1) } },
  BufReader::{ name: "2", func: fn(b) { reads(b, 2) } },
  BufReader::{ name: "3", func: fn(b) { reads(b, 3) } },
  BufReader::{ name: "4", func: fn(b) { reads(b, 4) } },
  BufReader::{ name: "5", func: fn(b) { reads(b, 5) } },
  BufReader::{ name: "7", func: fn(b) { reads(b, 7) } },
  BufReader::{ name: "bytes", func: read_bytes },
  BufReader::{ name: "lines", func: read_lines },
]

///|
const MinReadBufferSize = 16

///|
let buf_sizes : Array[Int] = [
  0,
  MinReadBufferSize,
  23,
  32,
  46,
  64,
  93,
  128,
  1024,
  4096,
]

///|
test "TestReader" {
  let texts : Array[String] = Array::make(31, "")
  let mut str = ""
  let mut all = ""
  for i = 0; i < texts.length() - 1; i = i + 1 {
    texts[i] = str + "\n"
    all += texts[i]
    str += Int::to_char(i % 26 + 'a'.to_int()).unwrap().to_string()
  }
  texts[texts.length() - 1] = all
  for h = 0; h < texts.length(); h = h + 1 {
    let text = texts[h]
    for i = 0; i < read_makers.length(); i = i + 1 {
      for j = 0; j < buf_readers.length(); j = j + 1 {
        for k = 0; k < buf_sizes.length(); k = k + 1 {
          let read_maker = read_makers[i]
          let buf_reader = buf_readers[j]
          let buf_size = buf_sizes[k]
          let read = (read_maker.func)(@strings.new_reader(text))
          let buf = new_reader_size(read, buf_size)
          let s = (buf_reader.func)(buf)
          if s != text {
            fail(
              "reader=\{read_maker.name} fn=\{buf_reader.name} bufsize=\{buf_size} want=\{text} got=\{s}",
            )
          }
        }
      }
    }
  }
}

///|
priv struct ZeroReader {}

///|
impl @io.Reader for ZeroReader with read(self, p) {
  ignore(self)
  ignore(p)
  0
}

///|
test "TestZeroReader" {
  let z = ZeroReader::{  }
  let r = new_reader(z)

  // Test for ErrNoProgress when reader returns 0 repeatedly
  let result : Result[Byte, Error] = try? r.read_byte()
  inspect(result is Err(_), content="true")
}

///|
/// A StringReader delivers its data one string segment at a time via Read.
priv struct StringReader {
  data : Array[String]
  mut step : Int
}

///|
fn StringReader::new(data : Array[String]) -> StringReader {
  StringReader::{ data, step: 0 }
}

///|
impl @io.Reader for StringReader with read(self, p) {
  if self.step < self.data.length() {
    let s = self.data[self.step]
    let bytes = @encoding/utf8.encode(s)
    let n = if bytes.length() > p.length() {
      p.length()
    } else {
      bytes.length()
    }
    for i = 0; i < n; i = i + 1 {
      p[i] = bytes[i]
    }
    self.step += 1
    n
  } else {
    raise @io.EOF
  }
}

///|
fn read_rune_segments(segments : Array[String]) -> String raise {
  let mut got = ""
  let mut want = ""
  for seg in segments {
    want += seg
  }
  let r = new_reader(StringReader::new(segments))
  for {
    let (rune, _) = r.read_rune() catch {
      @io.EOF => break
      e => raise e
    }
    got += rune.to_string()
  }
  if got != want {
    fail("segments=\{segments} got=\{got} want=\{want}")
  }
  got
}

///|
let segment_list : Array[Array[String]] = [
  [],
  [""],
  ["日", "本語"],
  ["\u{65e5}", "\u{672c}", "\u{8a9e}"],
  ["\u{000065e5}", "\u{0000672c}", "\u{00008a9e}"],
  ["Hello", ", ", "World", "!"],
  ["Hello", ", ", "", "World", "!"],
]

///|
test "read_rune" {
  for s in segment_list {
    ignore(read_rune_segments(s))
  }
}

///|
test "unread_rune" {
  let segments = ["Hello, world:", "日本語"]
  let r = new_reader(StringReader::new(segments))
  let mut got = ""
  let mut want = ""
  for seg in segments {
    want += seg
  }

  // Normal execution.
  for {
    let (r1, _) = r.read_rune() catch {
      @io.EOF => break
      e => abort("unexpected error on ReadRune: \{e}")
    }
    got += r1.to_string()

    // Put it back and read it again.
    r.unread_rune() catch {
      e => abort("unexpected error on UnreadRune: \{e}")
    }
    let (r2, _) = r.read_rune() catch {
      e => abort("unexpected error reading after unreading: \{e}")
    }
    if r1 != r2 {
      abort("incorrect rune after unread: got \{r1}, want \{r2}")
    }
  }
  if got != want {
    abort("got \{got}, want \{want}")
  }
}

///|
test "BufferFull" {
  let long_string = "And now, hello, world! It is the time for all good men to come to the aid of their party"
  let buf = @bufio.new_reader_size(
    @strings.new_reader(long_string),
    MinReadBufferSize,
  )
  @json.inspect(try? buf.read_slice('!'), content={
    "Err": [
      "BufferFull",
      [65, 110, 100, 32, 110, 111, 119, 44, 32, 104, 101, 108, 108, 111, 44, 32],
    ],
  })
  @json.inspect(@utf8.decode(buf.read_slice('!').bytesview()), content="world!")
}

///|
test "peek" {
  let p : @slice.Slice[Byte] = @slice.make(10)
  let buf = @bufio.new_reader_size(
    @strings.new_reader("abcdefghijklmnop"),
    MinReadBufferSize,
  )
  @json.inspect(buf.peek(1), content=[97])
  @json.inspect(buf.peek(4), content=[97, 98, 99, 100])
  @json.inspect(try? buf.peek(-1), content={ "Err": "NegativeCount" })
  @json.inspect(try? buf.peek(32), content={
    "Err": [
      "BufferFull",
      [
        97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
      ],
    ],
  })
  @json.inspect(buf.read(p[0:3]), content=3)
  @json.inspect(buf.peek(1), content=[100])
  @json.inspect(buf.peek(2), content=[100, 101])
  @json.inspect(buf.read(p[0:3]), content=3)
  @json.inspect(buf.peek(4), content=[103, 104, 105, 106])
  @json.inspect(buf.read(p[0:]), content=10)
  @json.inspect(buf.peek(0), content=[])
  @json.inspect(try? buf.peek(1), content={ "Err": "tonyfettes/go/io.EOF.EOF" })
}

///|
test "peek-then-unread_rune" {
  let r = new_reader(@strings.new_reader("x"))
  @json.inspect(r.read_rune(), content=["x", 1])
  @json.inspect(try? r.peek(1), content={ "Err": "tonyfettes/go/io.EOF.EOF" })
  @json.inspect(try? r.unread_rune(), content={ "Err": "InvalidUnreadRune" })
  @json.inspect(try? r.read_rune(), content={
    "Err": "tonyfettes/go/io.EOF.EOF",
  })
}

///|
const TestOutput : Bytes = "0123456789abcdefghijklmnopqrstuvwxy"

///|
const TestInput : Bytes = "012\n345\n678\n9ab\ncde\nfgh\nijk\nlmn\nopq\nrst\nuvw\nxy"

///|
const TestInputRN : Bytes = "012\r\n345\r\n678\r\n9ab\r\ncde\r\nfgh\r\nijk\r\nlmn\r\nopq\r\nrst\r\nuvw\r\nxy\r\n\n\r\n"

///|
priv struct TestReader {
  mut data : @slice.Slice[Byte]
  stride : Int
}

///|
impl @io.Reader for TestReader with read(
  self : TestReader,
  buf : @slice.Slice[Byte],
) -> Int raise {
  if len(self.data) == 0 {
    raise @io.EOF
  }
  let mut n = self.stride
  if n > len(self.data) {
    n = len(self.data)
  }
  if n > len(buf) {
    n = len(buf)
  }
  let n = buf.copy(self.data)
  self.data = self.data[n:]
  n
}

///|
fn test_read_line(input : @slice.Slice[Byte]) -> Unit raise {
  for stride = 1; stride < 2; stride = stride + 1 {
    let mut done = 0
    let reader = TestReader::{ data: input, stride }
    let l = new_reader_size(reader, len(input) + 1)
    for {
      let (line, is_prefix) = l.read_line() catch {
        @io.EOF => break
        err => fail("Got unknown error: \{err}")
      }
      if is_prefix {
        fail("read_line returned is_prefix=true")
      }
      if TestOutput[done:done + len(line)] is want &&
        @slice.bytesview(want) != line {
        fail("Bad line at stride \{stride}: got=\{line} want=\{want}")
      }
      done += len(line)
    }
    if done != len(TestOutput) {
      fail(
        "Read only \{done} bytes at stride \{stride}: want \{len(TestOutput)}",
      )
    }
  }
}

///|
test "read_line" {
  test_read_line(@slice.bytes(TestInput))
  test_read_line(@slice.bytes(TestInputRN))
}
