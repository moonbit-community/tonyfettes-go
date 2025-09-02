///|
pub fn clone(b : @slice.Slice[Byte]) -> @slice.Slice[Byte] {
  let n : @slice.Slice[Byte] = @slice.make(b.length())
  for i in 0..<b.length() {
    n[i] = b[i]
  }
  n
}
