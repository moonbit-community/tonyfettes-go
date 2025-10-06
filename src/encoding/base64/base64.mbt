// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package base64 implements base64 encoding as specified by RFC 4648.

//
// Encodings
//

///|
/// An `Encoding` is a radix 64 encoding/decoding scheme, defined by a
/// 64-character alphabet. The most common encoding is the "base64"
/// encoding defined in RFC 4648 and used in MIME (RFC 2045) and PEM
/// (RFC 1421).  RFC 4648 also defines an alternate encoding, which is
/// the standard encoding with - and _ substituted for + and /.
pub struct Encoding {
  /// mapping of symbol index to symbol byte value
  encode : FixedArray[Byte]
  /// mapping of symbol byte value to symbol index
  decode_map : FixedArray[Byte]
  pad_char : Char?
  strict : Bool
}

///|
pub const StdPadding : Char = '='

///|
const InvalidIndex : Byte = 0xFF

///|
/// `new_encoding` returns a new padded Encoding defined by the given alphabet,
/// which must be a 64-byte string that contains unique byte values and
/// does not contain the padding character or CR / LF ('\r', '\n').
/// The alphabet is treated as a sequence of byte values
/// without any special treatment for multi-byte UTF-8.
/// The resulting Encoding uses the default padding character ('='),
/// which may be changed or disabled via [Encoding.WithPadding].
pub fn new_encoding(encoder : Bytes) -> Encoding {
  if encoder.length() != 64 {
    abort("encoding alphabet is not 64-bytes long")
  }
  let encode : FixedArray[Byte] = FixedArray::make(64, 0)
  encode.blit_from_bytes(0, encoder, 0, 64)
  let decode_map = FixedArray::make(256, InvalidIndex)
  for i, c in encoder {
    if c is ('\n' | '\r') {
      abort("encoding alphabet contains newline character")
    }
    if decode_map[c.to_int()] != InvalidIndex {
      abort("encoding alphabet contains duplicate character")
    }
    decode_map[c.to_int()] = i.to_byte()
  }
  Encoding::{ encode, decode_map, pad_char: Some(StdPadding), strict: false }
}

///|
pub let std_encoding : Encoding = new_encoding(
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
)

///|
pub let url_encoding : Encoding = new_encoding(
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
)

//
// Encoder
//

///|
/// `encode` encodes src using the encoding enc,
/// writing [Encoding.EncodedLen](len(src)) bytes to dst.
///
/// The encoding pads the output to a multiple of 4 bytes,
/// so Encode is not appropriate for use on individual blocks
/// of a large data stream. Use [NewEncoder] instead.
pub fn Encoding::decode(
  enc : Encoding,
  dst : @slice.Slice[Byte],
  src : @slice.Slice[Byte],
) -> Int raise {
  let mut n : Int = 0
  if src.length() == 0 {
    return 0
  }
  let mut si = 0
  while src.length() - si >= 4 && dst.length() - n >= 4 {
    let src2 = src[si:si + 4]
    if assemble32(
        enc.decode_map[src2[0].to_int()],
        enc.decode_map[src2[1].to_int()],
        enc.decode_map[src2[2].to_int()],
        enc.decode_map[src2[3].to_int()],
      )
      is (dn, true) {
      @binary.BigEndian.put_uint32(dst[n:], dn)
      n += 3
      si += 4
    } else {
      let (sii, ninc) = enc.decode_quantum(dst[n:], src, si)
      si = sii
      n += ninc
    }
  }
  while si < src.length() {
    let (sii, ninc) = enc.decode_quantum(dst[n:], src, si)
    si = sii
    n += ninc
  }
  return n
}

//
// Decoder
//

///|
suberror CorruptInputError Int64

///|
pub impl Show for CorruptInputError with output(
  self : CorruptInputError,
  logger : &Logger,
) -> Unit {
  let CorruptInputError(value) = self
  logger.write_string("illegal base64 data at input byte \{value}")
}

///|
fn Encoding::decode_quantum(
  self : Encoding,
  dst : @slice.Slice[Byte],
  src : @slice.Slice[Byte],
  si : Int,
) -> (Int, Int) raise {
  let mut si = si
  let dbuf : FixedArray[Byte] = FixedArray::make(4, 0)
  let mut dlen = 4
  let mut err = None
  for j in 0..<dbuf.length() {
    if src.length() == si {
      if j == 0 {
        return (si, 0)
      } else if j == 1 && self.pad_char is Some(_) {
        raise CorruptInputError(int64(si - j))
      }
      dlen = j
      break
    }
    let in_ = src[si]
    si += 1
    let out = self.decode_map[in_.to_int()]
    if out != 0xff {
      dbuf[j] = out
      continue
    }
    if in_ is ('\n' | '\r') {
      continue j
    }
    if self.pad_char is Some(c) && in_.to_char() == c {
      raise CorruptInputError(int64(si - 1))
    }

    // We've reached the end and there's padding
    match j {
      0 | 1 => raise CorruptInputError(int64(si - 1))
      2 => {
        while si < src.length() && src[si] is ('\n' | '\r') {
          si += 1
        }
        if si == src.length() {
          // not enough padding
          raise CorruptInputError(int64(src.length()))
        }
        if self.pad_char is None ||
          (self.pad_char is Some(c) && src[si].to_char() != c) {
          // incorrect padding
          raise CorruptInputError(int64(si))
        }
        si += 1
      }
      _ => ()
    }

    // skip over newlines
    while si < src.length() && src[si] is ('\n' | '\r') {
      si += 1
    }
    if si < src.length() {
      err = Some(CorruptInputError(int64(si)))
    }
    dlen = j
    break
  }
  let val = (uint(dbuf[0]) << 18) |
    (uint(dbuf[1]) << 12) |
    (uint(dbuf[2]) << 6) |
    uint(dbuf[3])
  dbuf[2] = (val >> 16).to_byte()
  dbuf[1] = (val >> 8).to_byte()
  dbuf[0] = val.to_byte()
  if dlen == 4 {
    dst[2] = dbuf[2]
    dbuf[2] = 0
  }
  if dlen is (4 | 3) {
    dst[1] = dbuf[1]
    if self.strict && dbuf[2] != 0 {
      raise CorruptInputError(int64(si - 1))
    }
    dbuf[1] = 0
  }
  if dlen is (4 | 3 | 2) {
    dst[0] = dbuf[0]
    if self.strict && dbuf[1] != 0 {
      raise CorruptInputError(int64(si - 2))
    }
  }
  if err is Some(err) {
    raise err
  }
  return (si, dlen - 1)
}

