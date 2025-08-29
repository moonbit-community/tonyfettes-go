# tonyfettes/debugo

A **MoonBit library** for parsing and analyzing binary debugging formats, with comprehensive support for **Mach-O binary files** (macOS/iOS executables, libraries, and object files). This library is inspired by and maintains API compatibility with Go's `debug/macho` package while leveraging MoonBit's strong type system for safer binary parsing.

## Core Libraries

The project implements three main MoonBit packages:

### 1. **Mach-O Parser (`src/macho/`)**

- **Primary focus**: Complete port of Go's `debug/macho` package
- **Functionality**: Parses Mach-O binary files (macOS/iOS executables, libraries, object files)
- **Features**:
  - 32-bit and 64-bit Mach-O support
  - Cross-architecture parsing (x86, x86_64, ARM, ARM64, PowerPC)
  - Load command parsing (segments, symbol tables, dynamic libraries)
  - Symbol table analysis and extraction
  - Fat/Universal binary support
  - DWARF debug information extraction with ZLIB decompression
  - Section and segment data access

### 2. **DWARF Debug Information (`src/dwarf/`)**

- **Purpose**: DWARF debugging format support
- **Integration**: Works with Mach-O parser to extract debug information

### 3. **I/O Utilities (`src/io/`)**

- **Purpose**: Common I/O operations for binary parsing
- **Integration**: Provides shared functionality across parsers

## Features

- **Complete Mach-O Support**: Parse 32-bit and 64-bit Mach-O files with full cross-architecture support
- **Type Safety**: Leverages MoonBit's strong type system for safe binary parsing with comprehensive error handling
- **DWARF Debug Information**: Extract and analyze debugging information with automatic ZLIB decompression
- **Universal Binary Support**: Handle Fat/Universal binaries with multiple architectures
- **Symbol Analysis**: Extract symbol tables, dynamic symbols, and library dependencies
- **High-Level API**: Convenient functions for common binary analysis tasks

## Current Status

According to the documentation, the project is **~85-90% complete** for the Mach-O library:

**✅ Completed Features:**

- Complete Mach-O file parsing (32-bit/64-bit)
- Fat/Universal binary support
- Symbol table extraction and analysis
- Load command parsing
- Section/segment data access
- DWARF debug information extraction
- File I/O integration
- High-level query functions

**🚧 Remaining Work:**

- Complete relocation processing
- Architecture-specific relocation types
- Advanced data access methods
- Thread state/register parsing
- Enhanced error context
- Comprehensive testing with real binaries

## Technical Architecture

- **Language**: MoonBit (a modern functional programming language)
- **Build System**: Moon (MoonBit's package manager)
- **Dependencies**:
  - `moonbitlang/x` (MoonBit extended library)
  - `gmlewis/zlib` (compression support for DWARF)
- **Error Handling**: Uses MoonBit's structured error system with `suberror` types
- **Binary Data**: Proper handling of raw bytes (avoiding string conversion issues)

## Use Cases

This library enables MoonBit applications to:

- Analyze macOS/iOS application binaries
- Extract debugging information from executables
- Parse dynamic library dependencies
- Examine code signatures and load commands
- Support reverse engineering and binary analysis tools
- Enable development tools that work with Apple platform binaries

## Getting Started

### Installation

Add the library to your MoonBit project:

```bash
moon add tonyfettes/debugo
```

### Basic Usage

```moonbit
// Parse a Mach-O file
let file_data = @fs.read_file_to_bytes("example.dylib")
let file = @macho.File::new(file_data)

// Examine file properties
println("Architecture: \{file.header.cpu}")
println("File Type: \{file.header.type_}")

// Extract DWARF debug information
match file.dwarf(file_data) {
  Some(dwarf_data) => {
    let sections = dwarf_data.get_section_names()
    println("DWARF sections: \{sections}")
  }
  None => println("No debug information found")
}
```

For detailed usage examples and API documentation, see [`src/macho/README.mbt.md`](src/macho/README.mbt.md).

## Contributing

This project welcomes contributions! Key areas for contribution:

1. **Complete remaining features**: See the roadmap in `src/macho/README.mbt.md`
2. **Add comprehensive tests**: Especially with real-world binary files
3. **Improve documentation**: Add more usage examples and API docs
4. **Port additional debug formats**: Consider porting `debug/elf`, `debug/pe`, etc.

## License

Apache-2.0 - See LICENSE file for details.

## Related Work

This library's API design is inspired by Go's `debug/macho` package, adapted for MoonBit's type system and functional programming paradigms.
