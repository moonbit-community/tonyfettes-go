# MoonBit Regular Expression Package

This package provides regular expression functionality for MoonBit, translated from Go's `regexp` package.

## Features

- **Regular Expression Compilation**: Parse and compile regular expressions into an executable form
- **Pattern Matching**: Match strings and byte arrays against compiled regular expressions  
- **POSIX and Perl Syntax**: Support for both POSIX ERE and Perl-style regular expressions
- **Capture Groups**: Extract submatches using parenthesized capture groups
- **Linear Time Execution**: Guaranteed linear time execution (no catastrophic backtracking)

## Package Structure

```
src/regexp/
├── regexp.mbt        # Main Regexp type and public API
├── exec.mbt          # NFA execution engine  
├── syntax/           # Parsing and AST representation
│   ├── regexp.mbt    # AST nodes and operations
│   ├── parse.mbt     # Parser implementation
│   ├── compile.mbt   # Compilation to NFA instructions
│   └── error.mbt     # Error handling types
└── tests/            # Test files
```

## Basic Usage

### Compiling Regular Expressions

```moonbit
test "basic compilation" {
  // Compile a simple regexp
  let re = @regexp.must_compile("hello")
  inspect(re.to_string(), content="hello")
  
  // Or handle errors explicitly
  match @regexp.compile("world") {
    Ok(re) => println("Compiled successfully")
    Err(e) => println("Compilation error: " + e.to_string())
  }
}
```

### Pattern Matching

```moonbit
test "pattern matching" {
  let re = @regexp.must_compile("hello")
  
  // Match against strings
  inspect(re.match_string("hello world"), content="true")
  inspect(re.match_string("goodbye"), content="false")
  
  // Package-level convenience functions
  let result = @regexp.match_string("test", "testing")
  match result {
    Ok(matched) => inspect(matched, content="true")
    Err(e) => println("Error: " + e.to_string())
  }
}
```

### POSIX vs Perl Syntax

```moonbit
test "syntax modes" {
  // Perl-style (default) - supports advanced features
  let perl_re = @regexp.compile("hello.*world")
  
  // POSIX ERE - more restricted, leftmost-longest matching
  let posix_re = @regexp.compile_posix("hello.*world")
  
  // Both should work for basic patterns
  match (perl_re, posix_re) {
    (Ok(re1), Ok(re2)) => {
      inspect(re1.match_string("hello beautiful world"), content="true")
      inspect(re2.match_string("hello beautiful world"), content="true")
    }
    _ => println("Compilation failed")
  }
}
```

## Supported Syntax

### Basic Patterns

- `.` - matches any character except newline
- `^` - matches beginning of line/text
- `$` - matches end of line/text  
- `*` - matches 0 or more repetitions
- `+` - matches 1 or more repetitions
- `?` - matches 0 or 1 repetition

### Character Classes

- `[abc]` - matches any of a, b, or c
- `[a-z]` - matches any lowercase letter
- `[^abc]` - matches anything except a, b, or c

### Escape Sequences

- `\n` - newline
- `\t` - tab
- `\r` - carriage return
- `\\` - literal backslash
- `\.` - literal period

## Implementation Notes

This is a **basic translation** of Go's regexp package to MoonBit. The current implementation includes:

✅ **Implemented:**
- Basic AST structure and types
- Simple parsing for literal strings and basic patterns
- Compilation framework
- Basic NFA execution engine
- String and byte array input support
- Error handling types
- Core public API

🚧 **Partially Implemented:**
- Pattern parsing (only basic patterns supported)
- NFA execution (simplified implementation)
- Character class matching

❌ **Not Yet Implemented:**
- Full regexp parser (complex patterns, quantifiers, groups)
- Optimized execution engines (one-pass, backtracking)
- Advanced features (named captures, lookahead/lookbehind)
- Unicode property support
- Performance optimizations

## Performance Characteristics

- **Linear Time**: The execution engine guarantees O(n*m) time complexity where n is input length and m is pattern size
- **No Catastrophic Backtracking**: Unlike traditional backtracking implementations, this uses NFA simulation
- **Memory Efficient**: Uses sparse queue representation for NFA state tracking

## Error Handling

The package uses Result types for error handling:

```moonbit
test "error handling" {
  // Compilation errors
  match @regexp.compile("[invalid") {
    Ok(_) => println("Unexpected success")
    Err(e) => {
      inspect(e.code, content="ErrMissingBracket")
      println("Error: " + e.to_string())
    }
  }
}
```

## Contributing

This package is part of the MoonBit standard library ecosystem. Contributions to improve compatibility with Go's regexp package are welcome.

## License

This package follows the same license as the MoonBit standard library.