///|
priv struct Decoder {
  mut err : Error?
  /// error from r.read
  read_err : Error?
  enc : Encoding
  r : &@io.Reader
  /// leftover input
  buf : FixedArray[Byte] // [1024]byte
  mut nbuf : Int
  /// leftover decoded output
  mut out : @slice.Slice[Byte]
  outbuf : FixedArray[Byte] // [1024 / 4 * 3]byte
}

///|
impl @io.Reader for Decoder with read(self : Decoder, p : @slice.Slice[Byte]) -> Int raise {
  // Use leftover decoded output from last read.
  if self.out.length() > 0 {
    let n = p.copy(self.out)
    self.out = self.out[n:]
    return n
  }
  if self.err is Some(err) {
    raise err
  }

  // This code assumes that d.r strips supported whitespace ('\r' and '\n').

  // Refill buffer.
  while self.nbuf < 4 && self.read_err is None {
    let nn = p.length() / 3 * 4
    let nn = if nn < 4 { 4 } else { nn }
    let nn = if nn > self.buf.length() { self.buf.length() } else { nn }
    let nn = self.r.read(@slice.fixedarray(self.buf)[self.nbuf:nn])
    self.nbuf += nn
  }
  if self.nbuf < 4 {
    if self.enc.pad_char is None && self.nbuf > 0 {
      // Decode final fragment, without padding.
      let nw = self.enc.decode(
        @slice.fixedarray(self.outbuf),
        @slice.fixedarray(self.buf)[:self.nbuf],
      )
      self.nbuf = 0
      self.out = @slice.fixedarray(self.outbuf)[:nw]
      let n = p.copy(self.out)
      self.out = self.out[n:]
      if n > 0 || (p.length() == 0 && self.out.length() > 0) {
        return n
      }
      if self.err is Some(err) {
        raise err
      }
    }
    self.err = self.read_err
    if self.err is Some(@io.EOF) && self.nbuf > 0 {
      self.err = Some(@io.UnexpectedEof)
    }
    if self.err is Some(err) {
      raise err
    } else {
      return 0
    }
  }
  let nr = self.nbuf / 4 * 4
  let nw = self.nbuf / 4 * 3
  let mut n = 0
  if nw > p.length() {
    let nw = self.enc.decode(
      @slice.fixedarray(self.outbuf),
      @slice.fixedarray(self.buf)[:nr],
    )
    self.out = @slice.fixedarray(self.outbuf)[:nw]
    n = p.copy(self.out)
    self.out = self.out[n:]
  } else {
    n = self.enc.decode(p, @slice.fixedarray(self.buf)[:nr])
  }
  self.nbuf -= nr
  self.buf.unsafe_blit(0, self.buf, nr, self.nbuf)
  n
}

///|
/// `assemble32` assembles 4 base64 digits into 3 bytes.
/// Each digit comes from the decode map, and will be 0xff
/// if it came from an invalid character.
fn assemble32(n1 : Byte, n2 : Byte, n3 : Byte, n4 : Byte) -> (UInt, Bool) {
  if (n1 | n2 | n3 | n4) == 0xFF {
    return (0, false)
  }
  return (
    (n1.to_uint() << 26) |
    (n2.to_uint() << 20) |
    (n3.to_uint() << 14) |
    (n4.to_uint() << 8),
    true,
  )
}

///|
priv struct NewlineFilteringReader {
  wrapped : &@io.Reader
}

///|
impl @io.Reader for NewlineFilteringReader with read(
  self : NewlineFilteringReader,
  b : @slice.Slice[Byte],
) -> Int raise {
  for n = self.wrapped.read(b); n > 0; n = self.wrapped.read(b) {
    let mut offset = 0
    for src = 0; src < n; src = src + 1 {
      if b[src] != ('\n' : Byte) && b[src] != ('\r' : Byte) {
        b[offset] = b[src]
        offset = offset + 1
      }
    }
    if offset > 0 {
      return offset
    }
  } else {
    return n
  }
}

///|
pub fn new_decoder(enc : Encoding, r : &@io.Reader) -> &@io.Reader {
  Decoder::{
    enc,
    r: NewlineFilteringReader::{ wrapped: r },
    buf: FixedArray::make(1024, 0),
    nbuf: 0,
    outbuf: FixedArray::make(1024 / 4 * 3, 0),
    out: @slice.make(0),
    err: None,
    read_err: None,
  }
}
