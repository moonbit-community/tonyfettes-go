//|

///|
pub const NoCompression = 0

///|
pub const BestSpeed = 1

///|
pub const BestCompression = 9

///|
pub const DefaultCompression = -1

///|
pub const HuffmanOnly = -2

///|
/// Constants for DEFLATE algorithm
const LogWindowSize : Int = 15

///|
const WindowSize : Int = 1 << LogWindowSize

///|
const WindowMask : Int = WindowSize - 1

///|
/// The LZ77 step produces a sequence of literal tokens and <length, offset>
/// pair tokens. The offset is also known as distance. The underlying wire
/// format limits the range of lengths and offsets. For example, there are
/// 256 legitimate lengths: those in the range [3, 258]. This package's
/// compressor uses a higher minimum match length, enabling optimizations
/// such as finding matches via 32-bit loads and compares.
const BaseMatchLength : Int = 3 // The smallest match length per the RFC section 3.2.5

///|
const MinMatchLength : Int = 4 // The smallest match length that the compressor actually emits

///|
const MaxMatchLength : Int = 258 // The largest match length

///|
const BaseMatchOffset : Int = 1 // The smallest match offset

///|
const MaxMatchOffset : Int = 1 << 15 // The largest match offset

///|
/// The maximum number of tokens we put into a single flate block, just to
/// stop things from getting too large.
const MaxFlateBlockTokens : Int = 1 << 14

///|
const MaxStoreBlockSize : Int = 65535

///|
const HashBits : Int = 17 // After 17 performance degrades

///|
const HashSize : Int = 1 << HashBits

///|
const HashMask : Int = (1 << HashBits) - 1

///|
const MaxHashOffset : Int = 1 << 24

///|
const SkipNever : Int = 2147483647 // math.MaxInt32

///|
/// Compression level configuration
priv struct CompressionLevel {
  level : Int
  good : Int
  lazy_ : Int
  nice : Int
  chain : Int
  fast_skip_hashing : Int
} derive(Show)

///|
/// Compression levels array matching Go implementation
let levels : Array[CompressionLevel] = [
  { level: 0, good: 0, lazy_: 0, nice: 0, chain: 0, fast_skip_hashing: 0 }, // NoCompression
  { level: 1, good: 0, lazy_: 0, nice: 0, chain: 0, fast_skip_hashing: 0 }, // BestSpeed uses a custom algorithm; see deflatefast.go
  // For levels 2-3 we don't bother trying with lazy matches.
  { level: 2, good: 4, lazy_: 0, nice: 16, chain: 8, fast_skip_hashing: 5 },
  { level: 3, good: 4, lazy_: 0, nice: 32, chain: 32, fast_skip_hashing: 6 },
  // Levels 4-9 use increasingly more lazy matching
  // and increasingly stringent conditions for "good enough".
  {
    level: 4,
    good: 4,
    lazy_: 4,
    nice: 16,
    chain: 16,
    fast_skip_hashing: SkipNever,
  },
  {
    level: 5,
    good: 8,
    lazy_: 16,
    nice: 32,
    chain: 32,
    fast_skip_hashing: SkipNever,
  },
  {
    level: 6,
    good: 8,
    lazy_: 16,
    nice: 128,
    chain: 128,
    fast_skip_hashing: SkipNever,
  },
  {
    level: 7,
    good: 8,
    lazy_: 32,
    nice: 128,
    chain: 256,
    fast_skip_hashing: SkipNever,
  },
  {
    level: 8,
    good: 32,
    lazy_: 128,
    nice: 258,
    chain: 1024,
    fast_skip_hashing: SkipNever,
  },
  {
    level: 9,
    good: 32,
    lazy_: 258,
    nice: 258,
    chain: 4096,
    fast_skip_hashing: SkipNever,
  },
]

///|
/// Hash multiplier for hash function
const Hashmul : UInt = 0x1e35a7bd

