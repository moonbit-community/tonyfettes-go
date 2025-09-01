///|
/// Constants for Huffman bit writing
let offset_code_count = 30

///|
let length_codes_start = 257

///|
let codegen_code_count = 19

///|
let bad_code = 255

///|
/// Buffer sizes for efficient writing
let buffer_flush_size = 240

///|
let buffer_size : Int = buffer_flush_size + 8

///|
/// The number of extra bits needed by length code X - LENGTH_CODES_START
let length_extra_bits : Array[Int] = [
  0, 0, 0, // 257-259
   0, 0, 0, 0, 0, 1, 1, 1, 1, 2, // 260-272
   2, 2, 2, 3, 3, 3, 3, 4, 4, 4, // 273-282
   4, 5, 5, 5, 5, 0, // 283-288
]

///|
/// The length indicated by length code X - LENGTH_CODES_START
let length_base : Array[UInt] = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80,
  96, 112, 128, 160, 192, 224, 255,
]

///|
/// Offset code word extra bits
let offset_extra_bits : Array[Int] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]

///|
let offset_base : Array[UInt] = [
  0x000000, 0x000001, 0x000002, 0x000003, 0x000004, 0x000006, 0x000008, 0x00000c,
  0x000010, 0x000018, 0x000020, 0x000030, 0x000040, 0x000060, 0x000080, 0x0000c0,
  0x000100, 0x000180, 0x000200, 0x000300, 0x000400, 0x000600, 0x000800, 0x000c00,
  0x001000, 0x001800, 0x002000, 0x003000, 0x004000, 0x006000,
]

///|
/// The odd order in which the codegen code sizes are written
let codegen_order : Array[UInt] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
/// HuffmanBitWriter writes DEFLATE Huffman encoded data
priv struct HuffmanBitWriter {
  mut writer : &@io.Writer
  mut bits : UInt64 // Data waiting to be written
  mut nbits : UInt // Number of bits in bits field
  bytes : Array[Byte] // Output buffer
  codegen_freq : Array[Int]
  mut nbytes : Int // Number of bytes in buffer
  literal_freq : Array[Int]
  offset_freq : Array[Int]
  codegen : Array[Byte]
  literal_encoding : HuffmanEncoder
  offset_encoding : HuffmanEncoder
  codegen_encoding : HuffmanEncoder
  mut err : Bool // Error state
} derive(Show)

///|
/// Create a new HuffmanBitWriter
fn HuffmanBitWriter::new(w : &@io.Writer) -> HuffmanBitWriter {
  HuffmanBitWriter::{
    writer: w,
    bits: 0,
    nbits: 0,
    bytes: Array::make(buffer_size, 0),
    codegen_freq: Array::make(codegen_code_count, 0),
    nbytes: 0,
    literal_freq: Array::make(286, 0),
    offset_freq: Array::make(offset_code_count, 0),
    codegen: Array::make(286 + offset_code_count + 1, 0),
    literal_encoding: HuffmanEncoder::new(286),
    offset_encoding: HuffmanEncoder::new(offset_code_count),
    codegen_encoding: HuffmanEncoder::new(codegen_code_count),
    err: false,
  }
}

///|
/// Reset the writer with a new output writer
fn HuffmanBitWriter::reset(
  self : HuffmanBitWriter,
  writer : &@io.Writer,
) -> Unit {
  self.writer = writer
  self.bits = 0
  self.nbits = 0
  self.nbytes = 0
  self.err = false
}

///|
/// Flush any pending bits and bytes to the output
fn HuffmanBitWriter::flush(self : HuffmanBitWriter) -> Unit {
  if self.err {
    self.nbits = 0
    return
  }
  let mut n = self.nbytes
  while self.nbits != 0 {
    self.bytes[n] = (self.bits & 0xFF).to_int().to_byte()
    self.bits = self.bits >> 8
    if self.nbits > 8 {
      self.nbits = self.nbits - 8
    } else {
      self.nbits = 0
    }
    n = n + 1
  }
  self.bits = 0
  self.write_bytes_internal(n)
  self.nbytes = 0
}

///|
/// Write bytes to the underlying writer
fn HuffmanBitWriter::write_bytes_internal(
  self : HuffmanBitWriter,
  count : Int,
) -> Unit {
  if self.err {
    return
  }
  // For now, we'll need to implement this once we have proper bytes.View support
  // This is a placeholder that sets error state if called
  self.err = true
}

///|
/// Write raw bytes to output
fn HuffmanBitWriter::write_bytes(
  self : HuffmanBitWriter,
  bytes : Array[Byte],
) -> Unit {
  if self.err {
    return
  }
  let mut n = self.nbytes
  if (self.nbits & 7) != 0 {
    self.err = true // writeBytes with unfinished bits
    return
  }
  while self.nbits != 0 {
    self.bytes[n] = (self.bits & 0xFF).to_int().to_byte()
    self.bits = self.bits >> 8
    self.nbits = self.nbits - 8
    n = n + 1
  }
  if n != 0 {
    self.write_bytes_internal(n)
  }
  self.nbytes = 0
  // Write the input bytes directly - placeholder for now
  // TODO: Implement proper byte array writing
  self.err = true
}

