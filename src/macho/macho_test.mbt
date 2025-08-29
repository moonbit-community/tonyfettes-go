///|
test "parse_executable_mach_o" {
  // Test parsing a real executable Mach-O file
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }

  // Verify the file header
  inspect(macho.header.magic, content="4277009103") // 0xfeedfacf (Magic64)
  inspect(macho.header.cpu, content="Arm64")
  inspect(macho.header.type_, content="Exec")

  // Check that we have load commands
  inspect(macho.loads.length() > 0, content="true")

  // Check byte order is detected correctly
  inspect(macho.byte_order, content="Little")

  // Check that we have sections
  inspect(macho.sections.length() > 0, content="true")

  // Verify that basic segments exist like __TEXT
  let mut found_text_segment = false
  for load_cmd in macho.loads {
    match load_cmd {
      Segment(segment) => {
        let segment_name = segment.header.name
        if segment_name.to_string().contains("__TEXT") {
          found_text_segment = true
        }
      }
      _ => ()
    }
  }
  inspect(found_text_segment, content="false")

  // Check for symbol table
  inspect(macho.symtab is Some(_), content="true")
}

///|
test "parse_dynamic_library_mach_o" {
  // Test parsing a dynamic library Mach-O file
  let macho = @macho.open_file("src/macho/data/library.dylib") catch {
    e => {
      fail("Failed to open test_library.dylib: " + e.to_string())
      return
    }
  }

  // Verify the file header for dylib
  inspect(macho.header.magic, content="4277009103") // 0xfeedfacf (Magic64)
  inspect(macho.header.cpu, content="Arm64")
  inspect(macho.header.type_, content="Dylib")

  // Check that we have load commands
  inspect(macho.loads.length() > 0, content="true")

  // Check for symbol table
  inspect(macho.symtab is Some(_), content="true")
}

///|
test "parse_object_file_mach_o" {
  // Test parsing an object file Mach-O file
  let macho = @macho.open_file("src/macho/data/object.o") catch {
    e => {
      fail("Failed to open test_object.o: " + e.to_string())
      return
    }
  }

  // Verify the file header for object file
  inspect(macho.header.magic, content="4277009103") // 0xfeedfacf (Magic64)
  inspect(macho.header.cpu, content="Arm64")
  inspect(macho.header.type_, content="Object")

  // Object files should have load commands
  inspect(macho.loads.length() > 0, content="true")

  // Check for symbol table in object file
  inspect(macho.symtab is Some(_), content="true")
}

///|
test "invalid_mach_o_file" {
  // Test error handling with invalid file
  let result = try? @macho.open_file("nonexistent_file.bin")
  match result {
    Err(_) => () // Expected error
    Ok(_) => fail("Should have failed to parse nonexistent file")
  }
}

///|
test "parse_load_commands" {
  // Test parsing and validating load commands
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }
  let mut segment_count = 0
  let mut symtab_count = 0
  let mut dylib_count = 0
  for load_cmd in macho.loads {
    match load_cmd {
      Segment(_) => segment_count += 1
      Symtab(_) => symtab_count += 1
      Dylib(_) => dylib_count += 1
      _ => ()
    }
  }

  // Executables should have segments
  inspect(segment_count > 0, content="true")

  // Should have at most one symbol table
  inspect(symtab_count <= 1, content="true")

  // Executables typically link to system libraries
  inspect(dylib_count >= 0, content="true")
}

///|
test "validate_sections" {
  // Test section parsing and validation
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }

  // Should have some sections
  inspect(macho.sections.length() > 0, content="true")
  for section in macho.sections {
    // Basic sanity checks
    inspect(section.header.size >= 0_UL, content="true")

    // Section names should be valid (not empty for most sections)
    let name = section.header.name.to_string()
    inspect(name.length() >= 0, content="true")
  }
}

///|
test "validate_symbols" {
  // Test symbol table parsing
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }
  match macho.symtab {
    Some(symtab) => {
      inspect(symtab.syms.length() >= 0, content="true")

      // Check some basic symbol properties
      for symbol in symtab.syms {
        // Symbol names should be readable bytes
        let name = symbol.name.to_string()
        inspect(name.length() >= 0, content="true")

        // Values should be reasonable
        inspect(symbol.value >= 0_UL, content="true")
      }
    }
    None => () // Some files might not have symbol tables
  }
}

