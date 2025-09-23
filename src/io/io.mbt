// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package io provides basic interfaces to I/O primitives.
// Its primary job is to wrap existing implementations of such primitives,
// such as those in package os, into shared public interfaces that
// abstract the functionality, plus some other related primitives.
//
// Because these interfaces and primitives wrap lower-level operations with
// various implementations, unless otherwise informed clients should not
// assume they are safe for parallel execution.

///|
pub(all) enum SeekWhence {
  /// seek relative to the origin of the file
  SeekStart
  /// seek relative to the current offset
  SeekCurrent
  /// seek relative to the end
  SeekEnd
}

///|
/// ShortWrite means that a write accepted fewer bytes than requested
/// but failed to return an error.
pub(all) suberror ShortWrite

///|
/// InvalidWrite means that a write returned an impossible count.
priv suberror InvalidWrite

///|
/// ShortBuffer means that a read required a longer buffer than was provided.
pub(all) suberror ShortBuffer

///|
/// EOF is the error returned by Read when no more input is available.
/// (Read must return EOF itself, not an error wrapping EOF,
/// because callers will test for EOF using ==.)
/// Functions should return EOF only to signal a graceful end of input.
/// If the EOF occurs unexpectedly in a structured data stream,
/// the appropriate error is either [ErrUnexpectedEOF] or some other error
/// giving more detail.
pub(all) suberror EOF

///|
/// UnexpectedEof means that EOF was encountered in the
/// middle of reading a fixed-size block or data structure.
pub(all) suberror UnexpectedEof

///|
/// NoProgress is returned by some clients of a Reader when
/// many calls to Read have failed to return any data or error,
/// usually the sign of a broken Reader implementation.
pub(all) suberror NoProgress

///|
/// Reader is the interface that wraps the basic `read` method.
///
/// `read` reads up to len(p) bytes into p. It returns the number of bytes
/// read (0 <= n <= len(p)) and any error encountered. Even if `read`
/// returns n < len(p), it may use all of p as scratch space during the call.
/// If some data is available but not len(p) bytes, `read` conventionally
/// returns what is available instead of waiting for more.
///
/// When `read` encounters an error or end-of-file condition after
/// successfully reading n > 0 bytes, it returns the number of
/// bytes read. It may return the (non-nil) error from the same call
/// or return the error (and n == 0) from a subsequent call.
/// An instance of this general case is that a Reader returning
/// a non-zero number of bytes at the end of the input stream may
/// return either err == EOF or err == nil. The next `read` should
/// return 0, EOF.
///
/// Callers should always process the n > 0 bytes returned before
/// considering the error err. Doing so correctly handles I/O errors
/// that happen after reading some bytes and also both of the
/// allowed EOF behaviors.
///
/// If len(p) == 0, `read` should always return n == 0. It may return a
/// non-nil error if some error condition is known, such as EOF.
///
/// Implementations of `read` are discouraged from returning a
/// zero byte count with a nil error, except when len(p) == 0.
/// Callers should treat a return of 0 and nil as indicating that
/// nothing happened; in particular it does not indicate EOF.
///
/// Implementations must not retain p.
pub(open) trait Reader {
  read(self : Self, bytes : @slice.Slice[Byte]) -> Int raise
}

///|
/// Writer is the interface that wraps the basic `write` method.
///
/// `write` writes len(p) bytes from p to the underlying data stream.
/// It returns the number of bytes written from p (0 <= n <= len(p))
/// and any error encountered that caused the write to stop early.
/// `write` must return a non-nil error if it returns n < len(p).
/// `write` must not modify the slice data, even temporarily.
///
/// Implementations must not retain p.
pub(open) trait Writer {
  write(self : Self, bytes : @slice.Slice[Byte]) -> Int raise
}

///|
pub impl Writer for @buffer.Buffer with write(
  self : @buffer.Buffer,
  bytes : @slice.Slice[Byte],
) -> Int {
  for i in 0..<bytes.length() {
    self.write_byte(bytes[i])
  }
  bytes.length()
}