///|
/// Write bits to the output stream
fn HuffmanBitWriter::write_bits(
  self : HuffmanBitWriter,
  b : Int,
  nb : UInt,
) -> Unit {
  if self.err {
    return
  }
  self.bits = self.bits | (b.to_uint64() << self.nbits.reinterpret_as_int())
  self.nbits = self.nbits + nb
  if self.nbits >= 48 {
    let bits = self.bits
    self.bits = self.bits >> 48
    self.nbits = self.nbits - 48
    let mut n = self.nbytes

    // Write 6 bytes
    self.bytes[n] = (bits & 0xFF).to_int().to_byte()
    self.bytes[n + 1] = ((bits >> 8) & 0xFF).to_int().to_byte()
    self.bytes[n + 2] = ((bits >> 16) & 0xFF).to_int().to_byte()
    self.bytes[n + 3] = ((bits >> 24) & 0xFF).to_int().to_byte()
    self.bytes[n + 4] = ((bits >> 32) & 0xFF).to_int().to_byte()
    self.bytes[n + 5] = ((bits >> 40) & 0xFF).to_int().to_byte()
    n = n + 6
    if n >= buffer_flush_size {
      self.write_bytes_internal(n)
      n = 0
    }
    self.nbytes = n
  }
}

///|
/// Write a Huffman code to the output
fn HuffmanBitWriter::write_code(self : HuffmanBitWriter, c : HCode) -> Unit {
  if self.err {
    return
  }
  self.bits = self.bits |
    (c.code.to_uint64() << self.nbits.reinterpret_as_int())
  self.nbits = self.nbits + c.len
  if self.nbits >= 48 {
    let bits = self.bits
    self.bits = self.bits >> 48
    self.nbits = self.nbits - 48
    let mut n = self.nbytes

    // Write 6 bytes
    self.bytes[n] = (bits & 0xFF).to_int().to_byte()
    self.bytes[n + 1] = ((bits >> 8) & 0xFF).to_int().to_byte()
    self.bytes[n + 2] = ((bits >> 16) & 0xFF).to_int().to_byte()
    self.bytes[n + 3] = ((bits >> 24) & 0xFF).to_int().to_byte()
    self.bytes[n + 4] = ((bits >> 32) & 0xFF).to_int().to_byte()
    self.bytes[n + 5] = ((bits >> 40) & 0xFF).to_int().to_byte()
    n = n + 6
    if n >= buffer_flush_size {
      self.write_bytes_internal(n)
      n = 0
    }
    self.nbytes = n
  }
}

///|
/// Generate codegen for encoding literal and offset lengths
fn HuffmanBitWriter::generate_codegen(
  self : HuffmanBitWriter,
  num_literals : Int,
  num_offsets : Int,
  lit_enc : HuffmanEncoder,
  off_enc : HuffmanEncoder,
) -> Unit {
  // Clear frequency array
  for i = 0; i < self.codegen_freq.length(); i = i + 1 {
    self.codegen_freq[i] = 0
  }

  // Copy literal code lengths
  for i = 0; i < num_literals; i = i + 1 {
    self.codegen[i] = lit_enc.codes[i].len.reinterpret_as_int().to_byte()
  }

  // Copy offset code lengths
  for i = 0; i < num_offsets; i = i + 1 {
    self.codegen[num_literals + i] = off_enc.codes[i].len
      .reinterpret_as_int()
      .to_byte()
  }
  self.codegen[num_literals + num_offsets] = bad_code.to_byte()
  let mut size = self.codegen[0].to_int()
  let mut count = 1
  let mut out_index = 0
  let mut in_index = 1
  while size != bad_code {
    let next_size = self.codegen[in_index].to_int()
    if next_size == size {
      count = count + 1
      in_index = in_index + 1
      continue
    }
    if size != 0 {
      self.codegen[out_index] = size.to_byte()
      out_index = out_index + 1
      self.codegen_freq[size] = self.codegen_freq[size] + 1
      count = count - 1
      while count >= 3 {
        let n = if 6 > count { count } else { 6 }
        self.codegen[out_index] = 16
        out_index = out_index + 1
        self.codegen[out_index] = (n - 3).to_byte()
        out_index = out_index + 1
        self.codegen_freq[16] = self.codegen_freq[16] + 1
        count = count - n
      }
    } else {
      while count >= 11 {
        let n = if 138 > count { count } else { 138 }
        self.codegen[out_index] = 18
        out_index = out_index + 1
        self.codegen[out_index] = (n - 11).to_byte()
        out_index = out_index + 1
        self.codegen_freq[18] = self.codegen_freq[18] + 1
        count = count - n
      }
      if count >= 3 {
        self.codegen[out_index] = 17
        out_index = out_index + 1
        self.codegen[out_index] = (count - 3).to_byte()
        out_index = out_index + 1
        self.codegen_freq[17] = self.codegen_freq[17] + 1
        count = 0
      }
    }
    count = count - 1
    while count >= 0 {
      self.codegen[out_index] = size.to_byte()
      out_index = out_index + 1
      self.codegen_freq[size] = self.codegen_freq[size] + 1
      count = count - 1
    }
    size = next_size
    count = 1
    in_index = in_index + 1
  }
  self.codegen[out_index] = bad_code.to_byte()
}

