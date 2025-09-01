///|
/// HCode represents a Huffman code with a bit code and bit length
priv struct HCode {
  code : UInt
  len : UInt
} derive(Eq, Show)

///|
/// Set the code and length of an HCode
fn HCode::set(self : HCode, code : UInt, length : UInt) -> Unit {
  // Note: MoonBit structs are immutable by default, so we need a mutable reference
  // This will need to be addressed when used with mutable data structures
}

///|
/// LiteralNode represents a node with a literal and frequency
priv struct LiteralNode {
  literal : UInt
  freq : Int
} derive(Eq, Show)

///|
/// Create a max node sentinel
fn max_node() -> LiteralNode {
  LiteralNode::{ literal: 0xFFFF, freq: 0x7FFFFFFF }
}

///|
/// LevelInfo describes the state of the constructed tree for a given depth
priv struct LevelInfo {
  level : Int // Our level for better printing
  last_freq : Int // The frequency of the last node at this level
  next_char_freq : Int // The frequency of the next character to add to this level
  next_pair_freq : Int // The frequency of the next pair (from level below) to add to this level
  needed : Int // The number of chains remaining to generate for this level
} derive(Show)

///|
let max_bits_limit = 16

///|
/// HuffmanEncoder represents a Huffman encoder
priv struct HuffmanEncoder {
  codes : Array[HCode]
  freq_cache : Array[LiteralNode]
  bit_count : Array[Int]
  // We don't need sorting helpers in MoonBit since we can use built-in sorting
} derive(Show)

///|
/// Create a new Huffman encoder with specified size
fn HuffmanEncoder::new(size : Int) -> HuffmanEncoder {
  HuffmanEncoder::{
    codes: Array::make(size, HCode::{ code: 0, len: 0 }),
    freq_cache: Array::new(),
    bit_count: Array::make(max_bits_limit + 1, 0),
  }
}

///|
/// Calculate bit length for given frequencies
fn HuffmanEncoder::bit_length(self : HuffmanEncoder, freq : Array[Int]) -> Int {
  let mut total = 0
  for i = 0; i < freq.length(); i = i + 1 {
    let f = freq[i]
    if f != 0 {
      total += f * self.codes[i].len.reinterpret_as_int()
    }
  }
  total
}

///|
/// Reverse bits for Huffman encoding
fn reverse_bits(number : UInt, bit_length : Int) -> UInt {
  // Implement bit reversal - this is a simplified version
  // In Go this uses math/bits.Reverse16, we'll implement a basic version
  let mut result : UInt = 0
  let mut n = number
  let mut len = bit_length
  while len > 0 {
    result = (result << 1) | (n & 1)
    n = n >> 1
    len = len - 1
  }
  result
}

///|
/// Generate fixed literal encoding
fn generate_fixed_literal_encoding() -> HuffmanEncoder {
  let codes = Array::make(286, HCode::{ code: 0, len: 0 })
  for ch = 0; ch < 286; ch = ch + 1 {
    let (bits, size) = if ch < 144 {
      // size 8, 000110000  .. 10111111
      (ch.reinterpret_as_uint() + 48, 8)
    } else if ch < 256 {
      // size 9, 110010000 .. 111111111
      (ch.reinterpret_as_uint() + 400 - 144, 9)
    } else if ch < 280 {
      // size 7, 0000000 .. 0010111
      (ch.reinterpret_as_uint() - 256, 7)
    } else {
      // size 8, 11000000 .. 11000111
      (ch.reinterpret_as_uint() + 192 - 280, 8)
    }
    codes[ch] = HCode::{
      code: reverse_bits(bits, size),
      len: size.reinterpret_as_uint(),
    }
  }
  HuffmanEncoder::{
    codes,
    freq_cache: Array::new(),
    bit_count: Array::make(max_bits_limit + 1, 0),
  }
}

///|
/// Generate fixed offset encoding
fn generate_fixed_offset_encoding() -> HuffmanEncoder {
  let codes = Array::make(30, HCode::{ code: 0, len: 0 })
  for ch = 0; ch < codes.length(); ch = ch + 1 {
    codes[ch] = HCode::{
      code: reverse_bits(ch.reinterpret_as_uint(), 5),
      len: 5,
    }
  }
  HuffmanEncoder::{
    codes,
    freq_cache: Array::new(),
    bit_count: Array::make(max_bits_limit + 1, 0),
  }
}

///|
/// Pre-computed fixed encodings
let fixed_literal_encoding : HuffmanEncoder = generate_fixed_literal_encoding()

///|
let fixed_offset_encoding : HuffmanEncoder = generate_fixed_offset_encoding()
