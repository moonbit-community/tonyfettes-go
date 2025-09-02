// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

///|
pub struct Reader {
  mut r : &@flate.Reader
  mut decompressor : &@io.ReadCloser?
  mut digest : Adler32
  mut err : Error?
  scratch : FixedArray[Byte]
}

///|
/// Resetter resets a ReadCloser returned by NewReader or NewReaderDict
/// to switch to a new underlying Reader. This permits reusing a ReadCloser
/// instead of allocating a new one.
pub(open) trait Resetter {
  /// Reset discards any buffered data and resets the Resetter as if it was
  /// newly initialized with the given reader.
  reset(Self, &@flate.Reader, ArrayView[Byte]) -> Unit raise
}

///|
/// NewReader creates a new ReadCloser.
/// Reads from the returned ReadCloser read and decompress data from r.
/// If r does not implement io.ByteReader, the decompressor may read more
/// data than necessary from r.
/// It is the caller's responsibility to call Close on the ReadCloser when done.
///
/// The io.ReadCloser returned by NewReader also implements Resetter.
pub fn[R : @io.Reader + @io.ByteReader] new_reader(
  r : R,
) -> &@io.ReadCloser raise {
  new_reader_dict(r, [])
}

///|
/// NewReaderDict is like NewReader but uses a preset dictionary.
/// NewReaderDict ignores the dictionary if the compressed data does not refer to it.
/// If the compressed data refers to a different dictionary, NewReaderDict returns ErrDictionary.
///
/// The ReadCloser returned by NewReaderDict also implements Resetter.
pub fn[R : @io.Reader + @io.ByteReader] new_reader_dict(
  r : R,
  dict : ArrayView[Byte],
) -> &@io.ReadCloser raise {
  let z = Reader::{
    r,
    decompressor: None,
    digest: Adler32::new(),
    err: None,
    scratch: FixedArray::make(4, 0),
  }
  z.reset(r, dict)
  z
}

///|
pub impl @io.Reader for Reader with read(self : Reader, p : ArrayView[Byte]) {
  match self.err {
    Some(err) => raise err
    None => ()
  }
  let mut n = 0
  try {
    match self.decompressor {
      Some(decompressor) => n = decompressor.read(p)
      None => {
        self.err = Some(@io.EOF)
        raise @io.EOF
      }
    }
  } catch {
    e => {
      self.err = Some(e)
      match e {
        @io.EOF => () // Handle EOF specially
        _ => raise e
      }
    }
  }

  // Always write what we read to the digest
  self.digest.write(p[0:n])
  match self.err {
    Some(@io.EOF) => {
      // Finished file; check checksum.
      let checksum_buf : ArrayView[Byte] = Array::make(4, (0 : Byte))
      ignore(@io.read_full(self.r, checksum_buf[0:])) catch {
        @io.EOF => {
          self.err = Some(@io.UnexpectedEof)
          raise @io.UnexpectedEof
        }
        e => {
          self.err = Some(e)
          raise e
        }
      }
      // Copy to scratch buffer
      for i = 0; i < 4; i = i + 1 {
        self.scratch[i] = checksum_buf[i]
      }
      // ZLIB (RFC 1950) is big-endian, unlike GZIP (RFC 1952).
      let checksum = get_uint32_be_array(self.scratch, 0)
      if checksum != self.digest.sum32() {
        self.err = Some(ChecksumError)
        raise ChecksumError
      }
      raise @io.EOF
    }
    Some(e) => raise e
    None => n
  }
}

///|
/// Calling Close does not close the wrapped io.Reader originally passed to NewReader.
/// In order for the ZLIB checksum to be verified, the reader must be
/// fully consumed until the io.EOF.
pub impl @io.Closer for Reader with close(self) {
  match self.err {
    Some(@io.EOF) => ()
    Some(e) => raise e
    None => ()
  }
  match self.decompressor {
    Some(decompressor) =>
      decompressor.close() catch {
        e => {
          self.err = Some(e)
          raise e
        }
      }
    None => ()
  }
}

///|
pub impl Resetter for Reader with reset(self, r, dict : ArrayView[Byte]) {
  // Reset all fields like in Go: *z = reader{decompressor: z.decompressor}
  self.err = None
  self.r = r

  // Read the header (RFC 1950 section 2.2.).
  let header_buf : ArrayView[Byte] = Array::make(2, (0 : Byte))
  ignore(@io.read_full(self.r, header_buf[0:])) catch {
    @io.EOF => {
      self.err = Some(@io.UnexpectedEof)
      raise @io.UnexpectedEof
    }
    e => {
      self.err = Some(e)
      raise e
    }
  }
  // Copy to scratch buffer
  for i = 0; i < 2; i = i + 1 {
    self.scratch[i] = header_buf[i]
  }
  let h = get_uint16_be_array(self.scratch, 0)
  if (self.scratch[0] & 0x0f) != ZlibDeflate.to_byte() ||
    self.scratch[0] >> 4 > ZlibMaxWindow.to_byte() ||
    h % 31 != 0 {
    self.err = Some(HeaderError)
    raise HeaderError
  }
  let have_dict = (self.scratch[1] & 0x20) != 0
  if have_dict {
    let dict_checksum_buf : ArrayView[Byte] = Array::make(4, (0 : Byte))
    ignore(@io.read_full(self.r, dict_checksum_buf[0:])) catch {
      @io.EOF => {
        self.err = Some(@io.UnexpectedEof)
        raise @io.UnexpectedEof
      }
      e => {
        self.err = Some(e)
        raise e
      }
    }
    // Copy to scratch buffer
    for i = 0; i < 4; i = i + 1 {
      self.scratch[i] = dict_checksum_buf[i]
    }
    let checksum = get_uint32_be_array(self.scratch, 0)
    if checksum != checksum_bytes(dict) {
      self.err = Some(DictionaryError)
      raise DictionaryError
    }
  }
  match self.decompressor {
    None =>
      if have_dict {
        self.decompressor = Some(@flate.new_reader_dict(self.r, dict[0:]))
      } else {
        self.decompressor = Some(@flate.new_reader(self.r))
      }
    Some(decompressor) =>
      // Reset existing decompressor using flate.Resetter interface
      // FIXME: Need to check if flate readers implement Resetter trait
      if have_dict {
        self.decompressor = Some(@flate.new_reader_dict(self.r, dict[0:]))
      } else {
        self.decompressor = Some(@flate.new_reader(self.r))
      }
  }
  self.digest = Adler32::new()
}
