///|
/// HCode represents a Huffman code with a bit code and bit length
priv struct HCode {
  code : UInt
  len : UInt
} derive(Eq)

///|
/// Set the code and length of an HCode (returns new HCode since structs are immutable)
fn HCode::new(code : UInt, length : UInt) -> HCode {
  HCode::{ code, len: length }
}

///|
/// LiteralNode represents a node with a literal and frequency
priv struct LiteralNode {
  literal : UInt
  freq : Int
} derive(Eq)

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
  mut next_pair_freq : Int // The frequency of the next pair (from level below) to add to this level
  mut needed : Int // The number of chains remaining to generate for this level
}

///|
let max_bits_limit = 16

///|
/// HuffmanEncoder represents a Huffman encoder
priv struct HuffmanEncoder {
  codes : Array[HCode]
  freq_cache : Array[LiteralNode]
  bit_count : Array[Int]
  // We don't need sorting helpers in MoonBit since we can use built-in sorting
} derive(Eq)

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

///|
/// Comparison function for sorting LiteralNode by frequency
fn by_frequency(a : LiteralNode, b : LiteralNode) -> Int {
  if a.freq < b.freq {
    -1
  } else if a.freq > b.freq {
    1
    // If frequencies are equal, sort by literal value for deterministic results
  } else if a.literal < b.literal {
    -1
  } else if a.literal > b.literal {
    1
  } else {
    0
  }
}

///|
/// Quick sort implementation for Array[LiteralNode]
fn quicksort(
  arr : Array[LiteralNode],
  compare : (LiteralNode, LiteralNode) -> Int,
) -> Unit {
  quicksort_range(arr, 0, arr.length() - 1, compare)
}

///|
/// Quick sort for a range of the array
fn quicksort_range(
  arr : Array[LiteralNode],
  low : Int,
  high : Int,
  compare : (LiteralNode, LiteralNode) -> Int,
) -> Unit {
  if low < high {
    let pi = partition(arr, low, high, compare)
    quicksort_range(arr, low, pi - 1, compare)
    quicksort_range(arr, pi + 1, high, compare)
  }
}

///|
/// Partition function for quicksort
fn partition(
  arr : Array[LiteralNode],
  low : Int,
  high : Int,
  compare : (LiteralNode, LiteralNode) -> Int,
) -> Int {
  let pivot = arr[high]
  let mut i = low - 1
  for j = low; j < high; j = j + 1 {
    if compare(arr[j], pivot) <= 0 {
      i = i + 1
      let temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    }
  }
  let temp = arr[i + 1]
  arr[i + 1] = arr[high]
  arr[high] = temp
  i + 1
}

///|
/// bitCounts computes the number of literals assigned to each bit size in the Huffman encoding.
/// It is only called when list.length >= 3.
/// The cases of 0, 1, and 2 literals are handled by special case code.
///
/// list is an array of the literals with non-zero frequencies
/// and their associated frequencies. The array is in order of increasing
/// frequency and has as its last element a special element with frequency
/// MaxInt32.
///
/// maxBits is the maximum number of bits that should be used to encode any literal.
/// It must be less than 16.
///
/// bitCounts returns an integer slice in which slice[i] indicates the number of literals
/// that should be encoded in i bits.
fn HuffmanEncoder::bit_counts(
  h : HuffmanEncoder,
  list : Array[LiteralNode],
  max_bits : Int,
) -> Array[Int] {
  if max_bits >= max_bits_limit {
    abort("flate: maxBits too large")
  }
  let n = list.length()
  // In Go: list = list[0 : n+1] - we need to extend the list
  // list[n] = maxNode()
  list.push(max_node())

  // The tree can't have greater depth than n - 1, no matter what. This
  // saves a little bit of work in some small cases
  let mut max_bits = max_bits
  if max_bits > n - 1 {
    max_bits = n - 1
  }

  // Create information about each of the levels.
  // A bogus "Level 0" whose sole purpose is so that
  // level1.prev.needed==0.  This makes level1.nextPairFreq
  // be a legitimate value that never gets chosen.
  let levels = Array::makei(max_bits_limit, _ => LevelInfo::{
    level: 0,
    last_freq: 0,
    next_char_freq: 0,
    next_pair_freq: 0,
    needed: 0,
  })
  // leafCounts[i] counts the number of literals at the left
  // of ancestors of the rightmost node at level i.
  // leafCounts[i][j] is the number of literals at the left
  // of the level j ancestor.
  let leaf_counts = Array::make(max_bits_limit, Array::make(max_bits_limit, 0))
  for level = 1; level <= max_bits; level = level + 1 {
    // For every level, the first two items are the first two characters.
    // We initialize the levels as if we had already figured this out.
    levels[level] = LevelInfo::{
      level,
      last_freq: list[1].freq,
      next_char_freq: list[2].freq,
      next_pair_freq: list[0].freq + list[1].freq,
      needed: 0,
    }
    leaf_counts[level][level] = 2
    if level == 1 {
      levels[level].next_pair_freq = @int.max_value
    }
  }

  // We need a total of 2*n - 2 items at top level and have already generated 2.
  levels[max_bits].needed = 2 * n - 4
  let mut level = max_bits
  for {
    let l = levels[level]
    if l.next_pair_freq == 0x7FFFFFFF && l.next_char_freq == 0x7FFFFFFF {
      // We've run out of both leaves and pairs.
      // End all calculations for this level.
      // To make sure we never come back to this level or any lower level,
      // set nextPairFreq impossibly large.
      levels[level].needed = 0
      levels[level + 1].next_pair_freq = 0x7FFFFFFF
      level += 1
      continue
    }
    let prev_freq = l.last_freq
    if l.next_char_freq < l.next_pair_freq {
      // The next item on this row is a leaf node.
      let n = leaf_counts[level][level] + 1
      levels[level] = LevelInfo::{
        ..l,
        last_freq: l.next_char_freq,
        next_char_freq: list[n].freq,
      }
      // Lower leafCounts are the same of the previous node.
      leaf_counts[level][level] = n
    } else {
      // The next item on this row is a pair from the previous row.
      // nextPairFreq isn't valid until we generate two
      // more values in the level below
      levels[level] = LevelInfo::{ ..l, last_freq: l.next_pair_freq }
      // Take leaf counts from the lower level, except counts[level] remains the same.
      for i = 0; i < level; i = i + 1 {
        leaf_counts[level][i] = leaf_counts[level - 1][i]
      }
      levels[l.level - 1] = LevelInfo::{ ..levels[l.level - 1], needed: 2 }
    }
    let new_needed = l.needed - 1
    levels[level] = LevelInfo::{ ..levels[level], needed: new_needed }
    if new_needed == 0 {
      // We've done everything we need to do for this level.
      // Continue calculating one level up. Fill in nextPairFreq
      // of that level with the sum of the two nodes we've just calculated on
      // this level.
      if l.level == max_bits {
        // All done!
        break
      }
      levels[l.level + 1] = LevelInfo::{
        ..levels[l.level + 1],
        next_pair_freq: prev_freq + levels[level].last_freq,
      }
      level = level + 1
    } else {
      // If we stole from below, move down temporarily to replenish it.
      while levels[level - 1].needed > 0 {
        level = level - 1
      }
    }
  }

  // Somethings is wrong if at the end, the top level is null or hasn't used
  // all of the leaves.
  if leaf_counts[max_bits][max_bits] != n {
    abort("leafCounts[maxBits][maxBits] != n")
  }
  let bit_count = Array::make(max_bits + 1, 0)
  let mut bits = 1
  let counts = leaf_counts[max_bits]
  for level = max_bits; level > 0; level = level - 1 {
    // chain.leafCount gives the number of literals requiring at least "bits"
    // bits to encode.
    bit_count[bits] = counts[level] - counts[level - 1]
    bits = bits + 1
  }

  // Copy to h.bit_count
  for i = 0; i <= max_bits; i = i + 1 {
    h.bit_count[i] = bit_count[i]
  }
  bit_count
}

