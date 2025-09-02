///|
/// Constants for inflate.mbt
const MaxCodeLen = 16

///|
const MaxNumLit = 286

///|
const MaxNumDist = 30

///|
const NumCodes = 19

///|
const EndBlockMarker = 256

///|
/// Huffman decoding constants
const HuffmanChunkBits = 9

///|
const HuffmanNumChunks : Int = 1 << HuffmanChunkBits

///|
const HuffmanCountMask = 15

///|
const HuffmanValueShift = 4

///|
/// Error types for DEFLATE decompression
pub suberror CorruptInputError Int64

///|
impl Show for CorruptInputError with output(self, logger) {
  match self {
    CorruptInputError(offset) =>
      logger.write_string("flate: corrupt input before offset \{offset}")
  }
}

///|
/// HuffmanDecoder represents a Huffman decoding table
priv struct HuffmanDecoder {
  mut min : Int // the minimum code length
  chunks : Array[UInt] // chunks as described in algorithm
  mut links : Array[Array[UInt]] // overflow links
  mut link_mask : UInt // mask the width of the link table
}

///|
/// Create a new HuffmanDecoder
fn HuffmanDecoder::new() -> HuffmanDecoder {
  HuffmanDecoder::{
    min: 0,
    chunks: Array::make(HuffmanNumChunks, 0),
    links: Array::new(),
    link_mask: 0,
  }
}

///|
/// Initialize Huffman decoding tables from array of code lengths.
/// Following this function, h is guaranteed to be initialized into a complete
/// tree (i.e., neither over-subscribed nor under-subscribed). The exception is a
/// degenerate case where the tree has only a single symbol with length 1. Empty
/// trees are permitted.
fn HuffmanDecoder::init(
  self : HuffmanDecoder,
  lengths : ArrayView[Int],
) -> Bool {
  if self.min != 0 {
    // Reset the decoder
    self.min = 0
    for i = 0; i < self.chunks.length(); i = i + 1 {
      self.chunks[i] = 0
    }
    self.links.clear()
    self.link_mask = 0
  }

  // Count number of codes of each length, compute min and max length
  let count = Array::make(MaxCodeLen, 0)
  let mut min = 0
  let mut max = 0
  for i = 0; i < lengths.length(); i = i + 1 {
    let n = lengths[i]
    if n == 0 {
      continue
    }
    if min == 0 || n < min {
      min = n
    }
    if n > max {
      max = n
    }
    count[n] = count[n] + 1
  }

  // Empty tree. The decompressor.huffSym function will fail later if the tree
  // is used. Technically, an empty tree is only valid for the HDIST tree and
  // not the HCLEN and HLIT tree.
  if max == 0 {
    return true
  }
  let mut code = 0
  let nextcode = Array::make(MaxCodeLen, 0)
  for i = min; i <= max; i = i + 1 {
    code = code << 1
    nextcode[i] = code
    code = code + count[i]
  }

  // Check that the coding is complete (i.e., that we've
  // assigned all 2-to-the-max possible bit sequences).
  // Exception: To be compatible with zlib, we also need to
  // accept degenerate single-code codings.
  if code != 1 << max && !(code == 1 && max == 1) {
    return false
  }
  self.min = min
  if max > HuffmanChunkBits {
    let num_links = 1 << (max - HuffmanChunkBits)
    self.link_mask = (num_links - 1).reinterpret_as_uint()

    // create link tables
    let link = nextcode[HuffmanChunkBits + 1] >> 1
    self.links = Array::make(HuffmanNumChunks - link, Array::new())
    for j = link; j < HuffmanNumChunks; j = j + 1 {
      let reverse = reverse_bits_16(j.reinterpret_as_uint(), HuffmanChunkBits)
      let off = j - link
      self.chunks[reverse.reinterpret_as_int()] = ((off << HuffmanValueShift) |
      (HuffmanChunkBits + 1)).reinterpret_as_uint()
      self.links[off] = Array::make(num_links, 0)
    }
  }
  for i = 0; i < lengths.length(); i = i + 1 {
    let n = lengths[i]
    if n == 0 {
      continue
    }
    let code = nextcode[n]
    nextcode[n] = nextcode[n] + 1
    let chunk = ((i << HuffmanValueShift) | n).reinterpret_as_uint()
    let reverse = reverse_bits_16(code.reinterpret_as_uint(), n)
    if n <= HuffmanChunkBits {
      let mut off = reverse.reinterpret_as_int()
      while off < self.chunks.length() {
        self.chunks[off] = chunk
        off = off + (1 << n)
      }
    } else {
      let j = reverse.reinterpret_as_int() & (HuffmanNumChunks - 1)
      let value = (self.chunks[j] >> HuffmanValueShift).reinterpret_as_int()
      let linktab = self.links[value]
      let reverse_shifted = reverse.reinterpret_as_int() >> HuffmanChunkBits
      let mut off = reverse_shifted
      while off < linktab.length() {
        linktab[off] = chunk
        off = off + (1 << (n - HuffmanChunkBits))
      }
    }
  }
  true
}

