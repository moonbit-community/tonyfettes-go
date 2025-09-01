///|
/// ZLIB writer implementation with proper error handling

///|
/// Write the ZLIB header (RFC 1950 section 2.2)
fn Writer::write_header(self : Writer) -> Unit raise {
  if self.header_written {
    return
  }

  // ZLIB has a two-byte header (as documented in RFC 1950).
  // The first four bits is the CINFO (compression info), which is 7 for the default deflate window size.
  // The next four bits is the CM (compression method), which is 8 for deflate.
  self.scratch[0] = 0x78

  // The next two bits is the FLEVEL (compression level). The four values are:
  // 0=fastest, 1=fast, 2=default, 3=best.
  // The next bit, FDICT, is set if a dictionary is given.
  // The final five FCHECK bits form a mod-31 checksum.
  self.scratch[1] = 0x80 // Default compression level (2 << 6)
  if self.dict.length() > 0 {
    self.scratch[1] = self.scratch[1] | (1 << 5)
  }

  // Calculate checksum to make header divisible by 31
  // Create a temporary header with current values to calculate check bits
  let temp_header = (self.scratch[0].to_uint() << 8) | self.scratch[1].to_uint()
  let remainder = temp_header % 31
  let check_bits : UInt = if remainder == 0 { 0 } else { 31 - remainder }
  self.scratch[1] = (self.scratch[1].to_uint() + check_bits).to_byte()

  // Write the 2-byte header to underlying writer
  ignore(self.w.write([self.scratch[0], self.scratch[1]]))

  // If using a dictionary, write its Adler-32 checksum
  if self.dict.length() > 0 {
    let dict_checksum = checksum(self.dict)
    put_uint32_be(self.scratch, 0, dict_checksum)
    let checksum_bytes : Bytes = [
      self.scratch[0],
      self.scratch[1],
      self.scratch[2],
      self.scratch[3],
    ]
    ignore(self.w.write(checksum_bytes))
  }
  self.header_written = true
}

///|
/// Write data to the ZLIB stream
/// Returns the number of bytes written from data and any error encountered
pub fn Writer::write(self : Writer, data : Bytes) -> Int raise {
  // Check for previous errors
  match self.err {
    Some(err) => raise err
    None => ()
  }

  // Write header if not already written
  if not(self.header_written) {
    self.write_header() catch {
      e => {
        self.err = Some(e)
        raise e
      }
    }
  }
  if data.length() == 0 {
    return 0
  }

  // Update digest with original data
  self.digest.write_bytes(data)

  // For this simplified implementation, we're not including actual deflate compression
  // In a complete implementation, this would use a flate compressor to compress the data
  // For now, we'll just write the data directly (this would be replaced with compression)
  try {
    let n = self.w.write(data)
    return n
  } catch {
    e => {
      self.err = Some(e)
      raise e
    }
  }
}

///|
/// Flush any pending data to the underlying writer
pub fn Writer::flush(self : Writer) -> Unit raise {
  // Check for previous errors
  match self.err {
    Some(err) => raise err
    None => ()
  }
  if not(self.header_written) {
    self.write_header() catch {
      e => {
        self.err = Some(e)
        raise e
      }
    }
  }

  // In a complete implementation, this would flush the underlying compressor
  // For now, no additional flushing is needed since we write directly
}

///|
/// Close the writer and write the final checksum
pub fn Writer::close(self : Writer) -> Unit raise {
  // Check for previous errors
  match self.err {
    Some(err) => raise err
    None => ()
  }
  if not(self.header_written) {
    self.write_header() catch {
      e => {
        self.err = Some(e)
        raise e
      }
    }
  }

  // Write the Adler-32 checksum (4 bytes, big-endian)
  let checksum_val = self.digest.sum32()
  put_uint32_be(self.scratch, 0, checksum_val)
  let checksum_bytes : Bytes = [
    self.scratch[0],
    self.scratch[1],
    self.scratch[2],
    self.scratch[3],
  ]
  ignore(self.w.write(checksum_bytes)) catch {
    e => {
      self.err = Some(e)
      raise e
    }
  }
}

///|
/// Reset clears the state of the Writer such that it is equivalent to its
/// initial state from new, but instead writing to w.
/// This permits reusing a Writer rather than allocating a new one.
pub fn Writer::reset(self : Writer, w : &@io.Writer) -> Unit {
  self.w = w
  self.digest.reset()
  self.header_written = false
  self.err = None
  // Reset scratch buffer
  for i = 0; i < 4; i = i + 1 {
    self.scratch[i] = 0
  }
}

///|
/// Reset the writer with a new underlying writer and dictionary
pub fn Writer::reset_dict(self : Writer, w : &@io.Writer, dict : Bytes) -> Unit {
  self.reset(w)
  self.dict = dict
}