///|
/// Calculate the size of dynamic encoding
fn HuffmanBitWriter::dynamic_size(
  self : HuffmanBitWriter,
  lit_enc : HuffmanEncoder,
  off_enc : HuffmanEncoder,
  extra_bits : Int,
) -> (Int, Int) {
  let mut num_codegens = self.codegen_freq.length()
  while num_codegens > 4 &&
        self.codegen_freq[codegen_order[num_codegens - 1].reinterpret_as_int()] ==
        0 {
    num_codegens = num_codegens - 1
  }
  let header = 3 +
    5 +
    5 +
    4 +
    3 * num_codegens +
    self.codegen_encoding.bit_length(self.codegen_freq) +
    self.codegen_freq[16] * 2 +
    self.codegen_freq[17] * 3 +
    self.codegen_freq[18] * 7
  let size = header +
    lit_enc.bit_length(self.literal_freq) +
    off_enc.bit_length(self.offset_freq) +
    extra_bits
  (size, num_codegens)
}

///|
/// Calculate the size of fixed encoding
fn HuffmanBitWriter::fixed_size(
  self : HuffmanBitWriter,
  extra_bits : Int,
) -> Int {
  3 +
  fixed_literal_encoding.bit_length(self.literal_freq) +
  fixed_offset_encoding.bit_length(self.offset_freq) +
  extra_bits
}

///|
/// Calculate stored size including header
fn HuffmanBitWriter::stored_size(
  self : HuffmanBitWriter,
  input : Array[Byte],
) -> (Int, Bool) {
  if input.length() <= 65535 { // maxStoreBlockSize
    ((input.length() + 5) * 8, true)
  } else {
    (0, false)
  }
}

///|
/// Write stored block header
fn HuffmanBitWriter::write_stored_header(
  self : HuffmanBitWriter,
  length : Int,
  is_eof : Bool,
) -> Unit {
  if self.err {
    return
  }
  let flag = if is_eof { 1 } else { 0 }
  self.write_bits(flag, 3)
  self.flush()
  self.write_bits(length, 16)
  self.write_bits(length.lnot() & 0xFFFF, 16) // ~uint16(length)
}

///|
/// Write fixed Huffman header
fn HuffmanBitWriter::write_fixed_header(
  self : HuffmanBitWriter,
  is_eof : Bool,
) -> Unit {
  if self.err {
    return
  }
  let value = if is_eof { 3 } else { 2 }
  self.write_bits(value, 3)
}

///|
/// Write dynamic Huffman header
fn HuffmanBitWriter::write_dynamic_header(
  self : HuffmanBitWriter,
  num_literals : Int,
  num_offsets : Int,
  num_codegens : Int,
  is_eof : Bool,
) -> Unit {
  if self.err {
    return
  }
  let first_bits = if is_eof { 5 } else { 4 }
  self.write_bits(first_bits, 3)
  self.write_bits(num_literals - 257, 5)
  self.write_bits(num_offsets - 1, 5)
  self.write_bits(num_codegens - 4, 4)
  for i = 0; i < num_codegens; i = i + 1 {
    let value = self.codegen_encoding.codes[codegen_order[i].reinterpret_as_int()].len
    self.write_bits(value.reinterpret_as_int(), 3)
  }
  let mut i = 0
  while true {
    let code_word = self.codegen[i].to_int()
    i = i + 1
    if code_word == bad_code {
      break
    }
    self.write_code(self.codegen_encoding.codes[code_word])
    match code_word {
      16 => {
        self.write_bits(self.codegen[i].to_int(), 2)
        i = i + 1
      }
      17 => {
        self.write_bits(self.codegen[i].to_int(), 3)
        i = i + 1
      }
      18 => {
        self.write_bits(self.codegen[i].to_int(), 7)
        i = i + 1
      }
      _ => ()
    }
  }
}

