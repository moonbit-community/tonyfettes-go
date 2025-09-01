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
pub suberror InternalError String

///|
impl Show for InternalError with output(self, logger) {
  match self {
    InternalError(msg) => logger.write_string("flate: internal error: \{msg}")
  }
}

///|
/// HuffmanDecoder represents a Huffman decoding table
struct HuffmanDecoder {
  mut min : Int // the minimum code length
  chunks : Array[UInt] // chunks as described in algorithm
  mut links : Array[Array[UInt]] // overflow links 
  mut link_mask : UInt // mask the width of the link table
} derive(Show)

///|
/// Create a new HuffmanDecoder
pub fn HuffmanDecoder::new() -> HuffmanDecoder {
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
pub fn HuffmanDecoder::init(
  self : HuffmanDecoder,
  lengths : Array[Int],
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
