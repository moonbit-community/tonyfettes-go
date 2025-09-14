///|
#external
pub type UIntPtr

///|
pub extern "c" fn UIntPtr::from_uint64(v : UInt64) -> UIntPtr = "moonbit_tonyfettes_go_builtin_uintptr_from_uint64"

///|
pub extern "c" fn UIntPtr::from_int(v : Int) -> UIntPtr = "moonbit_tonyfettes_go_builtin_uintptr_from_int"

///|
pub extern "c" fn UIntPtr::to_uint64(self : UIntPtr) -> UInt64 = "moonbit_tonyfettes_go_builtin_uintptr_to_uint64"

///|
pub extern "c" fn UIntPtr::to_int(self : UIntPtr) -> Int = "moonbit_tonyfettes_go_builtin_uintptr_to_int"

///|
trait ToUIntPtr {
  to_uintptr(self : Self) -> UIntPtr
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

///|
trait ToInt64 {
  to_int64(self : Self) -> Int64
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

///|
trait ToInt {
  to_int(self : Self) -> Int
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