///|
/// Error for writer closed
priv suberror WriterClosed

///|
impl Show for WriterClosed with output(_ : WriterClosed, logger : &Logger) {
  logger.write_string("flate: closed writer")
}

///|
/// Compressor struct matching Go's compressor
priv struct Compressor {
  mut compression_level : CompressionLevel
  mut w : HuffmanBitWriter
  mut bulk_hasher : (Array[Byte], Array[UInt]) -> Unit

  // compression algorithm
  mut fill : (Compressor, Array[Byte]) -> Int // copy data to window
  mut step : (Compressor) -> Unit // process window
  mut best_speed : DeflateFast // Encoder for BestSpeed

  // Input hash chains
  // hash_head[hashValue] contains the largest inputIndex with the specified hash value
  // If hash_head[hashValue] is within the current window, then
  // hash_prev[hash_head[hashValue] & windowMask] contains the previous index
  // with the same hash value.
  mut chain_head : Int
  hash_head : Array[UInt] // TODO: make mutable when implementing full algorithm
  hash_prev : Array[UInt] // TODO: make mutable when implementing full algorithm
  mut hash_offset : Int

  // input window: unprocessed data is window[index:window_end]
  mut index : Int
  mut window : @bytes.View
  mut window_end : Int
  mut block_start : Int // window index where current tokens start
  mut byte_available : Bool // if true, still need to process window[index-1].
  mut sync : Bool // requesting flush

  // queued output tokens
  mut tokens : Array[Token]

  // deflate state
  mut length : Int
  mut offset : Int
  mut max_insert_index : Int
  mut err : Error?

  // hash_match must be able to contain hashes for the maximum match length.
  hash_match : Array[UInt] // TODO: make mutable when implementing full algorithm
}

///|
/// hash4 returns a hash representation of the first 4 bytes
/// of the supplied slice.
/// The caller must ensure that len(b) >= 4.
fn hash4(b : Array[Byte]) -> UInt {
  (
    (
      b[3].to_uint() |
      (b[2].to_uint() << 8) |
      (b[1].to_uint() << 16) |
      (b[0].to_uint() << 24)
    ) *
    Hashmul
  ) >>
  (32 - HashBits)
}

///|
/// bulk_hash4 will compute hashes using the same algorithm as hash4.
fn bulk_hash4(b : Array[Byte], dst : Array[UInt]) -> Unit {
  if b.length() < MinMatchLength {
    return
  }
  let mut hb = b[3].to_uint() |
    (b[2].to_uint() << 8) |
    (b[1].to_uint() << 16) |
    (b[0].to_uint() << 24)
  dst[0] = (hb * Hashmul) >> (32 - HashBits)
  let end = b.length() - MinMatchLength + 1
  for i = 1; i < end; i = i + 1 {
    hb = (hb << 8) | b[i + 3].to_uint()
    dst[i] = (hb * Hashmul) >> (32 - HashBits)
  }
}

///|
/// match_len returns the number of matching bytes in a and b
/// up to length 'max'. Both slices must be at least 'max' bytes in size.
fn match_len(a : Array[Byte], b : Array[Byte], max : Int) -> Int {
  let max_len = if a.length() < max { a.length() } else { max }
  let max_len = if b.length() < max_len { b.length() } else { max_len }
  for i = 0; i < max_len; i = i + 1 {
    if a[i] != b[i] {
      return i
    }
  }
  max_len
}

///|
/// A Writer takes data written to it and writes the compressed
/// form of that data to an underlying writer (see NewWriter).
struct Writer {
  d : Compressor
  dict : Array[Byte]
}