///|
/// Closer is the interface that wraps the basic `close` method.
///
/// The behavior of `close` after the first call is undefined.
/// Specific implementations may document their own behavior.
pub(open) trait Closer {
  close(self : Self) -> Unit raise
}

///|
/// Seeker is the interface that wraps the basic `seek` method.
///
/// `seek` sets the offset for the next `read` or `write` to `offset`,
/// interpreted according to whence:
///
/// - `SeekStart` means relative to the start of the file,
/// - `SeekCurrent` means relative to the current offset, and
/// - `SeekEnd` means relative to the end
///
/// (for example, `offset = -2` specifies the penultimate byte of the file).
/// `seek` returns the new offset relative to the start of the
/// file or an error, if any.
///
/// Seeking to an offset before the start of the file is an error.
/// Seeking to any positive offset may be allowed, but if the new offset exceeds
/// the size of the underlying object the behavior of subsequent I/O operations
/// is implementation-dependent.
pub(open) trait Seeker {
  seek(self : Self, offset : Int64, whence : SeekWhence) -> Int64 raise
}

///|
/// ReadWriter is the interface that groups the basic `read` and `write` methods.
pub(open) trait ReadWriter: Reader + Writer {}

///|
/// ReadCloser is the interface that groups the basic `read` and `close` methods.
pub(open) trait ReadCloser: Reader + Closer {}

///|
/// WriteCloser is the interface that groups the basic `write` and `close` methods.
pub(open) trait WriteCloser: Writer + Closer {}

///|
/// ReadWriteCloser is the interface that groups the basic `read`, `write` and `close` methods.
pub(open) trait ReadWriteCloser: Reader + Writer + Closer {}

///|
/// ReadSeeker is the interface that groups the basic `read` and `seek` methods.
pub(open) trait ReadSeeker: Reader + Seeker {}

///|
/// ReadSeekCloser is the interface that groups the basic `read`, `seek` and `close` methods.
pub(open) trait ReadSeekCloser: Reader + Seeker + Closer {}

///|
/// WriteSeeker is the interface that groups the basic `write` and `seek` methods.
pub(open) trait WriteSeeker: Writer + Seeker {}

///|
/// ReadWriteSeeker is the interface that groups the basic `read`, `write` and `seek` methods.
pub(open) trait ReadWriteSeeker: Reader + Writer + Seeker {}

///|
/// ReaderFrom is the interface that wraps the `read_from` method.
///
/// `read_from` reads data from `r` until EOF or error.
/// The return value `n` is the number of bytes read.
/// Any error except EOF encountered during the read is also returned.
///
/// The `copy` function uses `ReaderFrom` if available.
pub(open) trait ReaderFrom {
  read_from(self : Self, r : &Reader) -> Int64 raise
}

///|
/// WriterTo is the interface that wraps the `write_to` method.
///
/// `write_to` writes data to w until there's no more data to write or
/// when an error occurs. The return value n is the number of bytes
/// written. Any error encountered during the write is also returned.
///
/// The `copy` function uses `WriterTo` if available.
pub(open) trait WriterTo {
  write_to(self : Self, w : &Writer) -> Int64 raise
}

///|
/// ReaderAt is the interface that wraps the basic `read_at` method.
///
/// `read_at` reads `len(p)` bytes into `p` starting at offset `off` in the
/// underlying input source. It returns the number of bytes
/// read (0 <= n <= len(p)) and any error encountered.
///
/// When `read_at` returns n < len(p), it returns a non-nil error
/// explaining why more bytes were not returned. In this respect,
/// `read_at` is stricter than Read.
///
/// Even if `read_at` returns n < len(p), it may use all of p as scratch
/// space during the call. If some data is available but not len(p) bytes,
/// `read_at` blocks until either all the data is available or an error occurs.
/// In this respect `read_at` is different from Read.
///
/// If the n = len(p) bytes returned by `read_at` are at the end of the
/// input source, `read_at` may return either err == EOF or err == nil.
///
/// If `read_at` is reading from an input source with a seek offset,
/// `read_at` should not affect nor be affected by the underlying
/// seek offset.
///
/// Clients of `read_at` can execute parallel `read_at` calls on the
/// same input source.
///
/// Implementations must not retain p.
pub(open) trait ReaderAt {
  read_at(self : Self, bytes : @slice.Slice[Byte], off : Int64) -> Int raise
}