///|
/// Reverse bits utility function for 16-bit values
fn reverse_bits_16(n : UInt, bits : Int) -> UInt {
  let mut result : UInt = 0
  let mut num = n
  let mut remaining = bits
  while remaining > 0 {
    result = (result << 1) | (num & 1)
    num = num >> 1
    remaining = remaining - 1
  }
  result
}

///|
/// Additional constants from Go's deflate.go (moved from deflate.mbt to avoid duplication)
// const MaxMatchOffset = 1 << 15 // The largest match offset (already defined in deflate.mbt)

///|
/// Code order for HCLEN encoding - static array since constants can't be arrays
let code_order = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
pub suberror InternalError String

///|
pub(open) trait Reader: @io.Reader + @io.ByteReader {}

///|
/// Resetter trait for resetting a ReadCloser
pub(open) trait Resetter {
  reset(self : Self, r : &Reader, dict : @bytes.View) -> Unit raise
}

///|
/// Global fixed Huffman decoder initialization
let fixed_huffman_decoder : Ref[HuffmanDecoder?] = Ref::new(None)

///|
/// Decompressor state - removed derive(Show) due to trait constraints
priv struct Decompressor {
  // Input source
  mut r : &Reader
  mut roffset : Int64

  // Input bits, in top of b
  mut b : UInt
  mut nb : UInt

  // Huffman decoders for literal/length, distance
  mut h1 : HuffmanDecoder
  mut h2 : HuffmanDecoder

  // Length arrays used to define Huffman codes
  bits : Array[Int] // Size: MaxNumLit + MaxNumDist
  codebits : Array[Int] // Size: NumCodes

  // Output history, buffer
  mut dict : DictDecoder

  // Temporary buffer (avoids repeated allocation)
  buf : @bytes.View // Size: 4

  // Next step in the decompression, and decompression state
  mut step : (Decompressor) -> Unit raise
  mut step_state : StepState
  mut final_ : Bool
  mut err : Error?
  mut to_read : Array[Byte]
  mut hl : HuffmanDecoder?
  mut hd : HuffmanDecoder?
  mut copy_len : Int
  mut copy_dist : Int
}

///|
/// Create a new Decompressor
fn[Reader : @io.Reader + @io.ByteReader] Decompressor::new(
  r : Reader,
) -> Decompressor {
  Decompressor::{
    r,
    roffset: 0,
    b: 0,
    nb: 0,
    h1: HuffmanDecoder::new(),
    h2: HuffmanDecoder::new(),
    bits: Array::make(MaxNumLit + MaxNumDist, 0),
    codebits: Array::make(NumCodes, 0),
    dict: DictDecoder::new(),
    buf: Bytes::make(4, 0),
    step: _ => (),
    step_state: StepState::StateInit,
    final_: false,
    err: None,
    to_read: Array::new(),
    hl: None,
    hd: None,
    copy_len: 0,
    copy_dist: 0,
  }
}

///|
priv enum StepState {
  StateInit
  StateDict
}

