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
