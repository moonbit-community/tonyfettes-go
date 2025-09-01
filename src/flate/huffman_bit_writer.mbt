///|
/// Constants for Huffman bit writing
const OffsetCodeCount = 30

///|
const LengthCodesStart = 257

///|
const CodegenCodeCount = 19

///|
const BadCode = 255

///|
/// Buffer sizes for efficient writing
const BufferFlushSize = 240

///|
const BufferSize : Int = BufferFlushSize + 8

///|
/// The number of extra bits needed by length code X - LENGTH_CODES_START
let length_extra_bits : FixedArray[Int] = [
  0, 0, 0, // 257-259
   0, 0, 0, 0, 0, 1, 1, 1, 1, 2, // 260-272
   2, 2, 2, 3, 3, 3, 3, 4, 4, 4, // 273-282
   4, 5, 5, 5, 5, 0, // 283-288
]

///|
/// The length indicated by length code X - LENGTH_CODES_START
let length_base : FixedArray[UInt] = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80,
  96, 112, 128, 160, 192, 224, 255,
]

///|
/// Offset code word extra bits
let offset_extra_bits : FixedArray[Int] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]

///|
let offset_base : FixedArray[UInt] = [
  0x000000, 0x000001, 0x000002, 0x000003, 0x000004, 0x000006, 0x000008, 0x00000c,
  0x000010, 0x000018, 0x000020, 0x000030, 0x000040, 0x000060, 0x000080, 0x0000c0,
  0x000100, 0x000180, 0x000200, 0x000300, 0x000400, 0x000600, 0x000800, 0x000c00,
  0x001000, 0x001800, 0x002000, 0x003000, 0x004000, 0x006000,
]

///|
/// The odd order in which the codegen code sizes are written
let codegen_order : FixedArray[UInt] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
/// HuffmanBitWriter writes DEFLATE Huffman encoded data
priv struct HuffmanBitWriter {
  mut writer : &@io.Writer
  mut bits : UInt64 // Data waiting to be written
  mut nbits : UInt // Number of bits in bits field
  bytes : @bytes.View
  codegen_freq : Array[Int]
  mut nbytes : Int // Number of bytes in buffer
  literal_freq : Array[Int]
  offset_freq : Array[Int]
  codegen : Array[Byte]
  literal_encoding : HuffmanEncoder
  offset_encoding : HuffmanEncoder
  codegen_encoding : HuffmanEncoder
  mut err : Error?
} derive(Show)