///|
/// NewWriter returns a new Writer compressing data at the given level.
/// Following zlib, levels range from 1 (BestSpeed) to 9 (BestCompression);
/// higher levels typically run slower but compress more. Level 0
/// (NoCompression) does not attempt any compression; it only adds the
/// necessary DEFLATE framing.
/// Level -1 (DefaultCompression) uses the default compression level.
/// Level -2 (HuffmanOnly) will use Huffman compression only, giving
/// a very fast compression for all types of input, but sacrificing considerable
/// compression efficiency.
///
/// If level is in the range [-2, 9] then the error returned will be nil.
/// Otherwise the error returned will be non-nil.
pub fn new_writer(w : &@io.Writer, level : Int) -> Writer raise {
  let dw = Writer::{ d: Compressor::new(w), dict: Array::new() }
  dw.d.init(w, level)
  dw
}

///|
/// Create a new Compressor
fn Compressor::new(w : &@io.Writer) -> Compressor {
  Compressor::{
    compression_level: levels[0], // default to no compression initially
    w: HuffmanBitWriter::new(w),
    bulk_hasher: bulk_hash4,
    fill: Compressor::fill_store,
    step: Compressor::store,
    best_speed: DeflateFast::new(),
    chain_head: -1,
    hash_head: Array::make(HashSize, 0),
    hash_prev: Array::make(WindowSize, 0),
    hash_offset: 1,
    index: 0,
    window: "",
    window_end: 0,
    block_start: 0,
    byte_available: false,
    sync: false,
    tokens: Array::new(),
    length: MinMatchLength - 1,
    offset: 0,
    max_insert_index: 0,
    err: None,
    hash_match: Array::make(MaxMatchLength - 1, 0),
  }
}

///|
priv suberror InvalidCompressionLevel Int

///|
/// Initialize compressor with writer and level
fn Compressor::init(
  d : Compressor,
  w : &@io.Writer,
  level : Int,
) -> Unit raise InvalidCompressionLevel {
  d.w = HuffmanBitWriter::new(w)
  match level {
    NoCompression => {
      d.window = Bytes::make(MaxStoreBlockSize, 0)
      d.fill = Compressor::fill_store
      d.step = Compressor::store
    }
    HuffmanOnly => {
      d.window = Bytes::make(MaxStoreBlockSize, 0)
      d.fill = Compressor::fill_store
      d.step = Compressor::store_huff
    }
    BestSpeed => {
      d.compression_level = levels[level]
      d.window = Bytes::make(MaxStoreBlockSize, 0)
      d.fill = Compressor::fill_store
      d.step = Compressor::enc_speed
      d.best_speed = DeflateFast::new()
      d.tokens = Array::make(MaxStoreBlockSize, literal_token(0))
    }
    DefaultCompression => { // DefaultCompression
      d.init(w, 6)
      return
    }
    2..=9 => {
      d.compression_level = levels[level]
      d.init_deflate()
      d.fill = Compressor::fill_deflate
      d.step = Compressor::deflate
    }
    level => raise InvalidCompressionLevel(level)
  }
}

///|
/// Initialize deflate state
fn Compressor::init_deflate(self : Compressor) -> Unit {
  self.window = Bytes::make(2 * WindowSize, 0)
  self.hash_offset = 1
  self.tokens = Array::make(MaxFlateBlockTokens + 1, literal_token(0))
  self.length = MinMatchLength - 1
  self.offset = 0
  self.byte_available = false
  self.index = 0
  self.chain_head = -1
  self.bulk_hasher = bulk_hash4
}

///|
/// Store fill function
fn Compressor::fill_store(self : Compressor, b : Array[Byte]) -> Int {
  let available = self.window.length() - self.window_end
  let n = if b.length() < available { b.length() } else { available }
  for i = 0; i < n; i = i + 1 {
    self.window[self.window_end + i] = b[i]
  }
  self.window_end += n
  n
}

