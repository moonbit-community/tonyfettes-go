/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// Package zlib implements reading and writing of zlib format compressed data,
/// as specified in RFC 1950.
///
/// The implementation provides filters that uncompress during reading
/// and compress during writing.  For example, to write compressed data
/// to a buffer:
///
/// 	var b bytes.Buffer
/// 	w := zlib.NewWriter(&b)
/// 	w.Write([]byte("hello, world\n"))
/// 	w.Close()
///
/// and to read that data back:
///
/// 	r, err := zlib.NewReader(&b)
/// 	io.Copy(os.Stdout, r)
/// 	r.Close()

///|
/// These constants are copied from the flate package, so that code that imports
/// compress/zlib does not also have to import compress/flate.
pub const NoCompression : Int = @flate.NoCompression

///|
pub const BestSpeed : Int = @flate.BestSpeed

///|
pub const BestCompression : Int = @flate.BestCompression

///|
pub const DefaultCompression : Int = @flate.DefaultCompression

///|
pub const HuffmanOnly : Int = @flate.HuffmanOnly

///|
const ZlibDeflate : Int = 8

///|
const ZlibMaxWindow : Int = 7

///|
/// ErrChecksum is returned when reading ZLIB data that has an invalid checksum.
pub suberror ChecksumError

///|
pub impl Show for ChecksumError with output(
  _elf : ChecksumError,
  logger : &Logger,
) {
  logger.write_string("zlib: invalid checksum")
}

///|
/// ErrDictionary is returned when reading ZLIB data that has an invalid dictionary.
pub suberror DictionaryError

///|
pub impl Show for DictionaryError with output(
  _ : DictionaryError,
  logger : &Logger,
) {
  logger.write_string("zlib: invalid dictionary")
}

///|
/// ErrHeader is returned when reading ZLIB data that has an invalid header.
pub suberror HeaderError

///|
pub impl Show for HeaderError with output(_ : HeaderError, logger : &Logger) {
  logger.write_string("zlib: invalid header")
}
