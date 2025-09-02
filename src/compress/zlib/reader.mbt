// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

///|
const ZlibDeflate = 8

///|
const ZlibMaxWindow = 7

///|
pub suberror ChecksumError

///|
pub impl Show for ChecksumError with output(_ : ChecksumError, logger : &Logger) {
  logger.write_string("zlib: checksum error")
}

///|
pub suberror DictionaryError

///|
pub impl Show for DictionaryError with output(
  _ : DictionaryError,
  logger : &Logger,
) {
  logger.write_string("zlib: dictionary error")
}

///|
pub suberror HeaderError

///|
pub impl Show for HeaderError with output(_ : HeaderError, logger : &Logger) {
  logger.write_string("zlib: invalid header")
}

///|
priv struct Reader {
  mut r : &@flate.Reader
  mut decompressor : &@io.ReadCloser
  mut digest : Adler32
  mut err : Error?
  scratch : FixedArray[Byte]
}

///|
/// Resetter resets a ReadCloser returned by NewReader or NewReaderDict
/// to switch to a new underlying Reader. This permits reusing a ReadCloser
/// instead of allocating a new one.
pub trait Resetter {
  /// Reset discards any buffered data and resets the Resetter as if it was
  /// newly initialized with the given reader.
  reset(Self, &@io.Reader, @bytes.View) -> Unit raise
}

///|
/// NewReader creates a new ReadCloser.
/// Reads from the returned ReadCloser read and decompress data from r.
/// If r does not implement io.ByteReader, the decompressor may read more
/// data than necessary from r.
/// It is the caller's responsibility to call Close on the ReadCloser when done.
///
/// The io.ReadCloser returned by NewReader also implements Resetter.
pub fn[R : @flate.Reader] new_reader(r : R) -> &@io.Reader raise {
  new_reader_dict(r, b"")
}

///|
/// NewReaderDict is like NewReader but uses a preset dictionary.
/// NewReaderDict ignores the dictionary if the compressed data does not refer to it.
/// If the compressed data refers to a different dictionary, NewReaderDict returns ErrDictionary.
///
/// The ReadCloser returned by NewReaderDict also implements Resetter.
pub fn[R : @flate.Reader] new_reader_dict(
  r : R,
  dict : Bytes,
) -> &@io.ReadCloser raise {
  let z = Reader::{
    r: {
      let t : &@flate.Reader = r
      t
    },
    decompressor: {
      let null : &@io.ReadCloser = @flate.new_reader(r)
      null
    },
    digest: Adler32::new(),
    err: None,
    scratch: FixedArray::make(4, 0),
  }
  z.reset(r, dict)
  z
}

///|
impl @io.Reader for Reader with read(self, p) {
  match self.err {
    Some(err) => raise err
    None => ()
  }
  let mut n = 0
  try {
    n = self.decompressor.read(p)
    self.digest.write(p[0:n])
  } catch {
    e => {
      self.err = Some(e)
      match e {
        @io.EOF => () // Handle EOF specially
        _ => raise e
      }
    }
  }
  match self.err {
    Some(@io.EOF) => {
      // Finished file; check checksum.
      // Create a temporary bytes buffer for the scratch operation
      let scratch_bytes = Bytes::make(4, 0)
      ignore(@io.read_full(self.r, scratch_bytes)) catch {
        @io.EOF => {
          self.err = Some(@io.UnexpectedEof)
          raise @io.UnexpectedEof
        }
        e => {
          self.err = Some(e)
          raise e
        }
      }
      // Copy the result back to our scratch buffer
      for i = 0; i < 4; i = i + 1 {
        self.scratch[i] = scratch_bytes[i]
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
impl @io.Closer for Reader with close(self) {
  match self.err {
    Some(@io.EOF) => ()
    Some(e) => raise e
    None => ()
  }
  self.decompressor.close() catch {
    e => {
      self.err = Some(e)
      raise e
    }
  }
}

///|
impl Resetter for Reader with reset(
  self : Reader,
  r : &@io.Reader,
  dict : @bytes.View,
) -> Unit raise {
  self.err = None

  // Store the reader
  self.r = r

  // Read the header (RFC 1950 section 2.2.).
  let header_bytes = Bytes::make(2, 0)
  ignore(@io.read_full(self.r, header_bytes)) catch {
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
    self.scratch[i] = header_bytes[i]
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
    let dict_bytes = Bytes::make(4, 0)
    ignore(@io.read_full(self.r, dict_bytes)) catch {
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
      self.scratch[i] = dict_bytes[i]
    }
    let checksum = get_uint32_be_array(self.scratch, 0)
    if checksum != checksum_bytesview(dict) {
      self.err = Some(DictionaryError)
      raise DictionaryError
    }
  }
  if have_dict {
    self.decompressor = @flate.new_reader_dict(self.r, dict)
  } else {
    self.decompressor = @flate.new_reader(self.r)
  }
  self.digest = Adler32::new()
}
