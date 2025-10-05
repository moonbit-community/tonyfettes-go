///|
pub fn clone(b : @slice.Slice[Byte]) -> @slice.Slice[Byte] {
  let n : @slice.Slice[Byte] = @slice.make(b.length())
  for i in 0..<b.length() {
    n[i] = b[i]
  }
  n
}

///|
fn equal(a : @slice.Slice[Byte], b : @slice.Slice[Byte]) -> Bool {
  let len = a.length()
  if b.length() != len {
    return false
  }
  for i in 0..<len {
    if a[i] != b[i] {
      break false
    }
  } else {
    true
  }
}

///|
pub fn has_prefix(s : @slice.Slice[Byte], prefix : @slice.Slice[Byte]) -> Bool {
  let s_len = s.length()
  let p_len = prefix.length()
  if p_len <= s_len {
    for i in 0..<p_len {
      if s[i] != prefix[i] {
        break false
      }
    } else {
      true
    }
  } else {
    false
  }
}
