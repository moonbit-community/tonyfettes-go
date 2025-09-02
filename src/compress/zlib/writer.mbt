// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

///|
/// A Writer takes data written to it and writes the compressed
/// form of that data to an underlying writer (see NewWriter).
pub struct Writer {
  mut w : &@io.Writer
  level : Int
  dict : Bytes
  mut compressor : @flate.Writer?
  mut digest : Adler32
  mut err : Error?
  scratch : FixedArray[Byte]
  mut wrote_header : Bool
}

///|
/// NewWriter creates a new Writer.
/// Writes to the returned Writer are compressed and written to w.
///
/// It is the caller's responsibility to call Close on the Writer when done.
/// Writes may be buffered and not flushed until Close.
pub fn new_writer(w : &@io.Writer) -> Writer {
  let (z, _) = new_writer_level_dict(w, DefaultCompression, b"")
  z
}

///|
/// NewWriterLevel is like NewWriter but specifies the compression level instead
/// of assuming DefaultCompression.
///
/// The compression level can be DefaultCompression, NoCompression, HuffmanOnly
/// or any integer value between BestSpeed and BestCompression inclusive.
/// The error returned will be nil if the level is valid.
pub fn new_writer_level(w : &@io.Writer, level : Int) -> (Writer, Error?) {
  new_writer_level_dict(w, level, b"")
}

///|
/// NewWriterLevelDict is like NewWriterLevel but specifies a dictionary to
/// compress with.
///
/// The dictionary may be empty. If not, its contents should not be modified until
/// the Writer is closed.
pub fn new_writer_level_dict(
  w : &@io.Writer,
  level : Int,
  dict : Bytes,
) -> (Writer, Error?) {
  if level < HuffmanOnly || level > BestCompression {
    return (
      Writer::{
        w,
        level: DefaultCompression,
        dict: b"",
        compressor: None,
        digest: Adler32::new(),
        err: None,
        scratch: FixedArray::make(4, 0),
        wrote_header: false,
      },
      Some(InvalidCompressionLevel(level)),
    )
  }
  (
    Writer::{
      w,
      level,
      dict,
      compressor: None,
      digest: Adler32::new(),
      err: None,
      scratch: FixedArray::make(4, 0),
      wrote_header: false,
    },
    None,
  )
}

///|
/// Reset clears the state of the Writer z such that it is equivalent to its
/// initial state from NewWriterLevel or NewWriterLevelDict, but instead writing
/// to w.
pub fn Writer::reset(self : Writer, w : &@io.Writer) -> Unit {
  self.w = w
  // z.level and z.dict left unchanged.
  match self.compressor {
    Some(compressor) => compressor.reset(w)
    None => ()
  }
  self.digest.reset()
  self.err = None
  for i = 0; i < 4; i = i + 1 {
    self.scratch[i] = 0
  }
  self.wrote_header = false
}

///|
/// writeHeader writes the ZLIB header.
fn Writer::write_header(self : Writer) -> Unit raise {
  self.wrote_header = true
  // ZLIB has a two-byte header (as documented in RFC 1950).
  // The first four bits is the CINFO (compression info), which is 7 for the default deflate window size.
  // The next four bits is the CM (compression method), which is 8 for deflate.
  self.scratch[0] = 0x78
  // The next two bits is the FLEVEL (compression level). The four values are:
  // 0=fastest, 1=fast, 2=default, 3=best.
  // The next bit, FDICT, is set if a dictionary is given.
  // The final five FCHECK bits form a mod-31 checksum.
  match self.level {
    -2 | 0 | 1 => self.scratch[1] = 0 << 6
    2 | 3 | 4 | 5 => self.scratch[1] = 1 << 6
    6 | -1 => self.scratch[1] = 2 << 6
    7 | 8 | 9 => self.scratch[1] = 3 << 6
    _ => abort("unreachable")
  }
  if self.dict.length() != 0 {
    self.scratch[1] = self.scratch[1] | (1 << 5)
  }
  self.scratch[1] = self.scratch[1] +
    (31 - get_uint16_be_array(self.scratch, 0) % 31).to_byte()
  let header_bytes = Bytes::make(2, 0)
  header_bytes[0] = self.scratch[0]
  header_bytes[1] = self.scratch[1]
  ignore(self.w.write(header_bytes)) catch {
    e => raise e
  }
  if self.dict.length() != 0 {
    // The next four bytes are the Adler-32 checksum of the dictionary.
    put_uint32_be(self.scratch, 0, checksum_bytes(self.dict))
    let checksum_bytes = Bytes::make(4, 0)
    for i = 0; i < 4; i = i + 1 {
      checksum_bytes[i] = self.scratch[i]
    }
    ignore(self.w.write(checksum_bytes)) catch {
      e => raise e
    }
  }
  if self.compressor.is_empty() {
    // Initialize deflater unless the Writer is being reused
    // after a Reset call.
    self.compressor = Some(
      @flate.new_writer_dict(
        self.w,
        self.level,
        Array::from_iter(self.dict.iter()),
      ),
    )
    self.digest = Adler32::new()
  }
}

///|
/// Write writes a compressed form of p to the underlying io.Writer. The
/// compressed bytes are not necessarily flushed until the Writer is closed or
/// explicitly flushed.
pub impl @io.Writer for Writer with write(self, p) {
  if not(self.wrote_header) {
    self.write_header() catch {
      e => {
        self.err = Some(e)
        raise e
      }
    }
  }
  match self.err {
    Some(err) => raise err
    None => ()
  }
  if p.length() == 0 {
    return 0
  }
  let n = match self.compressor {
    Some(compressor) =>
      compressor.write(p) catch {
        e => {
          self.err = Some(e)
          raise e
        }
      }
    None => {
      self.err = Some(InternalError("compressor not initialized"))
      raise InternalError("compressor not initialized")
    }
  }
  self.digest.write(p)
  n
}

///|
/// Flush flushes the Writer to its underlying io.Writer.
pub fn Writer::flush(self : Writer) -> Unit raise {
  if !self.wrote_header {
    self.write_header()
  }
  if self.err is Some(err) {
    raise err
  }
  if self.compressor is Some(compressor) {
    compressor.flush()
  }
}

///|
/// Close closes the Writer, flushing any unwritten data to the underlying
/// io.Writer, but does not close the underlying io.Writer.
impl @io.Closer for Writer with close(self) {
  if !self.wrote_header {
    self.write_header()
  }
  if self.err is Some(err) {
    raise err
  }
  if self.compressor is Some(compressor) {
    compressor.close()
  }
  let checksum = self.digest.sum32()
  // ZLIB (RFC 1950) is big-endian, unlike GZIP (RFC 1952).
  put_uint32_be(self.scratch, 0, checksum)
  let checksum_bytes = Bytes::make(4, 0)
  for i = 0; i < 4; i = i + 1 {
    checksum_bytes[i] = self.scratch[i]
  }
  ignore(self.w.write(checksum_bytes)) catch {
    e => {
      self.err = Some(e)
      raise e
    }
  }
}

///|
suberror InvalidCompressionLevel Int