///|
/// fixedHuffmanDecoderInit initializes the fixed Huffman decoder
fn fixed_huffman_decoder_init() -> Unit {
  match fixed_huffman_decoder.val {
    Some(_) => () // Already initialized
    None => {
      // These come from the RFC section 3.2.6.
      let bits = Array::make(288, 0)
      for i = 0; i < 144; i = i + 1 {
        bits[i] = 8
      }
      for i = 144; i < 256; i = i + 1 {
        bits[i] = 9
      }
      for i = 256; i < 280; i = i + 1 {
        bits[i] = 7
      }
      for i = 280; i < 288; i = i + 1 {
        bits[i] = 8
      }
      let decoder = HuffmanDecoder::new()
      let _ = decoder.init(bits)
      fixed_huffman_decoder.val = Some(decoder)
    }
  }
}

///|
/// Returns the fixed Huffman decoder, initializing it if necessary
fn get_fixed_huffman_decoder() -> HuffmanDecoder {
  fixed_huffman_decoder_init()
  match fixed_huffman_decoder.val {
    Some(decoder) => decoder
    None => abort("Fixed Huffman decoder not initialized")
  }
}

///|
/// moreBits reads more bits from the input stream
fn Decompressor::more_bits(self : Decompressor) -> Unit raise {
  let c = self.r.read_byte()
  self.roffset += 1
  self.b = self.b | (c.to_uint() << self.nb.reinterpret_as_int())
  self.nb += 8
}

///|
/// huffSym reads the next Huffman-encoded symbol from decompressor according to h
fn Decompressor::huff_sym(self : Decompressor, h : HuffmanDecoder) -> Int raise {
  let mut n = h.min.reinterpret_as_uint()
  let mut nb = self.nb
  let mut b = self.b
  while true {
    while nb < n {
      let c = self.r.read_byte() catch {
        err => {
          self.b = b
          self.nb = nb
          raise err
        }
      }
      self.roffset += 1
      b = b | (c.to_uint() << (nb.reinterpret_as_int() & 31))
      nb += 8
    }
    let chunk = h.chunks[(b & (HuffmanNumChunks.reinterpret_as_uint() - 1)).reinterpret_as_int()]
    n = chunk & HuffmanCountMask.reinterpret_as_uint()
    if n > HuffmanChunkBits.reinterpret_as_uint() {
      let link_index = (chunk >> HuffmanValueShift).reinterpret_as_int()
      let link_offset = ((b >> HuffmanChunkBits) & h.link_mask).reinterpret_as_int()
      let chunk2 = h.links[link_index][link_offset]
      n = chunk2 & HuffmanCountMask.reinterpret_as_uint()
    }
    if n <= nb {
      if n == 0 {
        self.b = b
        self.nb = nb
        raise CorruptInputError(self.roffset)
      }
      self.b = b >> (n.reinterpret_as_int() & 31)
      self.nb = nb - n
      return (chunk >> HuffmanValueShift).reinterpret_as_int()
    }
  }
  // This should never be reached
  abort("Unreachable code in huff_sym")
}

///|
/// nextBlock processes the next block from the decompressor
fn Decompressor::next_block(f : Decompressor) -> Unit raise {
  while f.nb < 1 + 2 {
    f.more_bits()
  }
  f.final_ = (f.b & 1) == 1
  f.b = f.b >> 1
  let typ = f.b & 3
  f.b = f.b >> 2
  f.nb -= 1 + 2
  match typ {
    0 => f.data_block()
    1 => {
      // compressed, fixed Huffman tables
      f.hl = Some(get_fixed_huffman_decoder())
      f.hd = None
      f.huffman_block()
    }
    2 => {
      // compressed, dynamic Huffman tables
      f.read_huffman()
      f.hl = Some(f.h1)
      f.hd = Some(f.h2)
      f.huffman_block()
    }
    _ =>
      // 3 is reserved
      f.err = Some(CorruptInputError(f.roffset))
  }
}

///|
/// read reads from the decompressor
impl @io.Reader for Decompressor with read(self : Decompressor, b : @bytes.View) -> Int raise {
  for {
    if self.to_read.length() > 0 {
      let n = if b.length() < self.to_read.length() {
        b.length()
      } else {
        self.to_read.length()
      }
      for i = 0; i < n; i = i + 1 {
        b[i] = self.to_read[i]
      }
      // Remove copied bytes from to_read
      let new_to_read = Array::new()
      for i = n; i < self.to_read.length(); i = i + 1 {
        new_to_read.push(self.to_read[i])
      }
      self.to_read = new_to_read
      if self.to_read.length() == 0 {
        match self.err {
          Some(e) => raise e
          None => return n
        }
      }
      return n
    }
    match self.err {
      Some(e) => raise e
      None => ()
    }
    (self.step)(self)
    match self.err {
      Some(_) =>
        if self.to_read.length() == 0 {
          self.to_read = self.dict.read_flush() // Flush what's left in case of error
        }
      None => ()
    }
  }
}

