///|
struct AtomicUInt(UInt)

///|
pub extern "c" fn make_uint_fixedarray(
  length : Int,
  value : UInt,
) -> FixedArray[AtomicUInt] = "moonbit_tonyfettes_go_sync_atomic_make_uint_array"

///|
#borrow(array)
pub extern "c" fn load_uint32(
  array : FixedArray[AtomicUInt],
  index : Int,
) -> UInt = "moonbit_tonyfettes_go_sync_atomic_load_uint32"

///|
#borrow(array)
pub extern "c" fn store_uint32(
  array : FixedArray[UInt],
  index : Int,
  val : UInt,
) = "moonbit_tonyfettes_go_sync_atomic_store_uint32"
