/// Copyright 2017 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// A Builder is used to efficiently build a string using [Builder.Write] methods.
/// It minimizes memory copying. The zero value is ready to use.
/// Do not copy a non-zero Builder.
struct Builder {
  /// External users should never get direct access to this buffer, since
  /// the slice at some point will be converted to a string using unsafe, also
  /// data between len(buf) and cap(buf) might be uninitialized.
  mut buf : FixedArray[Byte]?
  mut len : Int
  mut last_rune : Int
}

///|
/// String returns the accumulated string.
pub fn Builder::string(self : Builder) -> String {
  guard self.buf is Some(buf) else { "" }
  buf.unsafe_reinterpret_as_bytes().to_unchecked_string()
}

///|
/// `len` returns the number of accumulated bytes; b.Len() == len(b.String()).
pub fn Builder::len(self : Builder) -> Int {
  self.len
}

///|
/// `cap` returns the capacity of the builder's underlying byte slice. It is the
/// total space allocated for the string being built and includes any bytes
/// already written.
pub fn Builder::cap(self : Builder) -> Int {
  if self.buf is Some(buf) {
    buf.length()
  } else {
    0
  }
}

///|
/// `reset` resets the [Builder](#Builder) to be empty.
pub fn Builder::reset(self : Builder) -> Unit {
  self.buf = None
  self.len = 0
}

///|
pub fn Builder::grow(self : Builder, n : Int) -> Unit {
  guard n > 0 else { return }
  guard self.buf is Some(buf) else {
    // First time: simply allocate.
    let size = if n < 64 { 64 } else { n }
    self.buf = Some(FixedArray::make(size, 0))
    self.len = 0
    return
  }
  let cap = buf.length()
  let len = self.len
  if cap - len >= n {
    // Enough space already.
    return
  }
  // Not enough space: double the capacity until we have enough.
  let new_cap = cap * 2
  let size = if new_cap - len >= n { new_cap } else { len + n }
  let new_buf : FixedArray[Byte] = FixedArray::make(size, 0)
  // Copy old data into new buffer.
  new_buf.unsafe_blit(0, buf, 0, len)
  self.buf = Some(new_buf)
}

///|
pub impl @io.Writer for Builder with write(
  self : Builder,
  p : @slice.Slice[Byte],
) -> Int raise {
  let n = p.len()
  self.grow(n)
  guard self.buf is Some(buf)
  for i in 0..<n {
    buf[self.len + i] = p[i]
  }
  let bv = buf.unsafe_reinterpret_as_bytes()
  loop bv[self.last_rune:self.len + n] {
    [] as view => self.last_rune = view.start_offset()
    [0x00..=0x7F, .. rest] => continue rest
    [0xC2..=0xDF] as view => self.last_rune = view.start_offset()
    [0xC2..=0xDF, 0x80..=0xBF, .. rest] => continue rest
    [0xE0..=0xEF] as view => self.last_rune = view.start_offset()
    [0xE0, 0xA0..=0xBF] as view => self.last_rune = view.start_offset()
    [0xE0, 0xA0..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [0xE1..=0xEC, 0x80..=0xBF] as view => self.last_rune = view.start_offset()
    [0xE1..=0xEC, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [0xED, 0x80..=0x9F] as view => self.last_rune = view.start_offset()
    [0xED, 0x80..=0x9F, 0x80..=0xBF, .. rest] => continue rest
    [0xEE..=0xEF, 0x80..=0xBF] as view => self.last_rune = view.start_offset()
    [0xEE..=0xEF, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [0xF0..=0xF4] as view => self.last_rune = view.start_offset()
    [0xF0, 0x90..=0xBF] as view => self.last_rune = view.start_offset()
    [0xF0, 0x90..=0xBF, 0x80..=0xBF] as view =>
      self.last_rune = view.start_offset()
    [0xF0, 0x90..=0xBF, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [0xF1..=0xF3, 0x80..=0xBF] as view => self.last_rune = view.start_offset()
    [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF] as view =>
      self.last_rune = view.start_offset()
    [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, 0x80..=0xBF, .. rest] =>
      continue rest
    [0xF4, 0x80..=0x8F] as view => self.last_rune = view.start_offset()
    [0xF4, 0x80..=0x8F, 0x80..=0xBF] as view =>
      self.last_rune = view.start_offset()
    [0xF4, 0x80..=0x8F, 0x80..=0xBF, 0x80..=0xBF, .. rest] => continue rest
    [..bytes] => raise @utf8.Malformed(bytes)
  }
  self.len += n
  self.last_rune = -1
  n
}