///|
/// close closes the decompressor
impl @io.Closer for Decompressor with close(self : Decompressor) -> Unit raise {
  match self.err {
    Some(@io.EOF) => ()
    Some(err) => raise err
    None => ()
  }
}

///|
/// dataBlock copies a single uncompressed data block from input to output
fn Decompressor::data_block(self : Decompressor) -> Unit raise {
  // Uncompressed.
  // Discard current half-byte.
  self.nb = 0
  self.b = 0

  // Length then ones-complement of length.
  let nr = @io.read_full(self.r, self.buf[0:4]) catch {
    @io.EOF => {
      self.err = Some(@io.UnexpectedEof)
      return
    }
    err => {
      self.err = Some(err)
      return
    }
  }
  self.roffset += nr.to_int64()
  let n = self.buf[0].to_int() | (self.buf[1].to_int() << 8)
  let nn = self.buf[2].to_int() | (self.buf[3].to_int() << 8)
  if nn != (n ^ 0xFFFF) {
    raise CorruptInputError(self.roffset)
  }
  if n == 0 {
    self.to_read = self.dict.read_flush()
    self.finish_block()
    return
  }
  self.copy_len = n
  self.copy_data()
}

///|
/// copyData copies copy_len bytes from the underlying reader into hist
/// It pauses for reads when hist is full
fn Decompressor::copy_data(self : Decompressor) -> Unit raise {
  let mut buf = self.dict.write_slice()
  if buf.length() > self.copy_len {
    buf = buf[:self.copy_len]
  }
  let cnt = @io.read_full(self.r, buf) catch {
    @io.EOF => raise @io.UnexpectedEof
    err => raise err
  }
  self.roffset += cnt.to_int64()
  self.copy_len -= cnt
  self.dict.write_mark(cnt)
  if self.dict.avail_write() == 0 || self.copy_len > 0 {
    self.to_read = self.dict.read_flush()
    self.step = Decompressor::copy_data
    return
  }
  self.finish_block()
}

///|
/// finishBlock finishes processing the current block
fn Decompressor::finish_block(self : Decompressor) -> Unit {
  if self.final_ {
    if self.dict.avail_read() > 0 {
      self.to_read = self.dict.read_flush()
    }
    self.err = Some(@io.EOF)
  }
  self.step = Decompressor::next_block
}

