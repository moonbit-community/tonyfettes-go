///|
pub fn rune_self(value : UInt16) -> Bool {
  let value = value.to_int()
  !value.is_leading_surrogate()
}

///|
pub const RuneError : Char = '\u{FFFD}'

///|
pub fn decode_last_rune_in_string(s : StringView) -> (Char, Int) {
  let end = s.length()
  if end is 0 {
    return (RuneError, 0)
  }
  let start = end - 1
  let r = s[start]
  if r.is_trailing_surrogate() {
    if start - 1 < 0 {
      return (RuneError, 0)
    }
    return (
      (0x10000 + (s[start - 1] - 0xD800) * 0x400 + (r - 0xDC00)).unsafe_to_char(),
      2,
    )
  } else if !r.is_leading_surrogate() {
    return (r.unsafe_to_char(), 1)
  } else {
    return (RuneError, 1)
  }
}

///|
pub fn decode_rune_in_string(s : StringView) -> (Char, Int) {
  let n = s.length()
  if n < 1 {
    return (RuneError, 0)
  }
  let s0 = s[0]
  if s0.is_leading_surrogate() {
    if n < 2 {
      return (RuneError, 0)
    }
    let s1 = s[1]
    if s1.is_trailing_surrogate() {
      return (
        (0x10000 + (s0 - 0xD800) * 0x400 + (s1 - 0xDC00)).unsafe_to_char(),
        2,
      )
    } else {
      return (RuneError, 0)
    }
  } else {
    return (s0.unsafe_to_char(), 1)
  }
}
