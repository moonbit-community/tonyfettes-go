# MoonBit Flate Package

This package provides a MoonBit implementation of the DEFLATE compression algorithm, migrated from Go's `compress/flate` package.

## Features

- **DeflateFast**: High-speed compression implementation based on Snappy's LZ77-style encoder
- **Multiple compression levels**: NoCompression, BestSpeed, BestCompression, DefaultCompression, HuffmanOnly
- **Streaming interface**: Compatible with MoonBit's io.Writer trait
- **Cross-block matching**: Efficient matching across block boundaries for better compression

## Core Components

### DeflateFast Algorithm

The `DeflateFast` implementation in `deflatefast.mbt` provides the fastest compression mode (BestSpeed level 1). Key features:

- **Hash table-based matching**: Uses a 16KB hash table for fast lookups  
- **Heuristic match skipping**: Dynamically adjusts search strategy based on input compressibility
- **Cross-block references**: Maintains previous block data for better compression ratios
- **Snappy-compatible**: Based on the same algorithm used in Google's Snappy compressor

### Performance Characteristics

- **Speed-optimized**: Prioritizes compression speed over compression ratio
- **Memory efficient**: Uses fixed-size data structures to minimize allocation overhead
- **Adaptive**: Automatically adjusts behavior for compressible vs incompressible data

## Usage Example

```moonbit
// Create a writer with BestSpeed compression
let output_buffer = Array::new()
let writer : @io.Writer = {
  write: fn(bytes) {
    for i = 0; i < bytes.length(); i = i + 1 {
      output_buffer.push(bytes[i])
    }
    bytes.length()
  }
}

let flate_writer = new_writer(writer, BestSpeed)

// Compress data
let data = "Hello, World! This is test data for compression."
let bytes = Bytes::new()
for i = 0; i < data.length(); i = i + 1 {
  bytes.push(data[i])
}

flate_writer.write(bytes)
flate_writer.close()
```

## Algorithm Details

### Hash Function

- Uses multiplication-based hashing with constant `0x1e35a7bd`
- 14-bit hash table (16384 entries) for fast lookups
- Collision handling via linked chain in hash table

### Match Finding

- Minimum match length: 4 bytes
- Maximum match length: 258 bytes  
- Maximum match distance: 32768 bytes
- Uses 32-bit and 64-bit loads for efficient byte comparison

### Block Processing

- Processes input in blocks up to 65535 bytes
- Maintains previous block data for cross-block matching
- Automatic buffer shifting to prevent integer overflow

## Testing

The implementation includes comprehensive whitebox tests covering:

- Basic encoder functionality
- Edge cases (empty input, small input, large input)
- Hash function correctness
- Match length calculation
- Cross-block matching
- Buffer management and overflow protection

Run tests with:

```bash
moon test
```

## Compatibility

This implementation maintains line-by-line correspondence with Go's original `deflatefast.go`, ensuring:

- Identical compression behavior
- Same performance characteristics  
- Compatible compressed output format
- Equivalent memory usage patterns

## Files

- `deflatefast.mbt`: Core DeflateFast implementation
- `deflate.mbt`: Main DEFLATE wrapper and Writer interface
- `token.mbt`: Token encoding for literals and matches
- `huffman_bit_writer.mbt`: Huffman encoding output
- `huffman_code.mbt`: Huffman code generation
- `deflatefast_wbtest.mbt`: Comprehensive test suite
