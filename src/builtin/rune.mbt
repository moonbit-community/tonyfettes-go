///|
pub typealias Char as Rune

///|
pub(all) suberror InvalidChar

///|
pub(open) trait ToChar {
  to_char(self : Self) -> Char raise InvalidChar
}

///|
pub impl ToChar for Byte with to_char(self : Byte) -> Rune {
  self.to_char()
}

///|
pub impl ToChar for Int with to_char(self : Int) -> Char raise InvalidChar {
  self.to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for UInt with to_char(self : UInt) -> Char raise InvalidChar {
  self.reinterpret_as_int().to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for Int16 with to_char(self : Int16) -> Char raise InvalidChar {
  self.to_int().to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for UInt16 with to_char(self : UInt16) -> Char raise InvalidChar {
  self.to_int().to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for Int64 with to_char(self : Int64) -> Char raise InvalidChar {
  self.to_int().to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for UInt64 with to_char(self : UInt64) -> Char raise InvalidChar {
  self.to_int().to_char().or_error(InvalidChar)
}

///|
pub impl ToChar for UIntPtr with to_char(self : UIntPtr) -> Char raise InvalidChar {
  self.to_uint().reinterpret_as_int().to_char().or_error(InvalidChar)
}

///|
pub fn[T : ToChar] rune(v : T) -> Rune raise InvalidChar {
  v.to_char()
}

///|
pub fn[T : ToChar] char(v : T) -> Char raise InvalidChar {
  v.to_char()
}
