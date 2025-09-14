///|
pub(open) trait Offsetof {
  offsetof(field : Self) -> Int
}

///|
pub fn[T : Offsetof] offsetof(field : T) -> Int {
  T::offsetof(field)
}

///|
pub(open) trait SizeOf {
  sizeof() -> Int
}

///|
pub fn[T : SizeOf] sizeof(v : T) -> Int {
  T::sizeof()
}
