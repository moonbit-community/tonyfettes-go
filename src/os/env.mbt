///|
pub fn getenv(key : String) -> String {
  let key = @encoding/utf8.encode(key)
  let value = try! @uv.os_getenv(key)
  match value {
    None => ""
    Some(value) => try! @encoding/utf8.decode(value)
  }
}