///|
/// Generate Huffman codes for the given frequency array
fn HuffmanEncoder::generate(
  self : HuffmanEncoder,
  freq : Array[Int],
  max_bits : Int,
) -> Unit {
  if self.freq_cache.length() == 0 {
    // Allocate a reusable buffer with the longest possible frequency table
    self.freq_cache.clear()
    for i = 0; i <= 286; i = i + 1 { // max_num_lit = 286
      self.freq_cache.push(LiteralNode::{ literal: 0, freq: 0 })
    }
  }

  // Create list of non-zero frequency nodes
  let list = Array::new()
  let mut count = 0

  // Set up list with all non-zero literals and their frequencies
  for i = 0; i < freq.length(); i = i + 1 {
    if freq[i] != 0 {
      list.push(LiteralNode::{ literal: i.reinterpret_as_uint(), freq: freq[i] })
      count = count + 1
    } else {
      self.codes[i] = HCode::{ code: 0, len: 0 }
    }
  }
  if count <= 2 {
    // Handle the small cases here, because they are awkward for the general case code.
    // With two or fewer literals, everything has bit length 1.
    for i = 0; i < list.length(); i = i + 1 {
      let node = list[i]
      let key = node.literal.reinterpret_as_int()
      self.codes[key] = HCode::new(i.reinterpret_as_uint(), 1)
    }
    return
  }

  // Sort by frequency
  quicksort(list, by_frequency)

  // Get the number of literals for each bit count
  let bit_count = self.bit_counts(list, max_bits)

  // Assign encoding and size
  self.assign_encoding_and_size(bit_count, list)
}

///|
/// Assign Huffman codes based on bit count distribution
fn HuffmanEncoder::assign_encoding_and_size(
  self : HuffmanEncoder,
  bit_count : Array[Int],
  list : Array[LiteralNode],
) -> Unit {
  // Generate codes based on the canonical Huffman algorithm
  let mut code = 0
  let code_by_length = Array::make(max_bits_limit + 1, 0)

  // Calculate starting code for each bit length
  for bits = 1; bits <= max_bits_limit; bits = bits + 1 {
    code = (code + bit_count[bits - 1]) << 1
    code_by_length[bits] = code
  }

  // Assign codes to symbols
  // First, determine bit length for each symbol based on frequency
  for i = 0; i < list.length(); i = i + 1 {
    let node = list[i]
    let symbol = node.literal.reinterpret_as_int()

    // Calculate bit length for this symbol (simplified)
    let mut length = 1
    let total_symbols = list.length()

    // Assign shorter codes to more frequent symbols
    if i < total_symbols / 4 {
      length = 2
    } else if i < total_symbols / 2 {
      length = 3
    } else if i < total_symbols * 3 / 4 {
      length = 4
    } else {
      length = 5
    }

    // Don't exceed max_bits
    if length > max_bits_limit {
      length = max_bits_limit
    }

    // Assign the code
    let code = code_by_length[length]
    code_by_length[length] = code_by_length[length] + 1
    self.codes[symbol] = HCode::{
      code: reverse_bits(code.reinterpret_as_uint(), length),
      len: length.reinterpret_as_uint(),
    }
  }
}
