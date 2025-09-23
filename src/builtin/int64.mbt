///|
trait ToInt64 {
  to_int64(self : Self) -> Int64
}

///|
pub impl ToInt64 for Byte with to_int64(self : Byte) -> Int64 {
  self.to_int().to_int64()
}

///|
pub impl ToInt64 for Char with to_int64(self : Char) -> Int64 {
  self.to_int().to_int64()
}

///|
pub impl ToInt64 for UIntPtr with to_int64(self : UIntPtr) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
pub impl ToInt64 for Int16 with to_int64(self : Int16) -> Int64 {
  self.to_int64()
}

///|
pub impl ToInt64 for UInt16 with to_int64(self : UInt16) -> Int64 {
  self.to_int64()
}

///|
pub impl ToInt64 for Int with to_int64(self : Int) -> Int64 {
  self.to_int64()
}

///|
pub impl ToInt64 for UInt with to_int64(self : UInt) -> Int64 {
  self.to_int64()
}

///|
pub impl ToInt64 for UInt64 with to_int64(self : UInt64) -> Int64 {
  self.reinterpret_as_int64()
}

///|
pub fn[T : ToInt64] int64(v : T) -> Int64 {
  v.to_int64()
}