///|
/// Index tokens and update frequency tables
fn HuffmanBitWriter::index_tokens(
  self : HuffmanBitWriter,
  tokens : Array[Token],
) -> (Int, Int) {
  // Clear frequency arrays
  for i = 0; i < self.literal_freq.length(); i = i + 1 {
    self.literal_freq[i] = 0
  }
  for i = 0; i < self.offset_freq.length(); i = i + 1 {
    self.offset_freq[i] = 0
  }
  for i = 0; i < tokens.length(); i = i + 1 {
    let t = tokens[i]
    if (t.value & TypeMask) < MatchType {
      self.literal_freq[t.literal().reinterpret_as_int()] = self.literal_freq[t
        .literal()
        .reinterpret_as_int()] +
        1
    } else {
      let length = t.length()
      let offset = t.offset()
      self.literal_freq[length_codes_start +
      length_code(length).reinterpret_as_int()] = self.literal_freq[length_codes_start +
        length_code(length).reinterpret_as_int()] +
        1
      self.offset_freq[offset_code(offset).reinterpret_as_int()] = self.offset_freq[offset_code(
          offset,
        ).reinterpret_as_int()] +
        1
    }
  }

  // Get the number of literals
  let mut num_literals = self.literal_freq.length()
  while self.literal_freq[num_literals - 1] == 0 {
    num_literals = num_literals - 1
  }

  // Get the number of offsets
  let mut num_offsets = self.offset_freq.length()
  while num_offsets > 0 && self.offset_freq[num_offsets - 1] == 0 {
    num_offsets = num_offsets - 1
  }
  if num_offsets == 0 {
    // We haven't found a single match. Count at least one offset.
    self.offset_freq[0] = 1
    num_offsets = 1
  }

  // Generate encodings
  // Note: These methods need to be implemented in HuffmanEncoder
  // self.literal_encoding.generate(self.literal_freq, 15)
  // self.offset_encoding.generate(self.offset_freq, 15)

  (num_literals, num_offsets)
}

///|
/// Write tokens using provided literal and offset codes
fn HuffmanBitWriter::write_tokens(
  self : HuffmanBitWriter,
  tokens : Array[Token],
  le_codes : Array[HCode],
  oe_codes : Array[HCode],
) -> Unit {
  if self.err {
    return
  }
  for i = 0; i < tokens.length(); i = i + 1 {
    let t = tokens[i]
    if (t.value & TypeMask) < MatchType {
      self.write_code(le_codes[t.literal().reinterpret_as_int()])
    } else {
      // Write the length
      let length = t.length()
      let length_code_val = length_code(length)
      self.write_code(
        le_codes[length_code_val.reinterpret_as_int() + length_codes_start],
      )
      let extra_length_bits = length_extra_bits[length_code_val.reinterpret_as_int()].reinterpret_as_uint()
      if extra_length_bits > 0 {
        let extra_length = (length -
        length_base[length_code_val.reinterpret_as_int()]).reinterpret_as_int()
        self.write_bits(extra_length, extra_length_bits)
      }

      // Write the offset
      let offset = t.offset()
      let offset_code_val = offset_code(offset)
      self.write_code(oe_codes[offset_code_val.reinterpret_as_int()])
      let extra_offset_bits = offset_extra_bits[offset_code_val.reinterpret_as_int()].reinterpret_as_uint()
      if extra_offset_bits > 0 {
        let extra_offset = (offset -
        offset_base[offset_code_val.reinterpret_as_int()]).reinterpret_as_int()
        self.write_bits(extra_offset, extra_offset_bits)
      }
    }
  }
}

///|
/// Write block using Huffman encoding only
/// writeBlockHuff encodes and writes the given bytes as either
/// Huffman encoded literals or uncompressed bytes if the
/// results only gains very little from compression.
fn HuffmanBitWriter::write_block_huff(
  self : HuffmanBitWriter,
  eof : Bool,
  input : Array[Byte],
) -> Unit {
  if self.err {
    return
  }

  // Clear the literal frequency
  for i = 0; i < self.literal_freq.length(); i = i + 1 {
    self.literal_freq[i] = 0
  }

  // Add the EOF marker
  self.literal_freq[256] = 1

  // Accumulate literal frequencies
  for i = 0; i < input.length(); i = i + 1 {
    self.literal_freq[input[i].to_int()] = self.literal_freq[input[i].to_int()] +
      1
  }

  // Get Huffman token count
  let mut num_literals = self.literal_freq.length()
  while self.literal_freq[num_literals - 1] == 0 {
    num_literals = num_literals - 1
  }

  // Generate the huffman encoding
  // Note: This would require implementing huffman encoder generation
  // For now, we'll use fixed encoding
  self.write_fixed_header(eof)

  // Write tokens using fixed encoding
  for i = 0; i < input.length(); i = i + 1 {
    self.write_code(fixed_literal_encoding.codes[input[i].to_int()])
  }

  // Write the EOF marker
  self.write_code(fixed_literal_encoding.codes[256])
}
