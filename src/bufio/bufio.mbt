// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package bufio implements buffered I/O. It wraps an io.Reader or io.Writer
// object, creating another object (Reader or Writer) that also implements
// the interface but provides buffering and some help for textual I/O.

///|
// Constants
let default_buf_size = 4096

///|
let min_read_buffer_size = 16

///|
let max_consecutive_empty_reads = 100

///|
// Error types
pub(all) suberror InvalidUnreadByte

///|
pub(all) suberror InvalidUnreadRune

///|
pub(all) suberror BufferFull

///|
pub(all) suberror NegativeCount

///|
// Reader implements buffering for an io.Reader object.
// A new Reader is created by calling new_reader or new_reader_size;
// alternatively the zero value of a Reader may be used after calling reset
// on it.
pub struct Reader {
  mut buf : Bytes // buffer for reads
  mut rd : &@io.Reader // underlying reader
  mut r : Int // buffer read position
  mut w : Int // buffer write position
  mut err : Bool // sticky error flag
  mut last_byte : Int // last byte read for unread_byte; -1 means invalid
  mut last_rune_size : Int // size of last rune read for unread_rune; -1 means invalid
}

///|
// new_reader_size returns a new Reader whose buffer has at least the specified
// size. If the argument io.Reader is already a Reader with large enough
// size, it returns the underlying Reader.
pub fn new_reader_size(rd : &@io.Reader, size : Int) -> Reader {
  let actual_size = if size < min_read_buffer_size {
    min_read_buffer_size
  } else {
    size
  }
  Reader::{
    buf: Bytes::make(actual_size, 0),
    rd,
    r: 0,
    w: 0,
    err: false,
    last_byte: -1,
    last_rune_size: -1,
  }
}

///|
// new_reader returns a new Reader whose buffer has the default size.
pub fn new_reader(rd : &@io.Reader) -> Reader {
  new_reader_size(rd, default_buf_size)
}

///|
// Size returns the size of the underlying buffer in bytes.
pub fn Reader::size(self : Reader) -> Int {
  self.buf.length()
}

///|
// reset discards any buffered data, resets all state, and switches
// the buffered reader to read from r.
// Calling reset on the zero value of Reader initializes the internal buffer
// to the default size.
pub fn Reader::reset(self : Reader, r : &@io.Reader) -> Unit {
  if self.buf.length() == 0 {
    self.buf = Bytes::make(default_buf_size, 0)
  }
  self.reset_with_buf(self.buf, r)
}

///|
fn Reader::reset_with_buf(self : Reader, buf : Bytes, r : &@io.Reader) -> Unit {
  self.buf = buf
  self.rd = r
  self.r = 0
  self.w = 0
  self.err = false
  self.last_byte = -1
  self.last_rune_size = -1
}

///|
// fill reads a new chunk into the buffer.
fn Reader::fill(self : Reader) -> Unit raise {
  // Slide existing data to beginning.
  if self.r > 0 {
    let slice_len = self.w - self.r
    for i = 0; i < slice_len; i = i + 1 {
      self.buf[i] = self.buf[self.r + i]
    }
    self.w -= self.r
    self.r = 0
  }
  if self.w >= self.buf.length() {
    abort("bufio: tried to fill full buffer")
  }

  // Read new data: try a limited number of times.
  for i = max_consecutive_empty_reads; i > 0; i = i - 1 {
    let view = self.buf[self.w:]
    let n = self.rd.read(view) catch {
      e => {
        self.err = true
        raise e
      }
    }
    if n < 0 {
      abort("bufio: reader returned negative count from Read")
    }
    self.w += n
    if n > 0 {
      return
    }
  }
  self.err = true
  raise @io.NoProgress
}

///|
// Peek returns the next n bytes without advancing the reader. The bytes stop
// being valid at the next read call. If necessary, Peek will read more bytes
// into the buffer in order to make n bytes available. If Peek returns fewer
// than n bytes, it also returns an error explaining why the read is short.
// The error is BufferFull if n is larger than b's buffer size.
//
// Calling Peek prevents a Reader.unread_byte or Reader.unread_rune call from succeeding
// until the next read operation.
pub fn Reader::peek(self : Reader, n : Int) -> Bytes raise {
  if n < 0 {
    raise NegativeCount
  }
  self.last_byte = -1
  self.last_rune_size = -1
  while self.w - self.r < n &&
        self.w - self.r < self.buf.length() &&
        not(self.err) {
    self.fill() catch {
      _ => break
    }
  }
  if n > self.buf.length() {
    let result = Bytes::make(self.w - self.r, 0)
    for i = 0; i < self.w - self.r; i = i + 1 {
      result[i] = self.buf[self.r + i]
    }
    raise BufferFull
  }
  let actual_n = if self.w - self.r < n { self.w - self.r } else { n }
  let result = Bytes::make(actual_n, 0)
  for i = 0; i < actual_n; i = i + 1 {
    result[i] = self.buf[self.r + i]
  }
  result
}

