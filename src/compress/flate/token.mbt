///|
/// Constants for token encoding
/// 2 bits:   type   0 = literal  1=EOF  2=Match   3=Unused
/// 8 bits:   xlength = length - MIN_MATCH_LENGTH
/// 22 bits   xoffset = offset - MIN_OFFSET_SIZE, or literal
const LengthShift = 22

///|
const OffsetMask : UInt = (1 << LengthShift) - 1

///|
const TypeMask : UInt = 3 << 30

///|
const LiteralType : UInt = 0 << 30

///|
const MatchType : UInt = 1 << 30

///|
/// The length code for length X (MIN_MATCH_LENGTH <= X <= MAX_MATCH_LENGTH)
/// is length_codes[length - MIN_MATCH_LENGTH]
let length_codes : FixedArray[UInt] = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12, 12, 13, 13, 13,
  13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17,
  17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19,
  19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21,
  21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22,
  22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25,
  25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
  25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28,
]

///|
let offset_codes : FixedArray[UInt] = [
  0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9,
  9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12,
  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
  12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
  13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15,
]

///|
/// Token represents a literal or match token
priv struct Token(UInt)

///|
/// Convert a literal into a literal token
fn literal_token(literal : UInt) -> Token {
  Token(LiteralType + literal)
}

///|
/// Convert a <xlength, xoffset> pair into a match token
fn match_token(xlength : UInt, xoffset : UInt) -> Token {
  Token(MatchType + (xlength << LengthShift) + xoffset)
}

///|
/// Returns the literal of a literal token
fn Token::literal(self : Token) -> UInt {
  self.0 - LiteralType
}

///|
/// Returns the extra offset of a match token
fn Token::offset(self : Token) -> UInt {
  self.0 & OffsetMask
}

///|
/// Returns the length of a match token
fn Token::length(self : Token) -> UInt {
  (self.0 - MatchType) >> LengthShift
}

///|
/// Returns the length code for a given length
fn length_code(len : UInt) -> UInt {
  length_codes[len.reinterpret_as_int()]
}

///|
/// Returns the offset code corresponding to a specific offset
fn offset_code(off : UInt) -> UInt {
  if off < length_codes.length().reinterpret_as_uint() {
    offset_codes[off.reinterpret_as_int()]
  } else if off >> 7 < offset_codes.length().reinterpret_as_uint() {
    offset_codes[(off >> 7).reinterpret_as_int()] + 14
  } else {
    offset_codes[(off >> 14).reinterpret_as_int()] + 28
  }
}
