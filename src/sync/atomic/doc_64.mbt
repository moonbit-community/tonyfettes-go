///|
struct AtomicUInt64(UInt64)

///|
pub extern "c" fn make_uint64_fixedarray(
  length : Int,
  value : UInt64,
) -> FixedArray[AtomicUInt64] = "moonbit_tonyfettes_go_sync_atomic_make_uint64_array"

///|
#borrow(array)
pub extern "c" fn load_uint64(
  array : FixedArray[AtomicUInt64],
  index : Int,
) -> UInt64 = "moonbit_tonyfettes_go_sync_atomic_load_uint64"

///|
#borrow(array)
pub extern "c" fn compare_and_swap_uint64(
  array : FixedArray[AtomicUInt64],
  index : Int,
  old : UInt64,
  new : UInt64,
) -> Bool = "moonbit_tonyfettes_go_sync_atomic_compare_and_swap_uint64"