///|
// Discard skips the next n bytes, returning the number of bytes discarded.
//
// If Discard skips fewer than n bytes, it also returns an error.
// If 0 <= n <= b.buffered(), Discard is guaranteed to succeed without
// reading from the underlying io.Reader.
pub fn Reader::discard(self : Reader, n : Int) -> Int raise {
  if n < 0 {
    raise NegativeCount
  }
  if n == 0 {
    return 0
  }
  self.last_byte = -1
  self.last_rune_size = -1
  let mut remain = n
  for {
    let skip = self.buffered()
    if skip == 0 {
      self.fill() catch {
        _ => break n - remain
      }
      let new_skip = self.buffered()
      if new_skip == 0 {
        break n - remain
      }
    }
    let actual_skip = if skip > remain { remain } else { skip }
    self.r += actual_skip
    remain -= actual_skip
    if remain == 0 {
      break n
    }
  }
}

///|
// Read reads data into p.
// It returns the number of bytes read into p.
// The bytes are taken from at most one Read on the underlying Reader,
// hence n may be less than p.length().
// To read exactly p.length() bytes, use io.read_full(b, p).
// If the underlying Reader can return a non-zero count with io.EOF,
// then this Read method can do so as well; see the io.Reader docs.
pub impl @io.Reader for Reader with read(self, p) {
  let n = p.length()
  if n == 0 {
    if self.buffered() > 0 {
      return 0
    }
    if self.err {
      raise @io.EOF
    }
    return 0
  }
  if self.r == self.w {
    if self.err {
      raise @io.EOF
    }
    if p.length() >= self.buf.length() {
      // Large read, empty buffer.
      // Read directly into p to avoid copy.
      let direct_n = self.rd.read(p) catch {
        e => {
          self.err = true
          raise e
        }
      }
      if direct_n < 0 {
        abort("bufio: reader returned negative count from Read")
      }
      if direct_n > 0 {
        self.last_byte = p[direct_n - 1].to_int()
        self.last_rune_size = -1
      }
      return direct_n
    }

    // One read.
    // Do not use b.fill, which will loop.
    self.r = 0
    self.w = 0
    let view = self.buf[:]
    let buf_n = self.rd.read(view) catch {
      e => {
        self.err = true
        raise e
      }
    }
    if buf_n < 0 {
      abort("bufio: reader returned negative count from Read")
    }
    if buf_n == 0 {
      if self.err {
        raise @io.EOF
      }
      return 0
    }
    self.w += buf_n
  }

  // copy as much as we can
  let copy_n = if p.length() > self.w - self.r {
    self.w - self.r
  } else {
    p.length()
  }
  for i = 0; i < copy_n; i = i + 1 {
    p[i] = self.buf[self.r + i]
  }
  self.r += copy_n
  self.last_byte = self.buf[self.r - 1].to_int()
  self.last_rune_size = -1
  copy_n
}

///|
// read_byte reads and returns a single byte.
// If no byte is available, returns an error.
pub impl @io.ByteReader for Reader with read_byte(self) {
  self.last_rune_size = -1
  while self.r == self.w {
    if self.err {
      raise @io.EOF
    }
    self.fill() catch {
      e => raise e
    }
  }
  let c = self.buf[self.r]
  self.r += 1
  self.last_byte = c.to_int()
  c
}

///|
// unread_byte unreads the last byte. Only the most recently read byte can be unread.
//
// unread_byte returns an error if the most recent method called on the
// Reader was not a read operation. Notably, Reader.peek, Reader.discard, and Reader.write_to are not
// considered read operations.
pub fn Reader::unread_byte(self : Reader) -> Unit raise InvalidUnreadByte {
  if self.last_byte < 0 || (self.r == 0 && self.w > 0) {
    raise InvalidUnreadByte
  }
  // b.r > 0 || b.w == 0
  if self.r > 0 {
    self.r -= 1
  } else {
    // b.r == 0 && b.w == 0
    self.w = 1
  }
  self.buf[self.r] = self.last_byte.to_byte()
  self.last_byte = -1
  self.last_rune_size = -1
}

///|
// buffered returns the number of bytes that can be read from the current buffer.
pub fn Reader::buffered(self : Reader) -> Int {
  self.w - self.r
}

