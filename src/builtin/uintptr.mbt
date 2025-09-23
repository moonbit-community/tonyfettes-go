///|
#external
pub type UIntPtr

///|
pub fn UIntPtr::from_byte(v : Byte) -> UIntPtr {
  UIntPtr::from_int(v.to_int())
}

///|
pub fn UIntPtr::from_uint16(v : UInt16) -> UIntPtr {
  UIntPtr::from_int(v.to_int())
}

///|
pub fn UIntPtr::from_int16(v : Int16) -> UIntPtr {
  UIntPtr::from_int(v.to_int())
}

///|
pub fn UIntPtr::from_int(v : Int) -> UIntPtr {
  UIntPtr::from_uint(v.reinterpret_as_uint())
}

///|
pub extern "c" fn UIntPtr::from_uint(v : UInt) -> UIntPtr = "moonbit_tonyfettes_go_builtin_uintptr_from_uint"

///|
pub fn UIntPtr::from_int64(v : Int64) -> UIntPtr {
  UIntPtr::from_uint64(v.reinterpret_as_uint64())
}

///|
pub extern "c" fn UIntPtr::from_uint64(v : UInt64) -> UIntPtr = "moonbit_tonyfettes_go_builtin_uintptr_from_uint64"

///|
pub fn UIntPtr::to_byte(self : UIntPtr) -> Byte {
  self.to_uint().to_byte()
}

///|
pub fn UIntPtr::to_int16(self : UIntPtr) -> Int16 {
  self.to_int16()
}

///|
pub fn UIntPtr::to_uint16(self : UIntPtr) -> UInt16 {
  self.to_uint16()
}

///|
pub fn UIntPtr::to_int(self : UIntPtr) -> Int {
  self.to_uint().reinterpret_as_int()
}

///|
pub extern "c" fn UIntPtr::to_uint(self : UIntPtr) -> UInt = "moonbit_tonyfettes_go_builtin_uintptr_to_uint"

///|
pub fn UIntPtr::to_int64(self : UIntPtr) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
pub extern "c" fn UIntPtr::to_uint64(self : UIntPtr) -> UInt64 = "moonbit_tonyfettes_go_builtin_uintptr_to_uint64"

///|
trait ToUIntPtr {
  to_uintptr(self : Self) -> UIntPtr
}

///|
pub impl ToUIntPtr for Byte with to_uintptr(self : Byte) -> UIntPtr {
  UIntPtr::from_byte(self)
}

///|
pub impl ToUIntPtr for Char with to_uintptr(self : Char) -> UIntPtr {
  UIntPtr::from_int(self.to_int())
}

///|
pub impl ToUIntPtr for Int16 with to_uintptr(self : Int16) -> UIntPtr {
  UIntPtr::from_int(self.to_int())
}

///|
pub impl ToUIntPtr for UInt16 with to_uintptr(self : UInt16) -> UIntPtr {
  UIntPtr::from_int(self.to_int())
}

///|
pub impl ToUIntPtr for Int with to_uintptr(self : Int) -> UIntPtr {
  UIntPtr::from_int(self)
}

///|
pub impl ToUIntPtr for UInt with to_uintptr(self : UInt) -> UIntPtr {
  UIntPtr::from_int(self.reinterpret_as_int())
}

///|
pub impl ToUIntPtr for Int64 with to_uintptr(self : Int64) -> UIntPtr {
  UIntPtr::from_uint64(self.reinterpret_as_uint64())
}

///|
pub impl ToUIntPtr for UInt64 with to_uintptr(self : UInt64) -> UIntPtr {
  UIntPtr::from_uint64(self)
}

///|
pub fn[T : ToUIntPtr] uintptr(v : T) -> UIntPtr {
  v.to_uintptr()
}
