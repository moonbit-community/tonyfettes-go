///|
/// Adler-32 checksum implementation
/// As defined in RFC 1950

// adler32 mod values
let mod_adler : UInt = 65521

///|
/// Adler32 state for incremental checksum calculation
pub struct Adler32 {
  mut a : UInt
  mut b : UInt
} derive(Show)

///|
/// Create a new Adler32 checksum
pub fn Adler32::new() -> Adler32 {
  { a: 1, b: 0 }
}

///|
/// Update the checksum with new data from a View
pub fn Adler32::write(self : Adler32, data : @bytes.View) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.a = (self.a + data[i].to_uint()) % mod_adler
    self.b = (self.b + self.a) % mod_adler
  }
}

///|
pub fn Adler32::write_bytes(self : Adler32, data : Bytes) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.a = (self.a + data[i].to_uint()) % mod_adler
    self.b = (self.b + self.a) % mod_adler
  }
}

///|
/// Update the checksum with new data from an Array
pub fn Adler32::write_array(self : Adler32, data : Array[Byte]) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.a = (self.a + data[i].to_uint()) % mod_adler
    self.b = (self.b + self.a) % mod_adler
  }
}

///|
pub fn Adler32::write_arrayview(self : Adler32, data : ArrayView[Byte]) -> Unit {
  for i = 0; i < data.length(); i = i + 1 {
    self.a = (self.a + data[i].to_uint()) % mod_adler
    self.b = (self.b + self.a) % mod_adler
  }
}

///|
/// Get the final checksum value
pub fn Adler32::sum32(self : Adler32) -> UInt {
  (self.b << 16) | self.a
}

///|
/// Reset the checksum to initial state
pub fn Adler32::reset(self : Adler32) -> Unit {
  self.a = 1
  self.b = 0
}

///|
/// Compute Adler32 checksum of data in one go (View)
pub fn checksum(data : @bytes.View) -> UInt {
  let adler = Adler32::new()
  adler.write(data)
  adler.sum32()
}

///|
/// Compute Adler32 checksum of data in one go (Array)
pub fn checksum_array(data : Array[Byte]) -> UInt {
  let adler = Adler32::new()
  adler.write_array(data)
  adler.sum32()
}
