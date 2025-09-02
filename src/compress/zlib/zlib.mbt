///|
/// ZLIB package implementing RFC 1950 compression format
/// Provides readers and writers for zlib-compressed data

// ZLIB constants
let zlib_deflate : Byte = b'\x08'

///|
let zlib_max_window : Byte = b'\x07'

///|
/// ZLIB-specific errors
pub suberror ChecksumError String

///|
pub suberror DictionaryError String

///|
pub suberror HeaderError String

///|
/// Reader for reading zlib-compressed data
pub struct Reader {
  mut reader : Bytes // For simplicity, we'll read from byte arrays
  mut offset : Int
  digest : Adler32 // Has reference semantics, no mut needed
  scratch : FixedArray[Byte] // Has reference semantics, no mut needed
  mut header_read : Bool
} derive(Show)

///|
/// Writer for writing zlib-compressed data
pub struct Writer {
  mut w : &@io.Writer
  digest : Adler32 // Has reference semantics, no mut needed
  mut dict : Bytes
  scratch : FixedArray[Byte] // Has reference semantics, no mut needed
  mut header_written : Bool
  mut err : Error? // Store any write errors
} derive(Show)

///|
/// Create a new ZLIB reader from byte data
pub fn Reader::new(data : Bytes) -> Reader {
  Reader::new_dict(data, [])
}

///|
/// Create a new ZLIB reader with a preset dictionary
pub fn Reader::new_dict(data : Bytes, _dict : Bytes) -> Reader {
  {
    reader: data,
    offset: 0,
    digest: Adler32::new(),
    scratch: FixedArray::make(4, 0),
    header_read: false,
  }
}

///|
/// Create a new ZLIB writer that writes compressed data to w
pub fn Writer::new(w : &@io.Writer) -> Writer {
  Writer::new_dict(w, [])
}

///|
/// Create a new ZLIB writer with a preset dictionary that writes compressed data to w
pub fn Writer::new_dict(w : &@io.Writer, dict : Bytes) -> Writer {
  {
    w,
    digest: Adler32::new(),
    dict,
    scratch: FixedArray::make(4, 0),
    header_written: false,
    err: None,
  }
}