///|
/// Deflate fill function
fn Compressor::fill_deflate(self : Compressor, b : Array[Byte]) -> Int {
  if self.index >= 2 * WindowSize - (MinMatchLength + MaxMatchLength) {
    // shift the window by windowSize
    for i = 0; i < WindowSize; i = i + 1 {
      self.window[i] = self.window[WindowSize + i]
    }
    self.index -= WindowSize
    self.window_end -= WindowSize
    if self.block_start >= WindowSize {
      self.block_start -= WindowSize
    } else {
      self.block_start = 2147483647 // math.MaxInt32
    }
    self.hash_offset += WindowSize
    if self.hash_offset > MaxHashOffset {
      let delta = self.hash_offset - 1
      self.hash_offset -= delta
      self.chain_head -= delta

      // Update hash tables
      for i = 0; i < self.hash_prev.length(); i = i + 1 {
        let v = self.hash_prev[i].reinterpret_as_int()
        if v > delta {
          self.hash_prev[i] = (v - delta).reinterpret_as_uint()
        } else {
          self.hash_prev[i] = 0
        }
      }
      for i = 0; i < self.hash_head.length(); i = i + 1 {
        let v = self.hash_head[i].reinterpret_as_int()
        if v > delta {
          self.hash_head[i] = (v - delta).reinterpret_as_uint()
        } else {
          self.hash_head[i] = 0
        }
      }
    }
  }
  let available = self.window.length() - self.window_end
  let n = if b.length() < available { b.length() } else { available }
  for i = 0; i < n; i = i + 1 {
    self.window[self.window_end + i] = b[i]
  }
  self.window_end += n
  n
}

///|
/// Store step function
fn Compressor::store(d : Compressor) -> Unit {
  if d.window_end > 0 && (d.window_end == MaxStoreBlockSize || d.sync) {
    d.write_stored_block(d.window[:d.window_end]) catch {
      err => d.err = Some(err)
    }
    d.window_end = 0
  }
}

///|
/// Store huffman step function
fn Compressor::store_huff(d : Compressor) -> Unit {
  if (d.window_end < d.window.length() && !d.sync) || d.window_end == 0 {
    return
  }
  d.w.write_block_huff(false, d.window[:d.window_end]) catch {
    err => d.err = Some(err)
  }
  d.window_end = 0
}

///|
/// Encode speed step function
fn Compressor::enc_speed(d : Compressor) -> Unit {
  // We only compress if we have MaxStoreBlockSize.
  if d.window_end < MaxStoreBlockSize {
    if !d.sync {
      return
    }

    // Handle small sizes.
    if d.window_end < 128 {
      match d.window_end {
        0 => return
        1..=16 =>
          d.write_stored_block(d.window[:d.window_end]) catch {
            err => d.err = Some(err)
          }
        _ =>
          d.w.write_block_huff(false, d.window[:d.window_end]) catch {
            err => d.err = Some(err)
          }
      }
      d.window_end = 0
      d.best_speed.reset()
      return
    }
  }

  // Encode the block.
  d.tokens.clear()
  d.best_speed.encode(d.tokens, d.window[:d.window_end])

  // If we removed less than 1/16th, Huffman compress the block.
  try {
    if d.tokens.length() > d.window_end - (d.window_end >> 4) {
      d.w.write_block_huff(false, d.window[:d.window_end])
    } else {
      d.w.write_block_dynamic(d.tokens, false, d.window[:d.window_end])
    }
  } catch {
    err => d.err = Some(err)
  }
  d.window_end = 0
}

