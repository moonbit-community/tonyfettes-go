///|
pub(open) trait ToUInt64 {
  to_uint64(self : Self) -> UInt64
}

///|
pub impl ToUInt64 for Byte with to_uint64(self : Byte) -> UInt64 {
  self.to_uint().to_uint64()
}

///|
pub impl ToUInt64 for Char with to_uint64(self : Char) -> UInt64 {
  self.to_uint().to_uint64()
}

///|
pub impl ToUInt64 for UIntPtr with to_uint64(self : UIntPtr) -> UInt64 {
  self.to_uint64()
}

///|
pub impl ToUInt64 for Int16 with to_uint64(self : Int16) -> UInt64 {
  self.to_int64().reinterpret_as_uint64()
}

///|
pub impl ToUInt64 for UInt16 with to_uint64(self : UInt16) -> UInt64 {
  self.to_uint64()
}

///|
pub impl ToUInt64 for Int with to_uint64(self : Int) -> UInt64 {
  self.to_uint64()
}

///|
pub impl ToUInt64 for UInt with to_uint64(self : UInt) -> UInt64 {
  self.to_uint64()
}

///|
pub impl ToUInt64 for Int64 with to_uint64(self : Int64) -> UInt64 {
  self.reinterpret_as_uint64()
}

///|
pub fn[T : ToUInt64] uint64(v : T) -> UInt64 {
  v.to_uint64()
}
