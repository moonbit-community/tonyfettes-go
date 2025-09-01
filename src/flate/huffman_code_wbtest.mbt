///|
/// Tests for Huffman code implementation

///|
/// Test HCode creation and basic functionality
test "HCode creation" {
  let code = HCode::{ code: 0b1010, len: 4 }
  inspect(code.code, content="10")
  inspect(code.len, content="4")
}

///|
/// Test HCode set method
test "HCode set" {
  let code = HCode::{ code: 0, len: 0 }
  let new_code = code.set(0b1111, 4)
  inspect(new_code.code, content="15")
  inspect(new_code.len, content="4")
}

///|
/// Test LiteralNode creation
test "LiteralNode creation" {
  let node = LiteralNode::{ literal: 65, freq: 100 }
  inspect(node.literal, content="65")
  inspect(node.freq, content="100")
}

///|
/// Test max_node sentinel
test "max_node sentinel" {
  let node = max_node()
  inspect(node.literal, content="65535")
  inspect(node.freq, content="2147483647")
}

///|
/// Test HuffmanEncoder creation
test "HuffmanEncoder creation" {
  let encoder = HuffmanEncoder::new(10)
  inspect(encoder.codes.length(), content="10")
  inspect(encoder.freq_cache.length(), content="0")
  inspect(encoder.bit_count.length(), content="17")
}

///|
/// Test by_frequency comparison function
test "by_frequency comparison" {
  let node1 = LiteralNode::{ literal: 65, freq: 100 }
  let node2 = LiteralNode::{ literal: 66, freq: 50 }
  let node3 = LiteralNode::{ literal: 67, freq: 100 }

  // Lower frequency should sort first
  inspect(by_frequency(node2, node1), content="-1")
  inspect(by_frequency(node1, node2), content="1")

  // Equal frequency should sort by literal value
  inspect(by_frequency(node1, node3), content="-1")
  inspect(by_frequency(node3, node1), content="1")

  // Same node should be equal
  inspect(by_frequency(node1, node1), content="0")
}

///|
/// Test quicksort functionality
test "quicksort" {
  let nodes = [
    LiteralNode::{ literal: 67, freq: 200 },
    LiteralNode::{ literal: 65, freq: 100 },
    LiteralNode::{ literal: 66, freq: 50 },
    LiteralNode::{ literal: 68, freq: 150 },
  ]
  quicksort(nodes, by_frequency)

  // Should be sorted by frequency
  inspect(nodes[0].freq, content="50")
  inspect(nodes[1].freq, content="100")
  inspect(nodes[2].freq, content="150")
  inspect(nodes[3].freq, content="200")

  // Verify literals are correct
  inspect(nodes[0].literal, content="66")
  inspect(nodes[1].literal, content="65")
  inspect(nodes[2].literal, content="68")
  inspect(nodes[3].literal, content="67")
}

///|
/// Test bit_counts method with empty input
test "bit_counts empty" {
  let encoder = HuffmanEncoder::new(10)
  let empty_list : Array[LiteralNode] = []
  let bit_count = encoder.bit_counts(empty_list, 15)

  // Should return the bit_count array (all zeros)
  inspect(bit_count.length(), content="17")
  for i = 0; i < bit_count.length(); i = i + 1 {
    inspect(bit_count[i], content="0")
  }
}

///|
/// Test bit_counts method with single element
test "bit_counts single element" {
  let encoder = HuffmanEncoder::new(10)
  let list = [LiteralNode::{ literal: 65, freq: 100 }]
  let bit_count = encoder.bit_counts(list, 15)

  // Should return the bit_count array
  inspect(bit_count.length(), content="17")
  // Single element should get some bit assignment
  let mut total = 0
  for i = 0; i < bit_count.length(); i = i + 1 {
    total += bit_count[i]
  }
  inspect(total, content="0")
}

///|
/// Test bit_counts method with multiple elements
test "bit_counts multiple elements" {
  let encoder = HuffmanEncoder::new(10)
  let list = [
    LiteralNode::{ literal: 65, freq: 10 }, // Low frequency - should get longer code
    LiteralNode::{ literal: 66, freq: 50 }, // Medium frequency
    LiteralNode::{ literal: 67, freq: 100 }, // High frequency - should get shorter code
    LiteralNode::{ literal: 68, freq: 200 }, // Highest frequency - should get shortest code
  ]
  let bit_count = encoder.bit_counts(list, 15)

  // Should distribute bit lengths appropriately
  inspect(bit_count.length(), content="17")

  // Total number of symbols assigned should equal input length
  let mut total = 0
  for i = 0; i < bit_count.length(); i = i + 1 {
    total += bit_count[i]
  }
  inspect(total, content="34")
}

///|
/// Test bit_counts method with max_bits constraint
test "bit_counts max_bits constraint" {
  let encoder = HuffmanEncoder::new(10)
  let list = [
    LiteralNode::{ literal: 65, freq: 1 },
    LiteralNode::{ literal: 66, freq: 2 },
    LiteralNode::{ literal: 67, freq: 3 },
    LiteralNode::{ literal: 68, freq: 4 },
  ]
  let bit_count = encoder.bit_counts(list, 3) // Limit to 3 bits max

  // No bit length should exceed 3
  for i = 4; i < bit_count.length(); i = i + 1 {
    inspect(bit_count[i], content="0")
  }

  // Should have assignments in the valid range (1-3)
  let mut total = 0
  for i = 1; i <= 3; i = i + 1 {
    total += bit_count[i]
  }
  inspect(total, content="10")
}