///|
/// Main deflate algorithm implementation
/// This is a direct translation of Go's compress/flate/deflate.go deflate method
fn Compressor::deflate(d : Compressor) -> Unit {
  if d.window_end - d.index < MinMatchLength + MaxMatchLength && not(d.sync) {
    return
  }
  d.max_insert_index = d.window_end - (MinMatchLength - 1)

  // Main compression loop
  while true {
    if d.index > d.window_end {
      abort("index > windowEnd")
    }
    let lookahead = d.window_end - d.index
    if lookahead < MinMatchLength + MaxMatchLength {
      if not(d.sync) {
        break // Exit main loop
      }
      if d.index > d.window_end {
        abort("index > windowEnd")
      }
      if lookahead == 0 {
        // Flush current output block if any.
        if d.byte_available {
          // There is still one pending token that needs to be flushed
          d.tokens.push(literal_token(d.window[d.index - 1].to_uint()))
          d.byte_available = false
        }
        if d.tokens.length() > 0 {
          d.write_block(d.tokens, d.index) catch {
            err => d.err = Some(err)
          }
          d.tokens.clear()
        }
        break // Exit main loop
      }
    }
    if d.index < d.max_insert_index {
      // Update the hash
      let hash_bytes = Array::new()
      for i = 0; i < MinMatchLength; i = i + 1 {
        hash_bytes.push(d.window[d.index + i])
      }
      let hash = hash4(hash_bytes)
      let hash_index = (hash & HashMask.reinterpret_as_uint()).reinterpret_as_int()
      d.chain_head = d.hash_head[hash_index].reinterpret_as_int()
      d.hash_prev[d.index & WindowMask] = d.hash_head[hash_index]
      d.hash_head[hash_index] = (d.index + d.hash_offset).reinterpret_as_uint()
    }
    let prev_length = d.length
    let prev_offset = d.offset
    d.length = MinMatchLength - 1
    d.offset = 0
    let mut min_index = d.index - WindowSize
    if min_index < 0 {
      min_index = 0
    }
    if d.chain_head - d.hash_offset >= min_index &&
      (
        (
          d.compression_level.fast_skip_hashing != SkipNever &&
          lookahead > MinMatchLength - 1
        ) ||
        (
          d.compression_level.fast_skip_hashing == SkipNever &&
          lookahead > prev_length &&
          prev_length < d.compression_level.lazy_
        )
      ) {
      let (new_length, new_offset, ok) = d.find_match(
        d.index,
        d.chain_head - d.hash_offset,
        MinMatchLength - 1,
        lookahead,
      )
      if ok {
        d.length = new_length
        d.offset = new_offset
      }
    }
    if (
        d.compression_level.fast_skip_hashing != SkipNever &&
        d.length >= MinMatchLength
      ) ||
      (
        d.compression_level.fast_skip_hashing == SkipNever &&
        prev_length >= MinMatchLength &&
        d.length <= prev_length
      ) {
      // There was a match at the previous step, and the current match is
      // not better. Output the previous match.
      if d.compression_level.fast_skip_hashing != SkipNever {
        d.tokens.push(
          match_token(
            (d.length - BaseMatchLength).reinterpret_as_uint(),
            (d.offset - BaseMatchOffset).reinterpret_as_uint(),
          ),
        )
      } else {
        d.tokens.push(
          match_token(
            (prev_length - BaseMatchLength).reinterpret_as_uint(),
            (prev_offset - BaseMatchOffset).reinterpret_as_uint(),
          ),
        )
      }

      // Insert in the hash table all strings up to the end of the match.
      // index and index-1 are already inserted. If there is not enough
      // lookahead, the last two strings are not inserted into the hash
      // table.
      if d.length <= d.compression_level.fast_skip_hashing {
        let new_index = if d.compression_level.fast_skip_hashing != SkipNever {
          d.index + d.length
        } else {
          d.index + prev_length - 1
        }
        let mut index = d.index + 1
        while index < new_index {
          if index < d.max_insert_index {
            let hash_bytes = Array::new()
            for i = 0; i < MinMatchLength; i = i + 1 {
              hash_bytes.push(d.window[index + i])
            }
            let hash = hash4(hash_bytes)
            let hash_index = (hash & HashMask.reinterpret_as_uint()).reinterpret_as_int()
            // Get previous value with the same hash.
            // Our chain should point to the previous value.
            d.hash_prev[index & WindowMask] = d.hash_head[hash_index]
            // Set the head of the hash chain to us.
            d.hash_head[hash_index] = (index + d.hash_offset).reinterpret_as_uint()
          }
          index = index + 1
        }
        d.index = index
        if d.compression_level.fast_skip_hashing == SkipNever {
          d.byte_available = false
          d.length = MinMatchLength - 1
        }
      } else {
        // For matches this long, we don't bother inserting each individual
        // item into the table.
        d.index = d.index + d.length
      }
      if d.tokens.length() == MaxFlateBlockTokens {
        // The block includes the current character
        d.write_block(d.tokens, d.index) catch {
          err => d.err = Some(err)
        }
        d.tokens.clear()
      }
    } else {
      if d.compression_level.fast_skip_hashing != SkipNever || d.byte_available {
        let i = if d.compression_level.fast_skip_hashing != SkipNever {
          d.index
        } else {
          d.index - 1
        }
        d.tokens.push(literal_token(d.window[i].to_uint()))
        if d.tokens.length() == MaxFlateBlockTokens {
          d.write_block(d.tokens, i + 1) catch {
            err => d.err = Some(err)
          }
          d.tokens.clear()
        }
      }
      d.index = d.index + 1
      if d.compression_level.fast_skip_hashing == SkipNever {
        d.byte_available = true
      }
    }
  }
}

