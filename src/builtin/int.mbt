///|
trait ToInt {
  to_int(self : Self) -> Int
}

///|
pub impl ToInt for Byte with to_int(self : Byte) -> Int {
  self.to_int()
}

///|
pub impl ToInt for Char with to_int(self : Char) -> Int {
  self.to_int()
}

///|
pub impl ToInt for UIntPtr with to_int(self : UIntPtr) -> Int {
  self.to_int()
}

///|
pub impl ToInt for Int16 with to_int(self : Int16) -> Int {
  self.to_int()
}

///|
pub impl ToInt for UInt16 with to_int(self : UInt16) -> Int {
  self.to_int()
}

///|
pub impl ToInt for UInt with to_int(self : UInt) -> Int {
  self.reinterpret_as_int()
}

///|
pub impl ToInt for Int64 with to_int(self : Int64) -> Int {
  self.to_int()
}

///|
pub impl ToInt for UInt64 with to_int(self : UInt64) -> Int {
  self.to_int()
}

///|
pub fn[T : ToInt] int(v : T) -> Int {
  v.to_int()
}