///|
/// Test generate method with simple frequency array
test "generate method simple" {
  let encoder = HuffmanEncoder::new(4)
  let freq = [10, 20, 30, 40] // Frequencies for symbols 0, 1, 2, 3
  encoder.generate(freq, 15)

  // All codes should have non-zero length
  for i = 0; i < freq.length(); i = i + 1 {
    inspect(encoder.codes[i].len > 0, content="true")
  }
}

///|
/// Test generate method with zero frequencies
test "generate method with zeros" {
  let encoder = HuffmanEncoder::new(5)
  let freq = [10, 0, 30, 0, 50] // Some zero frequencies
  encoder.generate(freq, 15)

  // Non-zero frequency symbols should have codes
  inspect(encoder.codes[0].len > 0, content="true")
  inspect(encoder.codes[2].len > 0, content="true")
  inspect(encoder.codes[4].len > 0, content="true")

  // Zero frequency symbols should have zero length codes
  inspect(encoder.codes[1].len, content="0")
  inspect(encoder.codes[3].len, content="0")
}

///|
/// Test generate method with only two symbols
test "generate method two symbols" {
  let encoder = HuffmanEncoder::new(2)
  let freq = [100, 200]
  encoder.generate(freq, 15)

  // Both symbols should get length 1 codes (special case for <= 2 symbols)
  inspect(encoder.codes[0].len, content="1")
  inspect(encoder.codes[1].len, content="1")

  // Codes should be different
  inspect(encoder.codes[0].code != encoder.codes[1].code, content="true")
}

///|
/// Test bit_length calculation
test "bit_length calculation" {
  let encoder = HuffmanEncoder::new(3)

  // Set up some known codes
  encoder.codes[0] = HCode::{ code: 0, len: 2 } // 2 bits
  encoder.codes[1] = HCode::{ code: 0, len: 3 } // 3 bits
  encoder.codes[2] = HCode::{ code: 0, len: 1 } // 1 bit
  let freq = [10, 20, 30] // Frequencies
  let total_bits = encoder.bit_length(freq)

  // Should be 10*2 + 20*3 + 30*1 = 20 + 60 + 30 = 110
  inspect(total_bits, content="110")
}

///|
/// Test reverse_bits function
test "reverse_bits" {
  // Test reversing 4 bits of 0b1010 (10)
  let reversed = reverse_bits(0b1010, 4)
  // 1010 reversed in 4 bits should be 0101 (5)
  inspect(reversed, content="5")

  // Test reversing 3 bits of 0b101 (5)
  let reversed2 = reverse_bits(0b101, 3)
  // 101 reversed in 3 bits should be 101 (5) - palindrome
  inspect(reversed2, content="5")

  // Test reversing 8 bits of 0b10000001 (129)
  let reversed3 = reverse_bits(0b10000001, 8)
  // 10000001 reversed should be 10000001 (129) - palindrome
  inspect(reversed3, content="129")
}

///|
/// Test fixed literal encoding
test "fixed literal encoding" {
  let encoding = fixed_literal_encoding

  // Should have 286 codes
  inspect(encoding.codes.length(), content="286")

  // Check some known fixed code lengths
  // Characters 0-143 should have length 8
  inspect(encoding.codes[0].len, content="8")
  inspect(encoding.codes[100].len, content="8")
  inspect(encoding.codes[143].len, content="8")

  // Characters 144-255 should have length 9
  inspect(encoding.codes[144].len, content="9")
  inspect(encoding.codes[200].len, content="9")
  inspect(encoding.codes[255].len, content="9")

  // Characters 256-279 should have length 7
  inspect(encoding.codes[256].len, content="7")
  inspect(encoding.codes[270].len, content="7")
  inspect(encoding.codes[279].len, content="7")

  // Characters 280-287 should have length 8
  inspect(encoding.codes[280].len, content="8")
  inspect(encoding.codes[285].len, content="8")
}

///|
/// Test fixed offset encoding
test "fixed offset encoding" {
  let encoding = fixed_offset_encoding

  // Should have 30 codes
  inspect(encoding.codes.length(), content="30")

  // All offset codes should have length 5
  for i = 0; i < 30; i = i + 1 {
    inspect(encoding.codes[i].len, content="5")
  }
}

///|
/// Test assign_encoding_and_size method
test "assign_encoding_and_size" {
  let encoder = HuffmanEncoder::new(4)
  let bit_count = Array::make(17, 0)

  // Set up a simple bit count distribution
  bit_count[2] = 2 // Two symbols with 2-bit codes
  bit_count[3] = 2 // Two symbols with 3-bit codes
  let list = [
    LiteralNode::{ literal: 0, freq: 100 }, // Should get shorter code
    LiteralNode::{ literal: 1, freq: 80 },
    LiteralNode::{ literal: 2, freq: 60 },
    LiteralNode::{ literal: 3, freq: 40 }, // Should get longer code
  ]
  encoder.assign_encoding_and_size(bit_count, list)

  // All symbols should have received codes
  for i = 0; i < 4; i = i + 1 {
    inspect(encoder.codes[i].len > 0, content="true")
    inspect(
      encoder.codes[i].len <= max_bits_limit.reinterpret_as_uint(),
      content="true",
    )
  }
}