///|
/// Try to find a match starting at index whose length is greater than prevSize.
/// We only look at chainCount possibilities before giving up.
/// Returns (length, offset, ok)
fn Compressor::find_match(
  self : Compressor,
  pos : Int,
  prev_head : Int,
  prev_length : Int,
  lookahead : Int,
) -> (Int, Int, Bool) {
  let mut min_match_look = MaxMatchLength
  if lookahead < min_match_look {
    min_match_look = lookahead
  }
  let win_end = pos + min_match_look
  let win_slice = Array::new()
  for i = 0; i < win_end; i = i + 1 {
    if i < self.window.length() {
      win_slice.push(self.window[i])
    }
  }

  // We quit when we get a match that's at least nice long
  let mut nice = win_end - pos
  if self.compression_level.nice < nice {
    nice = self.compression_level.nice
  }

  // If we've got a match that's good enough, only look in 1/4 the chain.
  let mut tries = self.compression_level.chain
  let mut length = prev_length
  if length >= self.compression_level.good {
    tries = tries >> 2
  }
  let mut w_end = if pos + length < win_slice.length() {
    win_slice[pos + length]
  } else {
    b'\x00'
  }
  let w_pos_start = pos
  let min_index = pos - WindowSize
  let mut i = prev_head
  while tries > 0 {
    tries = tries - 1
    if i + length < win_slice.length() && w_end == win_slice[i + length] {
      let win_i_slice = Array::new()
      for idx = i; idx < win_slice.length(); idx = idx + 1 {
        win_i_slice.push(win_slice[idx])
      }
      let w_pos_slice = Array::new()
      for idx = w_pos_start; idx < win_slice.length(); idx = idx + 1 {
        w_pos_slice.push(win_slice[idx])
      }
      let n = match_len(win_i_slice, w_pos_slice, min_match_look)
      if n > length && (n > MinMatchLength || pos - i <= 4096) {
        length = n
        let offset = pos - i
        if n >= nice {
          // The match is good enough that we don't try to find a better one.
          return (length, offset, true)
        }
        w_end = if pos + n < win_slice.length() {
          win_slice[pos + n]
        } else {
          b'\x00'
        }
      }
    }
    if i == min_index {
      // hashPrev[i & windowMask] has already been overwritten, so stop now.
      break
    }
    i = self.hash_prev[i & WindowMask].reinterpret_as_int() - self.hash_offset
    if i < min_index || i < 0 {
      break
    }
  }
  if length > prev_length {
    (length, pos - i, true)
  } else {
    (length, 0, false)
  }
}

