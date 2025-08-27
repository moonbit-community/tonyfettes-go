# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Project Structure

- MoonBit packages are organized per directory, for each directory, there is a
  `package.json` file listing its dependencies. Each package has its files and
  blackbox test files (common, ending in `_test.mbt`) and whitebox test files
  (ending in `_wbtest.mbt`).

- In the toplevel directory, this is a `moon.mod.json` file listing about the
  module and some meta information.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check the test is passed. MoonBit supports snapshot
  testing, so when your changes indeed change the behavior of the code, you
  should run `moon test --update` to update the snapshot.

- You can run `moon check` to check the code is linted correctly.

- When writing tests, you are encouraged to use `inspect` and run
  `moon test --update` to update the snapshots, only use assertions like
  `assert_eq` when you are in some loops where each snapshot may vary. You can
  use `moon coverage analyze > uncovered.log` to see which parts of your code
  are not covered by tests.

- agent-todo.md has some small tasks that are easy for AI to pick up, agent is
  welcome to finish the tasks and check the box when you are done

## Error Handling in MoonBit

MoonBit uses a structured error handling system based on `suberror` types and the `raise` keyword, similar to exceptions but statically typed.

### Defining Error Types

Use `suberror` to define custom error types with labelled payloads:

```moonbit
suberror FormatError {
  InvalidMagic(magic~ : UInt)
  FileTooSmall(actual_size~ : Int, required_size~ : Int)
  InvalidHeader(offset~ : Int64, message~ : String)
}

suberror ParseError {
  InvalidCommandSize(offset~ : Int, size~ : UInt)
  MissingData(offset~ : Int64, expected~ : String)
}
```

### Function Signatures

Functions that may raise errors use `-> T raise ErrorType` syntax:

```moonbit
fn parse_file(data : Bytes) -> File raise {
  // Function body that may raise FormatError, ParseError, etc.
}

// For specific error types:
fn parse_header(data : Bytes) -> FileHeader raise FormatError {
  // Only raises FormatError
}
```

### Raising Errors

Use `raise ErrorType::Variant(payload)` to throw errors:

```moonbit
if data.length() < 4 {
  raise FormatError::FileTooSmall(actual_size=data.length(), required_size=4)
}

if magic != expected_magic {
  raise FormatError::InvalidMagic(magic~)
}
```

### Handling Errors

Use `try...catch` blocks to handle errors:

```moonbit
try {
  let file = parse_file(data)
  // Success case
} catch {
  FormatError::FileTooSmall(actual_size~, required_size~) => {
    println("File too small: got \{actual_size}, need \{required_size}")
  }
  FormatError::InvalidMagic(magic~) => {
    println("Invalid magic number: 0x\{magic.to_hex()}")
  }
  _ => println("Unknown error occurred")
}
```

### Error Propagation

Functions automatically propagate compatible error types:

```moonbit
fn high_level_parse(data : Bytes) -> File raise {
  let file = parse_file(data) // Automatically propagates FormatError, ParseError
  file
}
```

### Best Practices

1. **Use descriptive error variants**: Each variant should represent a specific error condition
2. **Include contextual information**: Use labelled payloads to provide offset, expected values, etc.
3. **Group related errors**: Use separate suberror types for different layers (FormatError, ParseError, etc.)
4. **Test error cases**: Always write tests for both success and error scenarios using `try...catch`
5. **Document error conditions**: Clearly document what errors a function may raise

## Implementation Learnings

### Method Definition Syntax

When adding methods to existing types in MoonBit, use the explicit syntax:

```moonbit
pub fn TypeName::method_name(self : TypeName, other_params : Type) -> ReturnType raise {
  // Method body
}
```

All parameter types must be explicitly annotated, including `self`.

### File I/O Integration

- Use `@fs.read_file_to_bytes(path)` for reading files from filesystem
- The `@fs` package provides direct file system access capabilities
- File I/O functions should handle errors appropriately, either with try/catch or by letting errors propagate

### Type Conversions

- Use `reinterpret_as_int()` instead of deprecated `to_int()` for UInt to Int conversion
- For UInt64 to Int conversion: `value.to_uint().reinterpret_as_int()`
- Always check data bounds before performing conversions

### Data Access Patterns

When implementing data extraction from binary formats:

```moonbit
pub fn Section::data(self : Section, file_data : Bytes) -> Bytes raise {
  match self.data {
    Some(data) => data  // Return cached data if available
    None => {
      // Extract from file_data using offset and size
      let offset = self.header.offset.reinterpret_as_int()
      let size = self.header.size.to_uint().reinterpret_as_int()
      if file_data.length() < offset + size {
        raise ParseError::MissingData(/*...*/)
      }
      read_bytes(file_data, offset, size)
    }
  }
}
```

### Symbol Parsing Integration

- Symbol parsing should be integrated into the main file parsing pipeline
- Use fallback mechanisms when symbol parsing fails to maintain robustness
- Parse symbols lazily or with error handling to avoid breaking the entire file parsing

### Project Architecture Insights

- The macho library implements a Mach-O binary format parser similar to Go's debug/macho
- Fat/Universal binary support was already well-implemented
- The main missing pieces were file I/O, data access methods, and complete symbol parsing
- Tests are comprehensive and help ensure implementation correctness
- The codebase follows MoonBit's block-style organization with `///|` separators
