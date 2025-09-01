///|
/// DictDecoder implements the LZ77 sliding dictionary as used in decompression.
/// LZ77 decompresses data through sequences of two forms of commands:
///
/// - Literal insertions: Runs of one or more symbols are inserted into the data
///   stream as is. This is accomplished through the write_byte method for a
///   single symbol, or combinations of write_slice/write_mark for multiple symbols.
///   Any valid stream must start with a literal insertion if no preset dictionary
///   is used.
///
/// - Backward copies: Runs of one or more symbols are copied from previously
///   emitted data. Backward copies come as the tuple (dist, length) where dist
///   determines how far back in the stream to copy from and length determines how
///   many bytes to copy. Note that it is valid for the length to be greater than
///   the distance. Since LZ77 uses forward copies, that situation is used to
///   perform a form of run-length encoding on repeated runs of symbols.
///   The write_copy and try_write_copy are used to implement this command.
struct DictDecoder {
  mut hist : Array[Byte] // Sliding window history
  // Invariant: 0 <= rd_pos <= wr_pos <= hist.length()
  mut wr_pos : Int // Current output position in buffer
  mut rd_pos : Int // Have emitted hist[:rd_pos] already
  mut full : Bool // Has a full window length been written yet?
} derive(Show)

///|
/// Create a new DictDecoder
pub fn DictDecoder::new() -> DictDecoder {
  DictDecoder::{ hist: Array::new(), wr_pos: 0, rd_pos: 0, full: false }
}

///|
/// Initialize DictDecoder to have a sliding window dictionary of the given
/// size. If a preset dict is provided, it will initialize the dictionary with
/// the contents of dict.
pub fn DictDecoder::init(
  self : DictDecoder,
  size : Int,
  dict : Array[Byte],
) -> Unit {
  // Resize history if needed
  if self.hist.length() < size {
    self.hist = Array::make(size, 0)
  } else {
    // Clear existing data
    for i = 0; i < size; i = i + 1 {
      self.hist[i] = 0
    }
  }

  // Copy dictionary data
  let dict_size = if dict.length() > size { size } else { dict.length() }
  let start_offset = if dict.length() > size { dict.length() - size } else { 0 }
  for i = 0; i < dict_size; i = i + 1 {
    self.hist[i] = dict[start_offset + i]
  }
  self.wr_pos = dict_size
  if self.wr_pos == size {
    self.wr_pos = 0
    self.full = true
  }
  self.rd_pos = self.wr_pos
}

///|
/// Reports the total amount of historical data in the dictionary
pub fn DictDecoder::hist_size(self : DictDecoder) -> Int {
  if self.full {
    self.hist.length()
  } else {
    self.wr_pos
  }
}

///|
/// Reports the number of bytes that can be flushed by read_flush
pub fn DictDecoder::avail_read(self : DictDecoder) -> Int {
  self.wr_pos - self.rd_pos
}

///|
/// Reports the available amount of output buffer space
pub fn DictDecoder::avail_write(self : DictDecoder) -> Int {
  self.hist.length() - self.wr_pos
}

///|
/// Returns a mutable reference to the historical buffer for writing
/// The caller should write only up to avail_write() bytes
pub fn DictDecoder::write_slice(self : DictDecoder) -> Array[Byte] {
  self.hist
}

///|
/// Advances the writer pointer by cnt
/// This invariant must be kept: 0 <= cnt <= avail_write()
pub fn DictDecoder::write_mark(self : DictDecoder, cnt : Int) -> Unit {
  self.wr_pos += cnt
}

///|
/// Writes a single byte to the dictionary
/// This invariant must be kept: 0 < avail_write()
pub fn DictDecoder::write_byte(self : DictDecoder, c : Byte) -> Unit {
  self.hist[self.wr_pos] = c
  self.wr_pos += 1
}

///|
/// Copies a string at a given (dist, length) to the output.
/// This returns the number of bytes copied and may be less than the requested
/// length if the available space in the output buffer is too small.
/// This invariant must be kept: 0 < dist <= hist_size()
pub fn DictDecoder::write_copy(
  self : DictDecoder,
  dist : Int,
  length : Int,
) -> Int {
  let dst_base = self.wr_pos
  let mut dst_pos = dst_base
  let mut src_pos = dst_pos - dist
  let mut end_pos = dst_pos + length
  if end_pos > self.hist.length() {
    end_pos = self.hist.length()
  }

  // Copy non-overlapping section after destination position.
  // This section is non-overlapping in that the copy length for this section
  // is always less than or equal to the backwards distance. This can occur
  // if a distance refers to data that wraps-around in the buffer.
  // Thus, a backwards copy is performed here; that is, the exact bytes in
  // the source prior to the copy is placed in the destination.
  if src_pos < 0 {
    src_pos += self.hist.length()
    while dst_pos < end_pos && src_pos < self.hist.length() {
      self.hist[dst_pos] = self.hist[src_pos]
      dst_pos += 1
      src_pos += 1
    }
    src_pos = 0
  }

  // Copy possibly overlapping section before destination position.
  // This section can overlap if the copy length for this section is larger
  // than the backwards distance. This is allowed by LZ77 so that repeated
  // strings can be succinctly represented using (dist, length) pairs.
  // Thus, a forwards copy is performed here; that is, the bytes copied is
  // possibly dependent on the resulting bytes in the destination as the copy
  // progresses along.
  while dst_pos < end_pos {
    let copy_len = if end_pos - dst_pos < dst_pos - src_pos {
      end_pos - dst_pos
    } else {
      dst_pos - src_pos
    }
    for i = 0; i < copy_len; i = i + 1 {
      self.hist[dst_pos + i] = self.hist[src_pos + i]
    }
    dst_pos += copy_len
  }
  self.wr_pos = dst_pos
  dst_pos - dst_base
}

///|
/// Tries to copy a string at a given (distance, length) to the
/// output. This specialized version is optimized for short distances.
/// This invariant must be kept: 0 < dist <= hist_size()
pub fn DictDecoder::try_write_copy(
  self : DictDecoder,
  dist : Int,
  length : Int,
) -> Int {
  let dst_pos = self.wr_pos
  let end_pos = dst_pos + length
  if dst_pos < dist || end_pos > self.hist.length() {
    return 0
  }
  let dst_base = dst_pos
  let mut current_dst = dst_pos
  let src_pos = dst_pos - dist

  // Copy possibly overlapping section before destination position.
  while current_dst < end_pos {
    let copy_len = if end_pos - current_dst < current_dst - src_pos {
      end_pos - current_dst
    } else {
      current_dst - src_pos
    }
    for i = 0; i < copy_len; i = i + 1 {
      self.hist[current_dst + i] = self.hist[src_pos + i]
    }
    current_dst += copy_len
  }
  self.wr_pos = current_dst
  current_dst - dst_base
}

///|
/// Returns the data from the historical buffer that is ready to be
/// emitted to the user. The data returned by read_flush must be fully consumed
/// before calling any other DictDecoder methods.
pub fn DictDecoder::read_flush(self : DictDecoder) -> Array[Byte] {
  let to_read = Array::new()
  for i = self.rd_pos; i < self.wr_pos; i = i + 1 {
    to_read.push(self.hist[i])
  }
  self.rd_pos = self.wr_pos
  if self.wr_pos == self.hist.length() {
    self.wr_pos = 0
    self.rd_pos = 0
    self.full = true
  }
  to_read
}
