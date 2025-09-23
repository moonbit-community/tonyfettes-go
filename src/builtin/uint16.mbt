///|
trait ToUInt16 {
  to_uint16(self : Self) -> UInt16
}

///|
pub impl ToUInt16 for Byte with to_uint16(self : Byte) -> UInt16 {
  self.to_uint16()
}

///|
pub impl ToUInt16 for Char with to_uint16(self : Char) -> UInt16 {
  self.to_int().to_uint16()
}

///|
pub impl ToUInt16 for UIntPtr with to_uint16(self : UIntPtr) -> UInt16 {
  self.to_uint16()
}

///|
pub impl ToUInt16 for Int16 with to_uint16(self : Int16) -> UInt16 {
  self.reinterpret_as_uint16()
}

///|
pub impl ToUInt16 for Int with to_uint16(self : Int) -> UInt16 {
  self.to_uint16()
}

///|
pub impl ToUInt16 for UInt with to_uint16(self : UInt) -> UInt16 {
  self.reinterpret_as_int().to_uint16()
}

///|
pub impl ToUInt16 for Int64 with to_uint16(self : Int64) -> UInt16 {
  self.to_uint16()
}

///|
pub impl ToUInt16 for UInt64 with to_uint16(self : UInt64) -> UInt16 {
  self.reinterpret_as_int64().to_uint16()
}

///|
pub fn[T : ToUInt16] uint16(v : T) -> UInt16 {
  v.to_uint16()
}