///|
// read_slice reads until the first occurrence of delim in the input,
// returning a slice pointing at the bytes in the buffer.
// The bytes stop being valid at the next read.
// If read_slice encounters an error before finding a delimiter,
// it returns all the data in the buffer and the error itself (often io.EOF).
// read_slice fails with error BufferFull if the buffer fills without a delim.
// Because the data returned from read_slice will be overwritten
// by the next I/O operation, most clients should use
// Reader.read_bytes or read_string instead.
// read_slice returns err != null if and only if line does not end in delim.
pub fn Reader::read_slice(self : Reader, delim : Byte) -> Bytes raise {
  let mut s = 0 // search start index
  for {
    // Search buffer.
    let search_buf = self.buf[self.r + s:self.w]
    let mut i = -1
    for j = 0; j < search_buf.length(); j = j + 1 {
      if search_buf[j] == delim {
        i = j
        break
      }
    }
    if i >= 0 {
      let actual_i = i + s
      let line = Bytes::make(actual_i + 1, 0)
      for k = 0; k < actual_i + 1; k = k + 1 {
        line[k] = self.buf[self.r + k]
      }
      self.r += actual_i + 1

      // Handle last byte, if any.
      if line.length() > 0 {
        self.last_byte = line[line.length() - 1].to_int()
        self.last_rune_size = -1
      }
      return line
    }

    // Pending error?
    if self.err {
      let line = Bytes::make(self.w - self.r, 0)
      for k = 0; k < self.w - self.r; k = k + 1 {
        line[k] = self.buf[self.r + k]
      }
      self.r = self.w

      // Handle last byte, if any.
      if line.length() > 0 {
        self.last_byte = line[line.length() - 1].to_int()
        self.last_rune_size = -1
      }
      return line
    }

    // Buffer full?
    if self.buffered() >= self.buf.length() {
      self.r = self.w
      let line = Bytes::make(self.buf.length(), 0)
      for k = 0; k < self.buf.length(); k = k + 1 {
        line[k] = self.buf[k]
      }

      // Handle last byte, if any.
      if line.length() > 0 {
        self.last_byte = line[line.length() - 1].to_int()
        self.last_rune_size = -1
      }
      raise BufferFull
    }
    s = self.w - self.r // do not rescan area we scanned before
    self.fill() catch {
      _ => return Bytes::make(0, 0)
    }
  }
}

///|
// read_bytes reads until the first occurrence of delim in the input,
// returning a slice containing the data up to and including the delimiter.
// If read_bytes encounters an error before finding a delimiter,
// it returns the data read before the error and the error itself (often io.EOF).
// read_bytes returns err != null if and only if the returned data does not end in
// delim.
// For simple uses, a Scanner may be more convenient.
pub fn Reader::read_bytes(self : Reader, delim : Byte) -> Bytes raise {
  let full_buffers : Array[Bytes] = []
  let mut total_len = 0
  for {
    let frag = self.read_slice(delim) catch {
      BufferFull => {
        // Make a copy of the buffer and continue
        let buf = Bytes::make(self.buf.length(), 0)
        for i = 0; i < self.buf.length(); i = i + 1 {
          buf[i] = self.buf[i]
        }
        full_buffers.push(buf)
        total_len += buf.length()
        continue
      }
      e => raise e
    }

    // got final fragment
    total_len += frag.length()

    // Allocate new buffer to hold the full pieces and the fragment.
    let buf = Bytes::make(total_len, 0)
    let mut pos = 0
    // Copy full pieces and fragment in.
    for i = 0; i < full_buffers.length(); i = i + 1 {
      let piece = full_buffers[i]
      for j = 0; j < piece.length(); j = j + 1 {
        buf[pos] = piece[j]
        pos += 1
      }
    }
    for j = 0; j < frag.length(); j = j + 1 {
      buf[pos] = frag[j]
      pos += 1
    }
    break buf
  }
}

///|
// read_string reads until the first occurrence of delim in the input,
// returning a string containing the data up to and including the delimiter.
// If read_string encounters an error before finding a delimiter,
// it returns the data read before the error and the error itself (often io.EOF).
// read_string returns err != null if and only if the returned data does not end in
// delim.
// For simple uses, a Scanner may be more convenient.
pub fn Reader::read_string(self : Reader, delim : Byte) -> String raise {
  let bytes = self.read_bytes(delim) catch { e => raise e }
  bytes.to_string()
}

///|
// buffered output

// Writer implements buffering for an io.Writer object.
// If an error occurs writing to a Writer, no more data will be
// accepted and all subsequent writes, and Writer.flush, will return the error.
// After all data has been written, the client should call the
// Writer.flush method to guarantee all data has been forwarded to
// the underlying io.Writer.
pub struct Writer {
  mut err : Bool
  mut buf : Bytes
  mut n : Int
  mut wr : &@io.Writer
}

