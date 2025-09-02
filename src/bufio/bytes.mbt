///|
fn Bytes::op_set(self : Bytes, index : Int, value : Byte) -> Unit = "%fixedarray.set"

///|
fn @bytes.View::op_set(self : @bytes.View, index : Int, value : Byte) -> Unit {
  self.data()[self.start_offset() + index] = value
}
