///|
pub fn bytes_from_string(s : String) -> Bytes {
  @utf8.encode(s)
}
