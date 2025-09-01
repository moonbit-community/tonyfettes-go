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
let hashBits : Int = 17 // After 17 performance degrades

///|
let hashSize : Int = 1 << hashBits

///|
let hashMask : Int = (1 << hashBits) - 1

///|
let maxHashOffset : Int = 1 << 24

///|
const SkipNever : Int = 2147483647 // math.MaxInt32

///|
/// Compression level configuration
struct CompressionLevel {
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
pub suberror WriterClosed

///|
impl Show for WriterClosed with output(self, logger) {
  logger.write_string("flate: WriterClosed")
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
  best_speed : DeflateFast // Encoder for BestSpeed

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
  max_insert_index : Int // TODO: make mutable when implementing full algorithm
  mut err : Error?

  // hash_match must be able to contain hashes for the maximum match length.
  hash_match : Array[UInt] // TODO: make mutable when implementing full algorithm
} derive(Show)

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
  (32 - hashBits)
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
  dst[0] = (hb * Hashmul) >> (32 - hashBits)
  let end = b.length() - MinMatchLength + 1
  for i = 1; i < end; i = i + 1 {
    hb = (hb << 8) | b[i + 3].to_uint()
    dst[i] = (hb * Hashmul) >> (32 - hashBits)
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
} derive(Show)

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
    hash_head: Array::make(hashSize, 0),
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
suberror InvalidCompressionLevel Int

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
      // self.best_speed = DeflateFast::new() // TODO: implement
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
      d.step = Compressor::deflate_step
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
    if self.hash_offset > maxHashOffset {
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
  // Fast encoding using DeflateFast encoder
  if d.window_end == 0 && !d.sync {
    return
  }

  // Get the input window data
  let input = Array::new()
  for i = 0; i < d.window_end; i = i + 1 {
    input.push(d.window[i])
  }
  if input.length() > 0 {
    // Use DeflateFast to encode the input
    d.tokens = d.best_speed.encode(d.tokens, input)
  }

  // Add EOF token if we're syncing or have enough tokens
  if d.sync || d.tokens.length() >= MaxFlateBlockTokens {
    // Add EOF marker
    d.tokens.push(literal_token(256))

    // Write tokens using fixed Huffman encoding (fast)
    try {
      d.w.write_fixed_header(d.sync)
      d.w.write_tokens(
        d.tokens,
        fixed_literal_encoding.codes,
        fixed_offset_encoding.codes,
      )
    } catch {
      err => d.err = Some(err)
    }
    d.tokens.clear()
  }
  d.window_end = 0
}

///|
/// Deflate step function
fn Compressor::deflate_step(self : Compressor) -> Unit {
  // TODO: implement full deflate algorithm
  self.store_huff()
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
/// Public write method for Writer
pub fn Writer::write(self : Writer, bytes : @bytes.View) -> Int raise {
  let array_bytes = Array::new()
  for i = 0; i < bytes.length(); i = i + 1 {
    array_bytes.push(bytes[i])
  }
  self.d.write(array_bytes)
}

///|
/// Write method for Writer implementing io.Writer trait
pub impl @io.Writer for Writer with write(self, bytes) {
  self.write(bytes) catch {
    _ => 0
  }
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
/// Close method for Writer
impl @io.Closer for Writer with close(self) {
  self.d.close()
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
