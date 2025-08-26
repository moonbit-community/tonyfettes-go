///|
/// Simple example demonstrating the MoonBit Mach-O library
fn main {
  println("=== MoonBit Mach-O Parser Library Demo ===")
  println("")

  // Demo 1: Basic constants
  demo_constants()

  // Demo 2: File parsing
  demo_file_parsing()
  println("")
  println("=== Demo Complete ===")
}

///|
fn demo_constants() -> Unit {
  println("1. Constants Demo")
  println("-----------------")

  // Magic numbers
  println("Magic Numbers:")
  println("  32-bit: 0x" + @macho.magic_32.to_string())
  println("  64-bit: 0x" + @macho.magic_64.to_string())
  println("  Fat:    0x" + @macho.magic_fat.to_string())

  // Type conversions
  println("")
  println("Type Conversions:")
  let obj_type = @macho.Type::from_uint(1_U)
  let exec_type = @macho.Type::from_uint(2_U)
  println("  Type 1: " + obj_type.to_string())
  println("  Type 2: " + exec_type.to_string())

  // CPU conversions
  println("")
  println("CPU Conversions:")
  let i386_cpu = @macho.Cpu::from_uint(7_U)
  let arm64_cpu = @macho.Cpu::from_uint(16777228_U)
  println("  CPU 7: " + i386_cpu.to_string())
  println("  CPU 16777228: " + arm64_cpu.to_string())
  println("")
}

///|
fn demo_file_parsing() -> Unit {
  println("2. File Parsing Demo")
  println("--------------------")

  // Create a minimal valid Mach-O header
  let header_bytes = "\u{ce}\u{fa}\u{ed}\u{fe}" + // magic_32 (little endian)
    "\u{07}\u{00}\u{00}\u{00}" + // cpu (i386 = 7)
    "\u{00}\u{00}\u{00}\u{00}" + // subcpu (0)
    "\u{02}\u{00}\u{00}\u{00}" + // file type (exec = 2)
    "\u{00}\u{00}\u{00}\u{00}" + // ncmd (0)
    "\u{00}\u{00}\u{00}\u{00}" + // cmdsz (0)
    "\u{00}\u{00}\u{00}\u{00}" // flags (0)
  let file_data = header_bytes.to_bytes()
  match @macho.parse_file(file_data) {
    Ok(file) => {
      println("✓ Successfully parsed Mach-O file")
      println("  Magic: 0x" + file.header.magic.to_string())
      println("  CPU: " + @macho.get_architecture(file))
      println("  Type: " + @macho.get_file_type(file))
      println("  64-bit: " + @macho.is_64bit(file).to_string())
      println("  Commands: " + file.header.ncmd.to_string())
    }
    Err(err) => println("✗ Parse failed: " + err.message)
  }

  // Demo error handling with invalid data
  println("")
  let invalid_data = "invalid".to_bytes()
  match @macho.parse_file(invalid_data) {
    Ok(_) => println("Unexpected success")
    Err(err) => println("✓ Expected error: " + err.message)
  }

  // Demo binary utilities
  println("")
  println("Binary Utilities:")
  let data = "hello\u{00}world".to_bytes()
  let str = @macho.cstring(data)
  println("  C-string extraction: '" + str + "'")
  let valid_magic = @macho.is_valid_magic(@macho.magic_32)
  let invalid_magic = @macho.is_valid_magic(0x12345678_U)
  println("  Valid magic check: " + valid_magic.to_string())
  println("  Invalid magic check: " + invalid_magic.to_string())
}
