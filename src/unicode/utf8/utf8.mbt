///|
struct Utf8(Bytes)

///|
pub(all) suberror Malformed @bytes.View

///|
pub impl ToJson for Malformed with to_json(self : Malformed) -> Json {
  let Malformed(bytes) = self
  {
    "@tonyfettes/go/unicode/utf8.Malformed": bytes
    .to_bytes()
    .to_array()
    .to_json(),
  }
}

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

///|
pub const RuneError : Char = '\u{FFFD}'

///|
pub const RuneSelf : Byte = 0x80

///|
pub const MaxRune : Char = '\u{10FFFF}'

///|
pub const UTFMax : Int = 4

///|
const Maskx : Byte = 0b00111111

///|
const Mask2 : Byte = 0b00011111

///|
const Mask3 : Byte = 0b00001111

///|
const Mask4 : Byte = 0b00000111

///|
const Locb : Byte = 0b10000000

///|
const Hicb : Byte = 0b11000000

///|
const Xx : Byte = 0xF1

///|
const As : Byte = 0xF0

///|
const S1 : Byte = 0x02

///|
const S2 : Byte = 0x13

///|
const S3 : Byte = 0x03

///|
const S4 : Byte = 0x23

///|
const S5 : Byte = 0x34

///|
const S6 : Byte = 0x04

///|
const S7 : Byte = 0x44

///|
let first : FixedArray[Byte] = [
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  As,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S1,
  S2,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S3,
  S4,
  S3,
  S3,
  S5,
  S6,
  S6,
  S6,
  S7,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
  Xx,
]

///|
/// AcceptRange gives the range of valid values for the second byte in a UTF-8
/// sequence.
priv struct AcceptRange {
  lo : Byte
  hi : Byte
}

///|
let accept_ranges : FixedArray[AcceptRange] = [
  { lo: Locb, hi: Hicb },
  { lo: 0xA0, hi: Hicb },
  { lo: Locb, hi: 0x9F },
  { lo: 0x90, hi: Hicb },
  { lo: Locb, hi: 0x8F },
]

///|
/// full_rune reports whether the bytes in p begin with a full UTF-8 encoding of a rune.
/// An invalid encoding is considered a full Rune since it will convert as a width-1 error rune.
pub fn full_rune(p : @slice.Slice[Byte]) -> Bool {
  let n = p.length()
  if n == 0 {
    return false
  }
  let x = first[p[0].to_int()]
  if n >= int(x & 0x7) {
    return true
  }
  let accept = accept_ranges[(x >> 4).to_int()]
  if n > 1 && (p[1] < accept.lo || accept.hi < p[1]) {
    return true
  } else if n > 2 && (p[2] < Locb || Hicb < p[2]) {
    return true
  }
  return false
}

///|
/// decode_rune unpacks the first UTF-8 encoding in p and returns the rune and
/// its width in bytes. If p is empty it returns ([RuneError], 0). Otherwise, if
/// the encoding is invalid, it returns (RuneError, 1). Both are impossible
/// results for correct, non-empty UTF-8.
///
/// An encoding is invalid if it is incorrect UTF-8, encodes a rune that is
/// out of range, or is not the shortest possible UTF-8 encoding for the
/// value. No other validation is performed.
pub fn decode_rune(p : @slice.Slice[Byte]) -> (Char, Int) {
  let n = p.length()
  if n < 1 {
    return (RuneError, 0)
  }
  let p0 = int(p[0])
  let x = first[p0]
  if x >= As {
    // The following code simulates an additional check for x == xx and
    // handling the ASCII and invalid cases accordingly. This mask-and-or
    // approach prevents an additional branch.
    let mask = x.to_int() << 31 >> 31
    let rune_error = int(RuneError)
    return (((p0 & mask.lnot()) | (rune_error & mask)).unsafe_to_char(), 1)
  }
  let sz = int(x & 0x7)
  let accept = accept_ranges[(x >> 4).to_int()]
  if n < sz {
    return (RuneError, 1)
  }
  let b1 = p[1]
  if b1 < accept.lo || b1 > accept.hi {
    return (RuneError, 1)
  }
  // FIXME(tonyfettes): The following comment should do nothing in MoonBit.
  // <= instead of == to help the compiler eliminate some bounds checks
  if sz <= 2 {
    let mask2 = int(Mask2)
    return ((((p0 & mask2) << 6) | int(b1 & Maskx)).unsafe_to_char(), 2)
  }
  let b2 = p[2]
  if b2 < Locb || Hicb < b2 {
    return (RuneError, 1)
  }
  if sz <= 3 {
    return (
      (((p0 & int(Mask3)) << 12) | (int(b1 & Maskx) << 6) | int(b2 & Maskx)).unsafe_to_char(),
      3,
    )
  }
  let b3 = p[3]
  if b3 < Locb || Hicb < b3 {
    return (RuneError, 1)
  }
  return (
    (((p0 & int(Mask4)) << 18) |
    (int(b1 & Maskx) << 12) |
    (int(b2 & Maskx) << 6) |
    int(b3 & Maskx)).unsafe_to_char(),
    4,
  )
}