///|
/// readHuffman reads the Huffman tables for a dynamic block
fn Decompressor::read_huffman(f : Decompressor) -> Unit raise {
  // HLIT[5], HDIST[5], HCLEN[4].
  while f.nb < 5 + 5 + 4 {
    f.more_bits()
  }
  let nlit = (f.b & 0x1F).reinterpret_as_int() + 257
  if nlit > MaxNumLit {
    raise CorruptInputError(f.roffset)
  }
  f.b = f.b >> 5
  let ndist = (f.b & 0x1F).reinterpret_as_int() + 1
  if ndist > MaxNumDist {
    raise CorruptInputError(f.roffset)
  }
  f.b = f.b >> 5
  let nclen = (f.b & 0xF).reinterpret_as_int() + 4
  // NumCodes is 19, so nclen is always valid.
  f.b = f.b >> 4
  f.nb -= 5 + 5 + 4

  // (HCLEN+4)*3 bits: code lengths in the magic code_order order.
  for i = 0; i < nclen; i = i + 1 {
    while f.nb < 3 {
      f.more_bits()
    }
    f.codebits[code_order[i]] = (f.b & 0x7).reinterpret_as_int()
    f.b = f.b >> 3
    f.nb -= 3
  }
  for i = nclen; i < code_order.length(); i = i + 1 {
    f.codebits[code_order[i]] = 0
  }
  if !f.h1.init(f.codebits) {
    raise CorruptInputError(f.roffset)
  }

  // HLIT + 257 code lengths, HDIST + 1 code lengths,
  // using the code length Huffman code.
  let mut i = 0
  let n = nlit + ndist
  while i < n {
    let x = f.huff_sym(f.h1)
    if x < 16 {
      // Actual length.
      f.bits[i] = x
      i += 1
      continue
    }
    // Repeat previous length or zero.
    let mut rep = 0
    let mut nb = 0
    let mut b = 0
    match x {
      16 => {
        rep = 3
        nb = 2
        if i == 0 {
          raise CorruptInputError(f.roffset)
        }
        b = f.bits[i - 1]
      }
      17 => {
        rep = 3
        nb = 3
        b = 0
      }
      18 => {
        rep = 11
        nb = 7
        b = 0
      }
      _ => raise InternalError("unexpected length code")
    }
    while f.nb < nb.reinterpret_as_uint() {
      f.more_bits()
    }
    rep += (f.b & ((1 << nb) - 1)).reinterpret_as_int()
    f.b = f.b >> nb
    f.nb -= nb.reinterpret_as_uint()
    if i + rep > n {
      raise CorruptInputError(f.roffset)
    }
    for j = 0; j < rep; j = j + 1 {
      f.bits[i] = b
      i += 1
    }
  }
  if !f.h1.init(f.bits[0:nlit]) || !f.h2.init(f.bits[nlit:nlit + ndist]) {
    raise CorruptInputError(f.roffset)
  }

  // As an optimization, we can initialize the min bits to read at a time
  // for the HLIT tree to the length of the EOB marker since we know that
  // every block must terminate with one.
  if f.h1.min < f.bits[EndBlockMarker] {
    f.h1.min = f.bits[EndBlockMarker]
  }
}

///|
/// huffmanBlock decodes a single Huffman block from decompressor
fn Decompressor::huffman_block(self : Decompressor) -> Unit raise {
  match self.step_state {
    StepState::StateInit => self.huffman_read_literal()
    StepState::StateDict => self.huffman_copy_history()
  }
}

///|
/// huffmanReadLiteral reads literal and/or (length, distance) pairs
fn Decompressor::huffman_read_literal(self : Decompressor) -> Unit raise {
  while true {
    let hl = match self.hl {
      Some(h) => h
      None => raise InternalError("no literal huffman decoder")
    }
    let v = self.huff_sym(hl)
    if v < 256 {
      self.dict.write_byte(v.to_byte())
      if self.dict.avail_write() == 0 {
        self.to_read = self.dict.read_flush()
        self.step = Decompressor::huffman_block
        self.step_state = StateInit
        return
      }
      continue
    } else if v == 256 {
      self.finish_block()
      return
    }

    // Handle length/distance pairs (v >= 257)
    let mut length = 0
    let mut n = 0
    if v < 265 {
      length = v - (257 - 3)
      n = 0
    } else if v < 269 {
      length = v * 2 - (265 * 2 - 11)
      n = 1
    } else if v < 273 {
      length = v * 4 - (269 * 4 - 19)
      n = 2
    } else if v < 277 {
      length = v * 8 - (273 * 8 - 35)
      n = 3
    } else if v < 281 {
      length = v * 16 - (277 * 16 - 67)
      n = 4
    } else if v < 285 {
      length = v * 32 - (281 * 32 - 131)
      n = 5
    } else if v < MaxNumLit {
      length = 258
      n = 0
    } else {
      raise CorruptInputError(self.roffset)
    }
    if n > 0 {
      while self.nb < n.reinterpret_as_uint() {
        self.more_bits()
      }
      length += (self.b & ((1 << n) - 1)).reinterpret_as_int()
      self.b = self.b >> n
      self.nb -= n.reinterpret_as_uint()
    }
    let mut dist = 0
    match self.hd {
      None => {
        // Fixed distance encoding
        while self.nb < 5 {
          self.more_bits()
        }
        dist = reverse_bits_8((self.b & 0x1F).to_byte() << 3).to_int()
        self.b = self.b >> 5
        self.nb -= 5
      }
      Some(hd) => dist = self.huff_sym(hd)
    }
    if dist < 4 {
      dist += 1
    } else if dist < MaxNumDist {
      let nb = ((dist - 2) >> 1).reinterpret_as_uint()
      let extra = (dist & 1) << nb.reinterpret_as_int()
      while self.nb < nb {
        self.more_bits()
      }
      let extra2 = (self.b & ((1 << nb.reinterpret_as_int()) - 1)).reinterpret_as_int()
      self.b = self.b >> nb.reinterpret_as_int()
      self.nb -= nb
      dist = (1 << (nb.reinterpret_as_int() + 1)) + 1 + extra + extra2
    } else {
      raise CorruptInputError(self.roffset)
    }

    // No check on length; encoding can be prescient.
    if dist > self.dict.hist_size() {
      raise CorruptInputError(self.roffset)
    }
    self.copy_len = length
    self.copy_dist = dist
    self.huffman_copy_history()
    return
  }
}

