///|
#borrow(array)
pub extern "c" fn store_uint32(
  array : FixedArray[UInt],
  index : Int,
  val : UInt,
) -> Unit = "moonbit_tonyfettes_go_sync_atomic_store_uint32"