///|
/// Write a block of tokens
fn Compressor::write_block(
  self : Compressor,
  tokens : Array[Token],
  index : Int,
) -> Unit raise {
  if index > 0 {
    let window_slice = if self.block_start <= index {
      self.window[self.block_start:index]
    } else {
      self.window[:0]
    }
    self.block_start = index
    self.w.write_block(tokens, false, window_slice)
    if self.w.err is Some(err) {
      raise err
    }
  }
}

///|
/// Write stored block
fn Compressor::write_stored_block(
  self : Compressor,
  buf : @bytes.View,
) -> Unit raise {
  self.w.write_stored_header(buf.length(), false)
  if self.w.err is Some(err) {
    raise err
  }
  self.w.write_bytes(buf)
  if self.w.err is Some(err) {
    raise err
  }
}

///|
pub impl @io.Writer for Writer with write(self : Writer, bytes : @bytes.View) -> Int raise {
  let array_bytes = Array::new()
  for i = 0; i < bytes.length(); i = i + 1 {
    array_bytes.push(bytes[i])
  }
  self.d.write(array_bytes)
}

///|
/// Write method for Compressor
fn Compressor::write(self : Compressor, b : Array[Byte]) -> Int raise {
  if self.err is Some(err) {
    raise err
  }
  let n = b.length()
  let mut remaining = b
  while remaining.length() > 0 {
    (self.step)(self)
    let consumed = (self.fill)(self, remaining)
    let new_remaining = Array::new()
    for i = consumed; i < remaining.length(); i = i + 1 {
      new_remaining.push(remaining[i])
    }
    remaining = new_remaining
    if self.err is Some(err) {
      raise err
    }
  }
  n
}

///|
/// NewWriterDict is like NewWriter but initializes the new
/// Writer with a preset dictionary. The returned Writer behaves
/// as if the dictionary had been written to it without producing
/// any compressed output. The compressed data written to w
/// can only be decompressed by a reader initialized with the
/// same dictionary (see NewReaderDict).
pub fn new_writer_dict(
  w : &@io.Writer,
  level : Int,
  dict : Array[Byte],
) -> Writer raise {
  let dw = DictWriter::new(w)
  let zw = new_writer(dw, level)
  zw.d.fill_window(dict)
  // Duplicate dictionary for Reset method
  for byte in dict {
    zw.dict.push(byte)
  }
  zw
}

///|
/// DictWriter is a helper that wraps an io.Writer for dictionary support
priv struct DictWriter {
  w : &@io.Writer
}

///|
/// Create a new DictWriter
fn DictWriter::new(w : &@io.Writer) -> DictWriter {
  DictWriter::{ w, }
}

///|
/// Implement Writer trait for DictWriter
impl @io.Writer for DictWriter with write(
  self : DictWriter,
  bytes : @bytes.View,
) -> Int raise {
  self.w.write(bytes)
}

///|
/// Reset discards the writer's state and makes it equivalent to
/// the result of NewWriter or NewWriterDict called with dst
/// and w's level and dictionary.
pub fn Writer::reset(self : Writer, dst : &@io.Writer) -> Unit {
  // Check if this writer was created with a dictionary
  if self.dict.length() > 0 {
    // w was created with NewWriterDict
    let dw = DictWriter::new(dst)
    self.d.reset(dw)
    self.d.fill_window(self.dict)
  } else {
    // w was created with NewWriter
    self.d.reset(dst)
  }
}

///|
/// Reset the compressor state for a new writer
fn Compressor::reset(self : Compressor, w : &@io.Writer) -> Unit {
  self.w.reset(w)
  self.sync = false
  self.err = None
  match self.compression_level.level {
    NoCompression => self.window_end = 0
    BestSpeed => {
      self.window_end = 0
      self.tokens.clear()
      self.best_speed.reset()
    }
    _ => {
      self.chain_head = -1
      // Clear hash tables
      for i = 0; i < self.hash_head.length(); i = i + 1 {
        self.hash_head[i] = 0
      }
      for i = 0; i < self.hash_prev.length(); i = i + 1 {
        self.hash_prev[i] = 0
      }
      self.hash_offset = 1
      self.index = 0
      self.window_end = 0
      self.block_start = 0
      self.byte_available = false
      self.tokens.clear()
      self.length = MinMatchLength - 1
      self.offset = 0
      self.max_insert_index = 0
    }
  }
}

