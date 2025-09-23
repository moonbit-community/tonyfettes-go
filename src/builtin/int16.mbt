///|
trait ToInt16 {
  to_int16(self : Self) -> Int16
}

///|
pub impl ToInt16 for Byte with to_int16(self : Byte) -> Int16 {
  self.to_int16()
}

///|
pub impl ToInt16 for Char with to_int16(self : Char) -> Int16 {
  self.to_int().to_int16()
}

///|
pub impl ToInt16 for UIntPtr with to_int16(self : UIntPtr) -> Int16 {
  self.to_int16()
}

///|
pub impl ToInt16 for UInt16 with to_int16(self : UInt16) -> Int16 {
  self.to_int().to_int16()
}

///|
pub impl ToInt16 for Int with to_int16(self : Int) -> Int16 {
  self.to_int16()
}

///|
pub impl ToInt16 for UInt with to_int16(self : UInt) -> Int16 {
  self.reinterpret_as_int().to_int16()
}

///|
pub impl ToInt16 for Int64 with to_int16(self : Int64) -> Int16 {
  self.to_int16()
}

///|
pub impl ToInt16 for UInt64 with to_int16(self : UInt64) -> Int16 {
  self.reinterpret_as_int64().to_int16()
}

///|
pub fn[T : ToInt16] int16(v : T) -> Int16 {
  v.to_int16()
}