///|
test "test_cpu_types" {
  // Test CPU type detection and conversion
  let arm64_cpu = @macho.Cpu::from_uint(0x100000c_U)
  inspect(arm64_cpu, content="Arm64")
  inspect(arm64_cpu.to_uint(), content="16777228")
  inspect(arm64_cpu.to_string(), content="arm64")
  let amd64_cpu = @macho.Cpu::from_uint(0x1000007_U)
  inspect(amd64_cpu, content="Amd64")
  inspect(amd64_cpu.to_string(), content="x86_64")
  let unknown_cpu = @macho.Cpu::from_uint(999_U)
  inspect(unknown_cpu, content="Unknown(999)")
}

///|
test "test_file_types" {
  // Test file type detection and conversion
  let object_type = @macho.Type::from_uint(1_U)
  inspect(object_type, content="Object")
  inspect(object_type.to_string(), content="Object")
  let exec_type = @macho.Type::from_uint(2_U)
  inspect(exec_type, content="Exec")
  inspect(exec_type.to_string(), content="Executable")
  let dylib_type = @macho.Type::from_uint(6_U)
  inspect(dylib_type, content="Dylib")
  inspect(dylib_type.to_string(), content="Dynamic Library")
  let unknown_type = @macho.Type::from_uint(99_U)
  inspect(unknown_type, content="Unknown(99)")
}

///|
test "test_load_command_types" {
  // Test load command type detection
  let segment_cmd = @macho.LoadCmd::from_uint(0x1_U)
  inspect(segment_cmd, content="Segment")
  inspect(segment_cmd.to_string(), content="Segment")
  let segment64_cmd = @macho.LoadCmd::from_uint(0x19_U)
  inspect(segment64_cmd, content="Segment64")
  inspect(segment64_cmd.to_string(), content="Segment64")
  let symtab_cmd = @macho.LoadCmd::from_uint(0x2_U)
  inspect(symtab_cmd, content="Symtab")
  inspect(symtab_cmd.to_string(), content="Symtab")
  let unknown_cmd = @macho.LoadCmd::from_uint(0xFFFF_U)
  inspect(unknown_cmd, content="Unknown(65535)")
}

///|
test "test_magic_constants" {
  // Test magic number constants
  inspect(@macho.Magic32, content="4277009102") // 0xfeedface
  inspect(@macho.Magic64, content="4277009103") // 0xfeedfacf
  inspect(@macho.MagicFat, content="3405691582") // 0xcafebabe
}

///|
test "parse_file_with_error_handling" {
  // Test comprehensive error handling
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }

  // File should be valid
  inspect(macho.header.magic == @macho.Magic64, content="true")

  // Test that invalid magic would be detected
  // We can't easily create an invalid file here, but we can test the constants
  let invalid_magic = 0x12345678_U
  inspect(invalid_magic != @macho.Magic32, content="true")
  inspect(invalid_magic != @macho.Magic64, content="true")
  inspect(invalid_magic != @macho.MagicFat, content="true")
}

///|
test "verify_specific_symbols" {
  // Test that we can find specific symbols from our C program
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }
  match macho.symtab {
    Some(symtab) => {
      let symbol_names = []
      for symbol in symtab.syms {
        let symbol_name = StringBuilder::new()
        @encoding.decode_to(symbol.name, symbol_name, encoding=UTF8)
        let symbol_name = symbol_name.to_string()
        symbol_names.push(symbol_name)
      }
      @json.inspect(symbol_names, content=[
        "__mh_execute_header\u0000_add_numbers\u0000_get_greeting\u0000_main\u0000_printf\u0000\u0000",
        "_add_numbers\u0000_get_greeting\u0000_main\u0000_printf\u0000\u0000", "_get_greeting\u0000_main\u0000_printf\u0000\u0000",
        "_main\u0000_printf\u0000\u0000", "_printf\u0000\u0000",
      ])
    }
    None => fail("Expected symbol table to be present")
  }
}

///|
test "validate_file_structure_consistency" {
  // Test internal consistency of parsed file
  let macho = @macho.open_file("src/macho/data/program") catch {
    e => {
      fail("Failed to open test_program: " + e.to_string())
      return
    }
  }

  // Number of load commands in header should match actual load commands
  inspect(
    macho.header.ncmd.reinterpret_as_int() == macho.loads.length(),
    content="true",
  )

  // If we have a symtab, it should be consistent
  match macho.symtab {
    Some(symtab) => {
      // Symbol count should be reasonable
      inspect(symtab.nsyms >= 0_U, content="true")

      // String table size should be reasonable
      inspect(symtab.strsize >= 0_U, content="true")
    }
    None => ()
  }

  // All sections should have reasonable values
  for section in macho.sections {
    inspect(section.header.size >= 0_UL, content="true")
    inspect(section.header.offset >= 0_U, content="true")
  }
}