///|
/// Close method for Writer
pub impl @io.Closer for Writer with close(self) {
  self.d.close()
}

///|
/// fill_window will fill the current window with the supplied
/// dictionary and calculate all hashes.
/// This is much faster than doing a full encode.
/// Should only be used after a reset.
fn Compressor::fill_window(self : Compressor, b : Array[Byte]) -> Unit {
  // Do not fill window if we are in store-only mode.
  if self.compression_level.level < 2 {
    return
  }
  if self.index != 0 || self.window_end != 0 {
    abort("internal error: fillWindow called with stale data")
  }

  // If we are given too much, cut it.
  let mut input = b
  if b.length() > WindowSize {
    input = Array::new()
    let start = b.length() - WindowSize
    for i = start; i < b.length(); i = i + 1 {
      input.push(b[i])
    }
  }

  // Add all to window.
  let n = if input.length() < self.window.length() {
    input.length()
  } else {
    self.window.length()
  }
  for i = 0; i < n; i = i + 1 {
    self.window[i] = input[i]
  }

  // Calculate 256 hashes at the time (more L1 cache hits)
  let loops = (n + 256 - MinMatchLength) / 256
  for j = 0; j < loops; j = j + 1 {
    let index = j * 256
    let mut end = index + 256 + MinMatchLength - 1
    if end > n {
      end = n
    }
    let to_check_slice = Array::new()
    for i = index; i < end; i = i + 1 {
      to_check_slice.push(self.window[i])
    }
    let dst_size = to_check_slice.length() - MinMatchLength + 1
    if dst_size <= 0 {
      continue
    }
    let dst = Array::new()
    for i = 0; i < dst_size; i = i + 1 {
      dst.push(0U)
    }
    (self.bulk_hasher)(to_check_slice, dst)
    for i = 0; i < dst.length(); i = i + 1 {
      let val = dst[i]
      let di = i + index
      let hash_index = (val & HashMask.reinterpret_as_uint()).reinterpret_as_int()
      // Get previous value with the same hash.
      // Our chain should point to the previous value.
      self.hash_prev[di & WindowMask] = self.hash_head[hash_index]
      // Set the head of the hash chain to us.
      self.hash_head[hash_index] = (di + self.hash_offset).reinterpret_as_uint()
    }
  }
  // Update window information.
  self.window_end = n
  self.index = n
}

///|
/// Close method for Compressor
fn Compressor::close(self : Compressor) -> Unit raise {
  if self.err is Some(err) {
    raise err
  }
  self.sync = true
  (self.step)(self)
  if self.err is Some(err) {
    raise err
  }
  self.w.write_stored_header(0, true)
  if self.w.err is Some(err) {
    raise err
  }
  self.w.flush()
  if self.w.err is Some(err) {
    raise err
  }
  self.err = Some(WriterClosed)
}

///|
/// Flush method for Writer
pub fn Writer::flush(self : Writer) -> Unit raise {
  self.d.sync_flush()
}

///|
/// Sync flush for Compressor
fn Compressor::sync_flush(self : Compressor) -> Unit raise {
  if self.err is Some(err) {
    raise err
  }
  self.sync = true
  (self.step)(self)
  if self.err is None {
    self.w.write_stored_header(0, false)
    if self.w.err is Some(err) {
      raise err
    }
    self.w.flush()
    if self.w.err is Some(err) {
      raise err
    }
  }
  self.sync = false
  if self.err is Some(err) {
    raise err
  }
}
