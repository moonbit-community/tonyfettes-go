# ZLIB Package for MoonBit

This package implements RFC 1950 (ZLIB compression format) for MoonBit, providing readers and writers for zlib-compressed data.

## Features

- ✅ **ZLIB Header Parsing**: Complete RFC 1950 header validation including compression method, window size, and checksum verification
- ✅ **Adler32 Checksum**: Full implementation of the Adler-32 checksum algorithm
- ✅ **Binary Encoding**: Big-endian binary operations for ZLIB format compatibility
- ✅ **Error Handling**: Proper error handling using MoonBit's `raise`/`try` pattern
- ✅ **Reader/Writer API**: Simple and clean API for reading and writing ZLIB data
- ✅ **Dictionary Support**: Support for preset dictionaries in both reading and writing
- ✅ **Comprehensive Tests**: Full test coverage including round-trip testing

## API Overview

### Core Types

```moonbit
// ZLIB Reader for decompressing data
pub struct Reader

// ZLIB Writer for compressing data  
pub struct Writer

// Adler32 checksum calculator
pub struct Adler32
```

### Error Types

```moonbit
pub suberror ChecksumError String
pub suberror DictionaryError String  
pub suberror HeaderError String
```

### Basic Usage

#### Writing ZLIB Data

```moonbit
let writer = @zlib.Writer::new()
let data = [b'h', b'e', b'l', b'l', b'o']
writer.write(data)
writer.close()
let compressed_data = writer.to_bytes()
```

#### Reading ZLIB Data

```moonbit
let reader = @zlib.Reader::new(compressed_data)
let buf = Array::make(10, b'\x00')
try {
  let n = reader.read(buf)
  // Use the decompressed data in buf[:n]
} catch {
  @zlib.ChecksumError(msg) => // Handle checksum error
  @zlib.HeaderError(msg) => // Handle header error
  _ => // Handle other errors
}
```

#### Using Dictionaries

```moonbit
// Writer with dictionary
let dict = [b'd', b'i', b'c', b't']
let writer = @zlib.Writer::new_dict(dict)

// Reader with dictionary  
let reader = @zlib.Reader::new_dict(data, dict)
```

#### Adler32 Checksums

```moonbit
// One-shot calculation
let checksum = @zlib.checksum_array(data)

// Incremental calculation
let adler = @zlib.Adler32::new()
adler.write_array(part1)
adler.write_array(part2)
let checksum = adler.sum32()
```

## Implementation Notes

### Current Limitations

This is a **simplified implementation** for demonstration and basic compatibility:

1. **No Actual Compression**: The current implementation doesn't include actual DEFLATE compression/decompression. Data is passed through uncompressed but with proper ZLIB headers and checksums.

2. **Array-Based I/O**: Uses `Array[Byte]` instead of streaming I/O for simplicity.

3. **Basic Dictionary Support**: Dictionary checksums are validated but not used for actual compression.

### For Production Use

To make this production-ready, you would need to:

1. **Add DEFLATE Implementation**: Integrate with a DEFLATE compression library (like the existing `gmlewis/flate` package)
2. **Streaming I/O**: Implement proper streaming with the I/O traits
3. **Memory Optimization**: Optimize for memory usage and performance
4. **Advanced Dictionary Support**: Full dictionary-based compression

### Compatibility with gmlewis/zlib

This package provides a simplified, more MoonBit-idiomatic API compared to gmlewis/zlib:

| Feature | gmlewis/zlib | This Package |
|---------|-------------|--------------|
| Error Handling | `IOError?` | `raise`/`try` pattern |
| I/O Model | Streaming readers/writers | Array-based |
| Dictionary Support | Full | Basic validation |
| DEFLATE Compression | Yes | No (passthrough) |
| API Style | Go-like | MoonBit-idiomatic |

## Testing

The package includes comprehensive tests covering:

- Adler32 checksum calculations (incremental and one-shot)
- Binary encoding operations (big-endian UInt16/UInt32)
- Writer functionality and header generation
- Reader functionality and header validation
- Round-trip compression/decompression
- Dictionary support
- Error handling for invalid headers

Run tests with:
```bash
moon test
```

## Contributing

This implementation serves as a foundation for a complete ZLIB package. Contributions welcome for:

- Adding actual DEFLATE compression/decompression
- Implementing streaming I/O
- Performance optimizations
- Additional test cases