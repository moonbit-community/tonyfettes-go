///|
/// ZLIB reader implementation with proper error handling

///|
/// Read and validate the ZLIB header (RFC 1950 section 2.2)
fn Reader::read_header(self : Reader) -> Unit raise {
  if self.header_read {
    return
  }
  if self.offset + 2 > self.reader.length() {
    raise HeaderError("insufficient data for header")
  }

  // Read the 2-byte header
  let byte0 = self.reader[self.offset]
  let byte1 = self.reader[self.offset + 1]
  self.offset += 2

  // Store in scratch for checksum calculation
  self.scratch[0] = byte0
  self.scratch[1] = byte1
  let h = get_uint16_be_array(self.scratch, 0)

  // Check compression method (CM) - must be 8 (deflate)
  if (byte0 & 0x0f) != zlib_deflate {
    raise HeaderError("invalid compression method")
  }

  // Check compression info (CINFO) - must not exceed 7 
  if byte0 >> 4 > zlib_max_window {
    raise HeaderError("invalid window size")
  }

  // Check header checksum (FCHECK) - header must be divisible by 31
  if h % 31 != 0 {
    raise HeaderError("invalid header checksum")
  }

  // Check if preset dictionary is used (FDICT flag)
  let have_dict = (byte1 & 0x20) != 0
  if have_dict {
    if self.offset + 4 > self.reader.length() {
      raise HeaderError("insufficient data for dictionary checksum")
    }

    // Read 4-byte dictionary checksum
    for i = 0; i < 4; i = i + 1 {
      self.scratch[i] = self.reader[self.offset + i]
    }
    self.offset += 4
    let _dict_checksum = get_uint32_be_array(self.scratch, 0)
    // Note: In real implementation, we'd need to validate against provided dictionary
    // For now, we'll store this for potential future validation
  }
  self.header_read = true
}

///|
/// Read some bytes from the stream
pub fn Reader::read(self : Reader, buf : Bytes) -> Int raise {
  // Read header if not already read
  if not(self.header_read) {
    self.read_header()
  }
  let remaining = self.reader.length() - self.offset

  // Check if we're at the end (need to read checksum)
  if remaining <= 4 {
    // Read the final checksum
    if remaining < 4 {
      raise ChecksumError("insufficient data for checksum")
    }
    for i = 0; i < 4; i = i + 1 {
      self.scratch[i] = self.reader[self.offset + i]
    }
    let expected_checksum = get_uint32_be_array(self.scratch, 0)
    let actual_checksum = self.digest.sum32()
    if expected_checksum != actual_checksum {
      raise ChecksumError(
        "checksum mismatch: expected \{expected_checksum}, got \{actual_checksum}",
      )
    }
    return 0 // EOF
  }

  // For this simplified implementation, we're not including actual deflate decompression
  // In a complete implementation, this would use a flate decompressor
  // For now, we'll just copy some uncompressed data (minus the final 4 checksum bytes)

  let to_read = min(buf.length(), remaining - 4)
  if to_read <= 0 {
    return 0
  }
  for i = 0; i < to_read; i = i + 1 {
    buf[i] = self.reader[self.offset + i]
  }
  self.offset += to_read

  // Update digest with read data (in real implementation, this would be uncompressed data)
  // We'll create a temporary array to pass to digest
  let read_data = Array::make(to_read, b'\x00')
  for i = 0; i < to_read; i = i + 1 {
    read_data[i] = buf[i]
  }
  self.digest.write_array(read_data)
  to_read
}

///|
/// Reset reader with new input and optional dictionary
pub fn Reader::reset(self : Reader, data : Bytes, _dict : Bytes) -> Unit {
  self.reader = data
  self.offset = 0
  self.digest.reset()
  self.header_read = false
  // Reset scratch buffer
  for i = 0; i < 4; i = i + 1 {
    self.scratch[i] = b'\x00'
  }
}

///|
/// Helper function to get minimum of two integers
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}
