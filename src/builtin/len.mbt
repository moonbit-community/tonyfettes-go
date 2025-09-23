///|
pub(open) trait Len {
  len(self : Self) -> Int
}

///|
pub impl Len for Bytes with len(self : Bytes) -> Int {
  self.length()
}

///|
pub impl Len for BytesView with len(self : BytesView) -> Int {
  self.length()
}

///|
pub fn[T : Len] len(v : T) -> Int {
  T::len(v)
}
