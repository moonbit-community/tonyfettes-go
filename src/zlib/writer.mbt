///|
/// ZLIB writer implementation with proper error handling

///|
/// Write the ZLIB header (RFC 1950 section 2.2)
fn Writer::write_header(self : Writer) -> Unit {
  if self.header_written {
    return
  }

  // ZLIB has a two-byte header (as documented in RFC 1950).
  // The first four bits is the CINFO (compression info), which is 7 for the default deflate window size.
  // The next four bits is the CM (compression method), which is 8 for deflate.
  self.scratch[0] = b'\x78'

  // The next two bits is the FLEVEL (compression level). The four values are:
  // 0=fastest, 1=fast, 2=default, 3=best.
  // The next bit, FDICT, is set if a dictionary is given.
  // The final five FCHECK bits form a mod-31 checksum.
  self.scratch[1] = b'\x00'
  if self.dict.length() > 0 {
    self.scratch[1] = (self.scratch[1].to_uint() | (1 << 5)).to_byte()
  }

  // Calculate checksum to make header divisible by 31
  let header_val = get_uint16_be_array(self.scratch, 0)
  let check_bits = 31 - (header_val % 31).reinterpret_as_int()
  self.scratch[1] = (self.scratch[1].to_uint() +
  check_bits.reinterpret_as_uint()).to_byte()

  // Write the 2-byte header to output
  self.output.push(self.scratch[0])
  self.output.push(self.scratch[1])

  // If using a dictionary, write its Adler-32 checksum
  if self.dict.length() > 0 {
    let dict_checksum = checksum_array(self.dict)
    put_uint32_be(self.scratch, 0, dict_checksum)
    for i = 0; i < 4; i = i + 1 {
      self.output.push(self.scratch[i])
    }
  }
  self.header_written = true
}

///|
/// Write data to the ZLIB stream
pub fn Writer::write(self : Writer, data : Bytes) -> Unit {
  // Write header if not already written
  if not(self.header_written) {
    self.write_header()
  }
  if data.length() == 0 {
    return
  }

  // Update digest with original data
  self.digest.write_bytes(data)

  // For this simplified implementation, we're not including actual deflate compression
  // In a complete implementation, this would use a flate compressor to compress the data
  // For now, we'll just append the data directly (this would be replaced with compression)
  for i = 0; i < data.length(); i = i + 1 {
    self.output.push(data[i])
  }
}

///|
/// Flush any pending data
pub fn Writer::flush(self : Writer) -> Unit {
  if not(self.header_written) {
    self.write_header()
  }

  // In a complete implementation, this would flush the underlying compressor
}

///|
/// Close the writer and write the final checksum
pub fn Writer::close(self : Writer) -> Unit {
  if not(self.header_written) {
    self.write_header()
  }

  // Write the Adler-32 checksum (4 bytes, big-endian)
  let checksum_val = self.digest.sum32()
  put_uint32_be(self.scratch, 0, checksum_val)
  for i = 0; i < 4; i = i + 1 {
    self.output.push(self.scratch[i])
  }
}

///|
/// Get the output data
pub fn Writer::to_bytes(self : Writer) -> Bytes {
  [..self.output]
}

///|
/// Reset writer with optional dictionary
pub fn Writer::reset(self : Writer, dict : Bytes) -> Unit {
  self.output = []
  self.digest.reset()
  self.dict = dict
  self.header_written = false
  // Reset scratch buffer
  for i = 0; i < 4; i = i + 1 {
    self.scratch[i] = b'\x00'
  }
}
