///|
trait ToUInt {
  to_uint(self : Self) -> UInt
}

///|
pub impl ToUInt for Byte with to_uint(self : Byte) -> UInt {
  self.to_uint()
}

///|
pub impl ToUInt for Char with to_uint(self : Char) -> UInt {
  self.to_uint()
}

///|
pub impl ToUInt for UIntPtr with to_uint(self : UIntPtr) -> UInt {
  self.to_uint()
}

///|
pub impl ToUInt for Int16 with to_uint(self : Int16) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
pub impl ToUInt for UInt16 with to_uint(self : UInt16) -> UInt {
  self.to_uint()
}

///|
pub impl ToUInt for Int with to_uint(self : Int) -> UInt {
  self.reinterpret_as_uint()
}

///|
pub impl ToUInt for Int64 with to_uint(self : Int64) -> UInt {
  self.reinterpret_as_uint64().to_uint()
}

///|
pub impl ToUInt for UInt64 with to_uint(self : UInt64) -> UInt {
  self.to_uint()
}

///|
pub fn[T : ToUInt] uint(v : T) -> UInt {
  v.to_uint()
}