///|
/// WriterAt is the interface that wraps the basic `write_at` method.
///
/// `write_at` writes `len(p)` bytes from `p` to the underlying data stream
/// at offset `off`. It returns the number of bytes written from `p` (0 <= n <= len(p))
/// and any error encountered that caused the write to stop early.
/// `write_at` must return a non-nil error if it returns `n < len(p)`.
///
/// If `write_at` is writing to a destination with a seek offset,
/// `write_at` should not affect nor be affected by the underlying
/// seek offset.
///
/// Clients of `write_at` can execute parallel `write_at` calls on the same
/// destination if the ranges do not overlap.
///
/// Implementations must not retain p.
pub(open) trait WriterAt {
  write_at(self : Self, bytes : @slice.Slice[Byte], off : Int64) -> Int raise
}

///|
/// ByteReader is the interface that wraps the `read_byte` method.
///
/// `read_byte` reads and returns the next byte from the input or
/// any error encountered. If `read_byte` returns an error, no input
/// byte was consumed, and the returned byte value is undefined.
///
/// `read_byte` provides an efficient interface for byte-at-time
/// processing. A [Reader] that does not implement  ByteReader
/// can be wrapped using bufio.NewReader to add this method.
pub(open) trait ByteReader {
  read_byte(self : Self) -> Byte raise
}

///|
/// ByteScanner is the interface that adds the `unread_byte` method to the
/// basic `read_byte` method.
///
/// `unread_byte` causes the next call to `read_byte` to return the last byte read.
/// If the last operation was not a successful call to `read_byte`, `unread_byte` may
/// return an error, unread the last byte read (or the byte prior to the
/// last-unread byte), or (in implementations that support the [Seeker] interface)
/// seek to one byte before the current offset.
pub(open) trait ByteScanner: ByteReader {
  unread_byte(self : Self) -> Unit raise
}

///|
/// ByteWriter is the interface that wraps the `write_byte` method.
pub(open) trait ByteWriter {
  write_byte(self : Self, b : Byte) -> Unit raise
}

///|
/// `RuneReader` is the interface that wraps the `read_rune` method.
///
/// `read_rune` reads a single encoded Unicode character
/// and returns the rune and its size in bytes. If no character is
/// available, err will be set.
pub(open) trait RuneReader {
  read_rune(self : Self) -> (Rune, Int) raise
}

///|
/// `RuneScanner` is the interface that adds the `unread_rune` method to the
/// basic `read_rune` method.
///
/// `unread_rune` causes the next call to `read_rune` to return the last rune read.
/// If the last operation was not a successful call to `read_rune`, `unread_rune` may
/// return an error, unread the last rune read (or the rune prior to the
/// last-unread rune), or (in implementations that support the `Seeker` interface)
/// seek to the start of the rune before the current offset.
pub(open) trait RuneScanner: RuneReader {
  unread_rune(self : Self) -> Unit raise
}

///|
/// StringWriter is the interface that wraps the `write_string` method.
pub(open) trait StringWriter {
  write_string(self : Self, s : String) -> Int raise
}

///|
/// WriteString writes the contents of the string s to w, which accepts a slice of bytes.
/// If w implements [StringWriter], [StringWriter.WriteString] is invoked directly.
/// Otherwise, [Writer.Write] is called exactly once.
pub fn[StringWriter : StringWriter] write_string(
  w : StringWriter,
  s : String,
) -> Int raise {
  w.write_string(s)
}