///|
// new_writer_size returns a new Writer whose buffer has at least the specified
// size. If the argument io.Writer is already a Writer with large enough
// size, it returns the underlying Writer.
pub fn new_writer_size(w : &@io.Writer, size : Int) -> Writer {
  let actual_size = if size <= 0 { default_buf_size } else { size }
  Writer::{ buf: Bytes::make(actual_size, 0), wr: w, err: false, n: 0 }
}

///|
// new_writer returns a new Writer whose buffer has the default size.
// If the argument io.Writer is already a Writer with large enough buffer size,
// it returns the underlying Writer.
pub fn new_writer(w : &@io.Writer) -> Writer {
  new_writer_size(w, default_buf_size)
}

///|
// Size returns the size of the underlying buffer in bytes.
pub fn Writer::size(self : Writer) -> Int {
  self.buf.length()
}

///|
// reset discards any unflushed buffered data, clears any error, and
// resets b to write its output to w.
// Calling reset on the zero value of Writer initializes the internal buffer
// to the default size.
// Calling w.reset(w) (that is, resetting a Writer to itself) does nothing.
pub fn Writer::reset(self : Writer, w : &@io.Writer) -> Unit {
  if self.buf.length() == 0 {
    self.buf = Bytes::make(default_buf_size, 0)
  }
  self.err = false
  self.n = 0
  self.wr = w
}

///|
// flush writes any buffered data to the underlying io.Writer.
pub fn Writer::flush(self : Writer) -> Unit raise {
  if self.err {
    raise @io.EOF
  }
  if self.n == 0 {
    return
  }
  let view = self.buf[0:self.n]
  let n = self.wr.write(view) catch {
    e => {
      self.err = true
      raise e
    }
  }
  if n < self.n {
    for i = 0; i < self.n - n; i = i + 1 {
      self.buf[i] = self.buf[n + i]
    }
    self.n -= n
    self.err = true
    raise @io.ShortWrite
  }
  self.n = 0
}

///|
// available returns how many bytes are unused in the buffer.
pub fn Writer::available(self : Writer) -> Int {
  self.buf.length() - self.n
}

///|
// buffered returns the number of bytes that have been written into the current buffer.
pub fn Writer::buffered(self : Writer) -> Int {
  self.n
}

///|
// Write writes the contents of p into the buffer.
// It returns the number of bytes written.
// If nn < len(p), it also returns an error explaining
// why the write is short.
pub impl @io.Writer for Writer with write(self, p) {
  let mut nn = 0
  let mut remaining = p
  while remaining.length() > self.available() && not(self.err) {
    let mut n = 0
    if self.buffered() == 0 {
      // Large write, empty buffer.
      // Write directly from p to avoid copy.
      n = self.wr.write(remaining) catch {
        e => {
          self.err = true
          raise e
        }
      }
    } else {
      n = if remaining.length() > self.available() {
        self.available()
      } else {
        remaining.length()
      }
      for i = 0; i < n; i = i + 1 {
        self.buf[self.n + i] = remaining[i]
      }
      self.n += n
      self.flush() catch {
        e => {
          self.err = true
          raise e
        }
      }
    }
    nn += n
    remaining = remaining[n:]
  }
  if self.err {
    raise @io.EOF
  }
  let n = if remaining.length() > self.available() {
    self.available()
  } else {
    remaining.length()
  }
  for i = 0; i < n; i = i + 1 {
    self.buf[self.n + i] = remaining[i]
  }
  self.n += n
  nn += n
  nn
}

///|
// write_byte writes a single byte.
pub impl @io.ByteWriter for Writer with write_byte(self, c) {
  if self.err {
    raise @io.EOF
  }
  if self.available() <= 0 {
    self.flush() catch {
      e => {
        self.err = true
        raise e
      }
    }
  }
  self.buf[self.n] = c
  self.n += 1
}

///|
// write_string writes a string.
// It returns the number of bytes written.
// If the count is less than len(s), it also returns an error explaining
// why the write is short.
pub impl @io.StringWriter for Writer with write_string(self, s) {
  let bytes = s.to_bytes()
  self.write(bytes[:])
}

///|
// buffered input and output

// ReadWriter stores pointers to a Reader and a Writer.
// It implements io.ReadWriter.
pub struct ReadWriter {
  reader : Reader
  writer : Writer
}

///|
// new_read_writer allocates a new ReadWriter that dispatches to r and w.
pub fn new_read_writer(r : Reader, w : Writer) -> ReadWriter {
  ReadWriter::{ reader: r, writer: w }
}

///|
pub impl @io.Reader for ReadWriter with read(self, p) {
  self.reader.read(p)
}

///|
pub impl @io.Writer for ReadWriter with write(self, p) {
  self.writer.write(p)
}