///|
/// Create a new HuffmanBitWriter
fn HuffmanBitWriter::new(w : &@io.Writer) -> HuffmanBitWriter {
  HuffmanBitWriter::{
    writer: w,
    bits: 0,
    nbits: 0,
    bytes: Bytes::make(BufferSize, 0),
    codegen_freq: Array::make(CodegenCodeCount, 0),
    nbytes: 0,
    literal_freq: Array::make(286, 0),
    offset_freq: Array::make(OffsetCodeCount, 0),
    codegen: Array::make(286 + OffsetCodeCount + 1, 0),
    literal_encoding: HuffmanEncoder::new(286),
    offset_encoding: HuffmanEncoder::new(OffsetCodeCount),
    codegen_encoding: HuffmanEncoder::new(CodegenCodeCount),
    err: None,
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
  self.err = None
}

///|
/// Flush any pending bits and bytes to the output
fn HuffmanBitWriter::flush(w : HuffmanBitWriter) -> Unit raise {
  if w.err is Some(err) {
    w.nbits = 0
    raise err
  }
  let mut n = w.nbytes
  while w.nbits != 0 {
    w.bytes[n] = (w.bits & 0xFF).to_int().to_byte()
    w.bits = w.bits >> 8
    if w.nbits > 8 {
      w.nbits = w.nbits - 8
    } else {
      w.nbits = 0
    }
    n = n + 1
  }
  w.bits = 0
  w.write(w.bytes[:n])
  w.nbytes = 0
}

///|
fn Bytes::op_set(self : Bytes, index : Int, value : Byte) -> Unit = "%fixedarray.set"

///|
fn @bytes.View::op_set(self : @bytes.View, index : Int, value : Byte) -> Unit {
  self.data()[self.start_offset() + index] = value
}

///|
fn HuffmanBitWriter::write(w : HuffmanBitWriter, b : @bytes.View) -> Unit raise {
  if w.err is Some(err) {
    raise err
  }
  ignore(w.writer.write(b))
}

///|
/// Write raw bytes to output
fn HuffmanBitWriter::write_bytes(
  w : HuffmanBitWriter,
  bytes : @bytes.View,
) -> Unit raise {
  if w.err is Some(err) {
    raise err
  }
  let mut n = w.nbytes
  if (w.nbits & 7) != 0 {
    w.err = Some(InternalError("writeBytes with unfinished bits"))
    return
  }
  while w.nbits != 0 {
    w.bytes[n] = (w.bits & 0xFF).to_int().to_byte()
    w.bits = w.bits >> 8
    w.nbits = w.nbits - 8
    n = n + 1
  }
  if n != 0 {
    w.write(w.bytes[:n])
  }
  w.nbytes = 0
  w.write(bytes)
}

///|
/// Write bits to the output stream
fn HuffmanBitWriter::write_bits(
  w : HuffmanBitWriter,
  b : Int,
  nb : UInt,
) -> Unit raise {
  if w.err is Some(err) {
    raise err
  }
  w.bits = w.bits | (b.to_uint64() << w.nbits.reinterpret_as_int())
  w.nbits = w.nbits + nb
  if w.nbits >= 48 {
    let bits = w.bits
    w.bits = w.bits >> 48
    w.nbits = w.nbits - 48
    let mut n = w.nbytes

    // Write 6 bytes
    w.bytes[n] = (bits & 0xFF).to_int().to_byte()
    w.bytes[n + 1] = ((bits >> 8) & 0xFF).to_int().to_byte()
    w.bytes[n + 2] = ((bits >> 16) & 0xFF).to_int().to_byte()
    w.bytes[n + 3] = ((bits >> 24) & 0xFF).to_int().to_byte()
    w.bytes[n + 4] = ((bits >> 32) & 0xFF).to_int().to_byte()
    w.bytes[n + 5] = ((bits >> 40) & 0xFF).to_int().to_byte()
    n = n + 6
    if n >= BufferFlushSize {
      w.write(w.bytes[:n])
      n = 0
    }
    w.nbytes = n
  }
}

///|
/// Write a Huffman code to the output
fn HuffmanBitWriter::write_code(w : HuffmanBitWriter, c : HCode) -> Unit raise {
  if w.err is Some(err) {
    raise err
  }
  w.bits = w.bits | (c.code.to_uint64() << w.nbits.reinterpret_as_int())
  w.nbits = w.nbits + c.len
  if w.nbits >= 48 {
    let bits = w.bits
    w.bits = w.bits >> 48
    w.nbits = w.nbits - 48
    let mut n = w.nbytes
    w.bytes[n] = bits.to_byte()
    w.bytes[n + 1] = (bits >> 8).to_byte()
    w.bytes[n + 2] = (bits >> 16).to_byte()
    w.bytes[n + 3] = (bits >> 24).to_byte()
    w.bytes[n + 4] = (bits >> 32).to_byte()
    w.bytes[n + 5] = (bits >> 40).to_byte()
    n += 6
    if n >= BufferFlushSize {
      w.write(w.bytes[:n])
      n = 0
    }
    w.nbytes = n
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
  self.codegen[num_literals + num_offsets] = BadCode.to_byte()
  let mut size = self.codegen[0].to_int()
  let mut count = 1
  let mut out_index = 0
  let mut in_index = 1
  while size != BadCode {
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
  self.codegen[out_index] = BadCode.to_byte()
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
) -> Unit raise {
  if self.err is Some(err) {
    raise err
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
) -> Unit raise {
  if self.err is Some(err) {
    raise err
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
) -> Unit raise {
  if self.err is Some(err) {
    raise err
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
    if code_word == BadCode {
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
      self.literal_freq[LengthCodesStart +
      length_code(length).reinterpret_as_int()] = self.literal_freq[LengthCodesStart +
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
) -> Unit raise {
  if self.err is Some(err) {
    raise err
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
        le_codes[length_code_val.reinterpret_as_int() + LengthCodesStart],
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
  input : @bytes.View,
) -> Unit raise {
  if self.err is Some(err) {
    raise err
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

///|
/// Write block using dynamic Huffman encoding
/// writeBlockDynamic encodes and writes the given tokens as dynamic
/// Huffman encoded data. If input is supplied and the compression savings
/// are below 1/16th of the input size the block is stored.
fn HuffmanBitWriter::write_block_dynamic(
  self : HuffmanBitWriter,
  tokens : Array[Token],
  eof : Bool,
  input : @bytes.View,
) -> Unit raise {
  if self.err is Some(_) {
    return
  }

  // For now, we'll fall back to Huffman-only encoding
  // TODO: Implement proper dynamic Huffman encoding
  self.write_block_huff(eof, input)
}