///|
/// ReadAtLeast reads from r into buf until it has read at least min bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is EOF only if no bytes were read.
/// If an EOF happens after reading fewer than min bytes,
/// ReadAtLeast returns [ErrUnexpectedEOF].
/// If min is greater than the length of buf, ReadAtLeast returns [ErrShortBuffer].
/// On return, n >= min if and only if err == nil.
/// If r returns an error having read at least min bytes, the error is dropped.
pub fn[R : Reader] read_at_least(
  r : R,
  buf : @slice.Slice[Byte],
  min : Int,
) -> Int raise {
  if buf.length() < min {
    raise ShortBuffer
  }
  let mut n = 0
  let mut buf = buf
  while n < min {
    let nn = r.read(buf) catch {
      EOF if n > 0 => raise UnexpectedEof
      e => raise e
    }
    if nn == 0 {
      if n == 0 {
        raise EOF
      } else {
        raise UnexpectedEof
      }
    }
    n += nn
    buf = buf[nn:]
  }
  n
}

///|
/// ReadFull reads exactly len(buf) bytes from r into buf.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is EOF only if no bytes were read.
/// If an EOF happens after reading some but not all the bytes,
/// ReadFull returns [ErrUnexpectedEOF].
/// On return, n == len(buf) if and only if err == nil.
/// If r returns an error having read at least len(buf) bytes, the error is dropped.
pub fn[R : Reader] read_full(r : R, bytes : @slice.Slice[Byte]) -> Int raise {
  let mut total = 0
  let mut remaining = bytes
  while remaining.length() > 0 {
    let n = r.read(remaining) catch {
      EOF if total > 0 => raise UnexpectedEof
      e => raise e
    }
    if n == 0 {
      if total == 0 {
        raise EOF
      } else {
        raise UnexpectedEof
      }
    }
    total += n
    remaining = remaining[n:]
  }
  total
}

///|
/// copy_n copies n bytes (or until an error) from src to dst.
/// It returns the number of bytes copied and the first error encountered while copying, if any.
pub fn[R : Reader, W : Writer] copy_n(
  dst : W,
  src : R,
  n : Int64,
) -> Int64 raise {
  let mut written = 0L
  let mut remaining = n
  let buf : @slice.Slice[Byte] = @slice.make(8192) // 8KB buffer
  while remaining > 0 {
    let to_read = if remaining > buf.length().to_int64() {
      buf.length()
    } else {
      remaining.to_int()
    }
    let nr = src.read(buf[0:to_read]) catch {
      EOF => break
      e => raise e
    }
    if nr == 0 {
      break
    }
    let nw = dst.write(buf[0:nr])
    if nw < 0 || nr < nw {
      raise InvalidWrite
    }
    written += nw.to_int64()
    if nw != nr {
      raise ShortWrite
    }
    remaining -= nr.to_int64()
  }
  written
}

///|
/// `copy` copies from src to dst until either `EOF` is reached
/// on src or an error occurs. It returns the number of bytes
/// copied and the first error encountered while copying, if any.
///
/// A successful `copy` returns `err == nil`, not `err == EOF`.
/// Because `copy` is defined to read from `src` until EOF, it does
/// not treat an EOF from Read as an error to be reported.
///
/// If `src` implements [WriterTo],
/// the copy is implemented by calling `src.WriteTo(dst)`.
/// Otherwise, if dst implements [ReaderFrom],
/// the copy is implemented by calling dst.ReadFrom(src).
pub fn[R : Reader, W : Writer] copy(dst : W, src : R) -> Int64 raise {
  copy_buffer(dst, src, None)
}

///|
pub fn[Writer : Writer, Reader : Reader] copy_buffer(
  dst : Writer,
  src : Reader,
  buf : @slice.Slice[Byte]?,
) -> Int64 raise {
  if buf is Some(buf) && len(buf) == 0 {
    abort("empty buffer in copy_buffer")
  }
  _copy_buffer(dst, src, buf)
}

