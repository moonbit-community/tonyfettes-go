///|
struct Utf8(Bytes)

///|
pub suberror Malformed @bytes.View

///|
fn validate(bytes : @bytes.View) -> Unit raise Malformed {
  let start_offset = bytes.start_offset()
  loop bytes {
    [] => return
    [
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      0x00..=0x7F,
      .. rest,
    ] => continue rest
    [0x00..=0x7F, .. rest] => continue rest
    [0xC2..=0xDF, 0x80..=0xBF, .. rest] => continue rest
    [0xE0, 0xA0..=0xBF, 0x80..=0xBF, .. rest]
    | [0xE1..=0xEC, 0x80..=0xBF, 0x80..=0xBF, .. rest]
    | [0xED, 0x80..=0x9F, 0x80..=0xBF, .. rest]
    | [0xEE..=0xEF, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [0xF0, 0x90..=0xBF, 0x80..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF4, 0x80..=0x8F, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [..] as bytes =>
      raise Malformed(bytes[bytes.start_offset() - start_offset:])
  }
}

///|
pub fn new(bytes : Bytes) -> Utf8 raise Malformed {
  validate(bytes)
  Utf8(bytes)
}

///|
pub fn Utf8::to_bytes(self : Utf8) -> Bytes {
  self.0
}

///|
pub fn Utf8::to_string(self : Utf8) -> String {
  let builder = StringBuilder::new()
  loop self.0[:] {
    [] => break
    [_..=0x7F as b0, .. rest] => {
      builder.write_char(b0.to_char())
      continue rest
    }
    [_..=0xDF as b0, b1, .. rest] => {
      let char = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [_..=0xEF as b0, b1, b2, .. rest] => {
      let char = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [b0, b1, b2, b3, .. rest] => {
      let char = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [..] => abort("unreachable")
  }
  builder.to_string()
}

///|
pub fn decode(bytes : @bytes.View) -> String raise Malformed {
  let start_offset = bytes.start_offset()
  let builder = StringBuilder::new()
  loop bytes {
    [] => break
    [
      0x00..=0x7F as b0,
      0x00..=0x7F as b1,
      0x00..=0x7F as b2,
      0x00..=0x7F as b3,
      0x00..=0x7F as b4,
      0x00..=0x7F as b5,
      0x00..=0x7F as b6,
      0x00..=0x7F as b7,
      .. rest,
    ] => {
      builder.write_char(b0.to_char())
      builder.write_char(b1.to_char())
      builder.write_char(b2.to_char())
      builder.write_char(b3.to_char())
      builder.write_char(b4.to_char())
      builder.write_char(b5.to_char())
      builder.write_char(b6.to_char())
      builder.write_char(b7.to_char())
      continue rest
    }
    [0x00..=0x7F as b0, .. rest] => {
      builder.write_char(b0.to_char())
      continue rest
    }
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest] => {
      let char = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest] => {
      let char = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [
      0xF0 as b0,
      0x90..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF4 as b0,
      0x80..=0x8F as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ] => {
      let char = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      builder.write_char(char.unsafe_to_char())
      continue rest
    }
    [..] as bytes =>
      raise Malformed(bytes[bytes.start_offset() - start_offset:])
  }
  builder.to_string()
}

///|
const U_REP = '\u{FFFD}'

///|
///
/// References :
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-5/#G40630
pub fn decode_lossy(
  bytes : @slice.Slice[Byte],
  ignore_bom? : Bool = false,
) -> String {
  let bytes = bytes.bytesview()
  let bytes = if ignore_bom && bytes is [.. "\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  let builder = StringBuilder::new(size_hint=bytes.length())
  loop bytes {
    [] => ()
    [0..=0x7F as b, .. rest] => {
      builder.write_char(b.to_int().unsafe_to_char())
      continue rest
    }
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest] => {
      let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest] => {
      let ch = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xE0, 0xA0..=0xBF, .. rest]
    | [0xE1..=0xEC, 0x80..=0xBF, .. rest]
    | [0xED, 0x80..=0x9F, .. rest]
    | [0xEE..=0xEF, 0x80..=0xBF, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [
      0xF0 as b0,
      0x90..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF4 as b0,
      0x80..=0x8F as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ] => {
      let ch = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xF0, 0x90..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF4, 0x80..=0x8F, 0x80..=0xBF, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [0xF0, 0x90..=0xBF, .. rest]
    | [0xF1..=0xF3, 0x80..=0xBF, .. rest]
    | [0xF4, 0x80..=0x8F, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [_, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
  }
  builder.to_string()
}

///|
pub fn encode(string : @string.View) -> Bytes {
  let buffer = @buffer.new()
  for c in string {
    let code = c.to_int()
    if code <= 0x7F {
      buffer.write_byte(code.to_byte())
    } else if code <= 0x7FF {
      buffer.write_byte((0xC0 | ((code >> 6) & 0x1F)).to_byte())
      buffer.write_byte((0x80 | (code & 0x3F)).to_byte())
    } else if code <= 0xFFFF {
      buffer.write_byte((0xE0 | ((code >> 12) & 0x0F)).to_byte())
      buffer.write_byte((0x80 | ((code >> 6) & 0x3F)).to_byte())
      buffer.write_byte((0x80 | (code & 0x3F)).to_byte())
    } else {
      buffer.write_byte((0xF0 | ((code >> 18) & 0x07)).to_byte())
      buffer.write_byte((0x80 | ((code >> 12) & 0x3F)).to_byte())
      buffer.write_byte((0x80 | ((code >> 6) & 0x3F)).to_byte())
      buffer.write_byte((0x80 | (code & 0x3F)).to_byte())
    }
  }
  buffer.contents()
}