///|
/// huffmanCopyHistory performs a backwards copy according to RFC section 3.2.3
fn Decompressor::huffman_copy_history(self : Decompressor) -> Unit raise {
  let cnt = self.dict.try_write_copy(self.copy_dist, self.copy_len)
  let real_cnt = if cnt == 0 {
    self.dict.write_copy(self.copy_dist, self.copy_len)
  } else {
    cnt
  }
  self.copy_len -= real_cnt
  if self.dict.avail_write() == 0 || self.copy_len > 0 {
    self.to_read = self.dict.read_flush()
    self.step = Decompressor::huffman_block
    self.step_state = StateDict
    return
  }
  self.huffman_read_literal()
}

///|
/// reverse_bits_8 reverses bits in a byte
fn reverse_bits_8(b : Byte) -> Byte {
  let mut result = 0
  let mut byte = b.to_int()
  for _i = 0; _i < 8; _i = _i + 1 {
    result = (result << 1) | (byte & 1)
    byte = byte >> 1
  }
  result.to_byte()
}

///|
/// reset resets the decompressor for a new stream
impl Resetter for Decompressor with reset(
  self : Decompressor,
  r : &Reader,
  dict : @bytes.View,
) -> Unit raise {
  self.roffset = 0
  self.b = 0
  self.nb = 0
  self.h1 = HuffmanDecoder::new()
  self.h2 = HuffmanDecoder::new()
  for i = 0; i < self.bits.length(); i = i + 1 {
    self.bits[i] = 0
  }
  for i = 0; i < self.codebits.length(); i = i + 1 {
    self.codebits[i] = 0
  }
  self.dict = DictDecoder::new()
  for i = 0; i < 4; i = i + 1 {
    self.buf[i] = 0
  }
  self.step = Decompressor::next_block
  self.step_state = StepState::StateInit
  self.final_ = false
  self.err = None
  self.to_read = Array::new()
  self.hl = None
  self.hd = None
  self.copy_len = 0
  self.copy_dist = 0
  self.r = r
  self.dict.init(MaxMatchOffset, dict)
}

///|
/// new_reader returns a new ReadCloser that can be used to read the uncompressed
/// version of r. If r does not also implement io.ByteReader, the decompressor may
/// read more data than necessary from r.
pub fn[R : @io.Reader + @io.ByteReader] new_reader(r : R) -> &@io.ReadCloser {
  fixed_huffman_decoder_init()
  let f = Decompressor::new(r)
  for i = 0; i < MaxNumLit + MaxNumDist; i = i + 1 {
    f.bits[i] = 0
  }
  for i = 0; i < NumCodes; i = i + 1 {
    f.codebits[i] = 0
  }
  f.step = Decompressor::next_block
  f.dict.init(MaxMatchOffset, [])
  f
}

///|
/// new_reader_dict is like new_reader but initializes the reader with a preset
/// dictionary. The returned reader behaves as if the uncompressed data stream
/// started with the given dictionary, which has already been read.
pub fn[R : @io.Reader + @io.ByteReader] new_reader_dict(
  r : R,
  dict : @bytes.View,
) -> &@io.ReadCloser {
  fixed_huffman_decoder_init()
  let f = Decompressor::new(r)
  for i = 0; i < MaxNumLit + MaxNumDist; i = i + 1 {
    f.bits[i] = 0
  }
  for i = 0; i < NumCodes; i = i + 1 {
    f.codebits[i] = 0
  }
  f.step = Decompressor::next_block
  f.dict.init(MaxMatchOffset, dict)
  f
}