///|
fn[Writer : Writer, Reader : Reader] _copy_buffer(
  dst : Writer,
  src : Reader,
  buf : @slice.Slice[Byte]?,
) -> Int64 raise {
  let buf = match buf {
    Some(buf) => buf
    None => {
      let size = 32 * 1024
      @slice.make(size)
    }
  }
  let mut written : Int64 = 0
  let mut err = None
  while true {
    let nr = src.read(buf) catch {
      EOF => break
      e => {
        err = Some(e)
        break
      }
    }
    let nw = dst.write(buf[0:nr]) catch {
      ew => {
        err = Some(ew)
        break
      }
    }
    if nr < nw {
      err = Some(InvalidWrite)
      break
    }
    written += int64(nw)
    if nr != nw {
      err = Some(ShortWrite)
      break
    }
  }
  if err is Some(err) && written == 0 {
    raise err
  }
  written
}

///|
/// Resetter is the interface that wraps the Reset method.
pub(open) trait Resetter {
  reset(self : Self, r : &Reader) -> Unit raise
}

///|
/// LimitedReader reads from R but limits the amount of
/// data returned to just N bytes.
struct LimitedReader {
  r : &Reader
  mut n : Int64
}

///|
/// LimitReader returns a Reader that reads from r
/// but stops with EOF after n bytes.
pub fn limit_reader(r : &Reader, n : Int64) -> LimitedReader {
  LimitedReader::{ r, n }
}

///|
pub impl Reader for LimitedReader with read(self, p) {
  if self.n <= 0 {
    raise EOF
  }
  let max = p.length().to_int64()
  let to_read = if max > self.n { self.n.to_int() } else { p.length() }
  let n = self.r.read(p[0:to_read])
  self.n -= n.to_int64()
  n
}

///|
/// NewSectionReader returns a SectionReader that reads from r
/// starting at offset off and stops with EOF after n bytes.
pub fn new_section_reader(
  r : &ReaderAt,
  off : Int64,
  n : Int64,
) -> SectionReader {
  SectionReader::new(r, off, n)
}

///|
struct SectionReader {
  r : &ReaderAt
  base : Int64
  mut off : Int64
  limit : Int64
  n : Int64
}

///|
pub fn SectionReader::new(
  r : &ReaderAt,
  off : Int64,
  n : Int64,
) -> SectionReader {
  let remaining = if off <= @int64.max_value - n {
    n + off
  } else {
    @int64.max_value
  }
  SectionReader::{ r, base: off, off, limit: remaining, n }
}

///|
pub impl Reader for SectionReader with read(
  s : SectionReader,
  p : @slice.Slice[Byte],
) -> Int raise {
  if s.off >= s.limit {
    return 0
  }
  let max = s.limit - s.off
  let p = if p.length().to_int64() > max { p[0:max.to_int()] } else { p }
  let n = s.r.read_at(p, s.off)
  s.off += n.to_int64()
  return n
}

///|
pub(all) suberror SeekError {
  InvalidOffset(Int64)
}

///|
pub impl Seeker for SectionReader with seek(
  s : SectionReader,
  offset : Int64,
  whence : SeekWhence,
) -> Int64 raise {
  let offset = match whence {
    SeekStart => offset + s.base
    SeekCurrent => offset + s.off
    SeekEnd => offset + s.limit
  }
  if offset < s.base {
    raise SeekError::InvalidOffset(offset)
  }
  s.off = offset
  return offset - s.base
}

///|
pub impl ReaderAt for SectionReader with read_at(
  s : SectionReader,
  p : @slice.Slice[Byte],
  off : Int64,
) -> Int raise {
  if off < 0 || off >= s.size() {
    raise EOF
  }
  let max = s.limit - off
  if p.length().to_int64() > max {
    let p = p[0:max.to_int()]
    return s.r.read_at(p, off)
  } else {
    return s.r.read_at(p, off)
  }
}

///|
pub fn SectionReader::size(s : SectionReader) -> Int64 {
  return s.limit - s.base
}

///|
pub fn[Reader : Reader] read_all(r : Reader) -> @slice.Slice[Byte] raise {
  let mut buf = @slice.make(512)
  let mut len = 0
  for {
    let n = r.read(buf[len:]) catch {
      EOF => return buf
      err => raise err
    }
    len += n
    if len == buf.length() {
      let new_buf = @slice.make(buf.length() * 2)
      let _ = new_buf.copy(buf)
      buf = new_buf
    }
  }
}
