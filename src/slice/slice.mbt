///|
struct Slice[T](FixedArray[T], Int, Int)

///|
pub impl[T : Eq] Eq for Slice[T] with equal(self : Slice[T], other : Slice[T]) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if self.0[self.1 + i] != other.0[other.1 + i] {
      return false
    }
  }
  true
}

///|
pub fn[T] array(
  array : FixedArray[T],
  start? : Int = 0,
  end? : Int,
) -> Slice[T] {
  let len = array.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard 0 <= start && start <= end && end <= len else {
    abort("slice: out of bounds")
  }
  Slice(array, start, end - start)
}

///|
fn Bytes::unsafe_reinterpret_as_fixedarray(self : Bytes) -> FixedArray[Byte] = "%identity"

///|
pub fn bytes(bytes : Bytes, start? : Int = 0, end? : Int) -> Slice[Byte] {
  array(bytes.unsafe_reinterpret_as_fixedarray(), start~, end?)
}

///|
pub fn[T : Default] make(size : Int) -> Slice[T] {
  if size < 0 {
    abort("slice: negative size")
  }
  if size == 0 {
    Slice([], 0, size)
  } else {
    let value = T::default()
    let array = FixedArray::make(size, value)
    for i in 1..<size {
      array[i] = value
    }
    Slice(array, 0, size)
  }
}

///|
pub fn[T] Slice::length(self : Slice[T]) -> Int {
  self.2
}

///|
pub impl[T] @builtin.Len for Slice[T] with len(self : Slice[T]) -> Int {
  self.length()
}

///|
pub impl[T] Default for Slice[T] with default() -> Slice[T] {
  Slice([], 0, 0)
}

///|
pub fn[T] new() -> Slice[T] {
  Slice([], 0, 0)
}

///|
pub fn[T] Slice::op_as_view(
  self : Slice[T],
  start? : Int = 0,
  end? : Int,
) -> Slice[T] {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("slice: out of bounds")
  }
  Slice(self.0, self.1 + start, end - start)
}

///|
pub fn[T] Slice::op_get(s : Slice[T], idx : Int) -> T {
  let idx = if idx < 0 { s.length() + idx } else { idx }
  guard 0 <= idx && idx < s.length() else {
    abort("slice: index out of bounds")
  }
  s.0[s.1 + idx]
}

///|
pub fn[T] Slice::op_set(s : Slice[T], idx : Int, val : T) -> Unit {
  let idx = if idx < 0 { s.length() + idx } else { idx }
  guard 0 <= idx && idx < s.length() else {
    abort("slice: index out of bounds")
  }
  s.0[s.1 + idx] = val
}

///|
pub impl[T : Show] Show for Slice[T] with output(
  self : Slice[T],
  logger : &Logger,
) -> Unit {
  logger.write_string("[")
  for i in 0..<self.length() {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.0[self.1 + i])
  }
  logger.write_string("]")
}

///|
pub impl[T : ToJson] ToJson for Slice[T] with to_json(self : Slice[T]) -> Json {
  let arr = Array::make(self.length(), Json::null())
  for i in 0..<self.length() {
    arr[i] = self.0[self.1 + i].to_json()
  }
  Json::array(arr)
}

///|
pub fn[T : Default] Slice::append(s : Slice[T], val : T) -> Slice[T] {
  let Slice(buf, off, len) = s
  let buf = buf.copy()
  let mut cap = buf.length()
  if off + len < cap {
    buf[off + len] = val
    return Slice(buf, off, len + 1)
  }
  if cap == 0 {
    cap = 1
  }
  while cap < off + len + 1 {
    cap = cap * 2
  }
  let new_buf = FixedArray::make(cap, T::default())
  for i in 0..<len {
    new_buf[i] = buf[off + i]
  }
  new_buf[off + len] = val
  Slice(new_buf, off, len + 1)
}

///|
pub fn[T] Slice::iter(s : Slice[T]) -> Iter[T] {
  Iter::new(each => for i in s.1..<(s.1 + s.2) {
    match each(s.0.unsafe_get(i)) {
      IterEnd => break IterEnd
      IterContinue => continue
    }
  } else {
    IterContinue
  })
}

///|
pub fn[T] Slice::iter2(s : Slice[T]) -> Iter2[Int, T] {
  Iter2::new(each => for i in 0..<s.2 {
    match each(i, s.0.unsafe_get(i + s.1)) {
      IterEnd => break IterEnd
      IterContinue => continue
    }
  } else {
    IterContinue
  })
}

///|
pub fn Slice::bytesview(self : Slice[Byte]) -> @bytes.View {
  self.0.unsafe_reinterpret_as_bytes()[self.1:self.1 + self.2]
}

///|
fn[T] make_arrayview(
  buf : FixedArray[T],
  start : Int,
  len : Int,
) -> ArrayView[T] = "%arrayview.make"

///|
pub fn[T] Slice::arrayview(self : Slice[T]) -> ArrayView[T] {
  make_arrayview(self.0, self.1, self.2)
}

///|
pub fn[T] Slice::copy(dst : Slice[T], src : Slice[T]) -> Int {
  let n = if dst.length() < src.length() { dst.length() } else { src.length() }
  for i in 0..<n {
    dst.0[dst.1 + i] = src.0[src.1 + i]
  }
  n
}

///|
pub fn Slice::copy_from_bytesview(dst : Slice[Byte], src : @bytes.View) -> Int {
  let dst_len = dst.length()
  let src_len = src.length()
  let n = if dst_len < src_len { dst_len } else { src_len }
  for i in 0..<n {
    dst.0[dst.1 + i] = src[i]
  }
  n
}

///|
pub fn[T] Slice::buffer(self : Slice[T]) -> FixedArray[T] {
  self.0
}

///|
pub fn[T] Slice::offset(self : Slice[T]) -> Int {
  self.1
}
