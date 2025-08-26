///|
/// Test cases for utility functions

// Helper to create a minimal test file with given values
fn create_test_file_helper() -> File {
  {
    header: {
      magic: magic_64,
      cpu: Arm64,
      sub_cpu: 0_U,
      type_: Exec,
      ncmd: 2_U,
      cmdsz: 100_U,
      flags: flag_pie | flag_two_level,
    },
    byte_order: Little,
    loads: Array::new(),
    sections: Array::new(),
    symtab: None,
    dysymtab: None,
  }
}

///|
test "is_64bit and is_32bit" {
  let file64 = create_test_file_helper()
  let file32 = {
    header: {
      magic: magic_32,
      cpu: I386,
      sub_cpu: 0_U,
      type_: Exec,
      ncmd: 0_U,
      cmdsz: 0_U,
      flags: 0_U,
    },
    byte_order: Little,
    loads: Array::new(),
    sections: Array::new(),
    symtab: None,
    dysymtab: None,
  }
  assert_true(is_64bit(file64))
  assert_false(is_32bit(file64))
  assert_false(is_64bit(file32))
  assert_true(is_32bit(file32))
}

///|
test "get_architecture" {
  let file_i386 = {
    header: {
      magic: magic_32,
      cpu: I386,
      sub_cpu: 0_U,
      type_: Exec,
      ncmd: 0_U,
      cmdsz: 0_U,
      flags: 0_U,
    },
    byte_order: Little,
    loads: Array::new(),
    sections: Array::new(),
    symtab: None,
    dysymtab: None,
  }
  assert_eq(get_architecture(file_i386), "i386")
}

///|
test "get_file_type" {
  let file_obj = {
    header: {
      magic: magic_64,
      cpu: Arm64,
      sub_cpu: 0_U,
      type_: Object,
      ncmd: 0_U,
      cmdsz: 0_U,
      flags: 0_U,
    },
    byte_order: Little,
    loads: Array::new(),
    sections: Array::new(),
    symtab: None,
    dysymtab: None,
  }
  assert_eq(get_file_type(file_obj), "Object")
}

///|
test "get_file_summary" {
  let file = create_test_file_helper()
  let summary = get_file_summary(file)
  assert_true(summary.contains("64-bit"))
  assert_true(summary.contains("Executable"))
  assert_true(summary.contains("arm64"))
}

///|
test "has_flag" {
  let file = create_test_file_helper()
  assert_true(has_flag(file, flag_pie))
  assert_true(has_flag(file, flag_two_level))
  assert_false(has_flag(file, flag_no_undefs))
  assert_false(has_flag(file, flag_bind_at_load))
}

///|
test "get_flags_description" {
  let file = create_test_file_helper()
  let flags = get_flags_description(file)
  assert_true(flags.length() >= 2)
  assert_true(flags.contains("PIE"))
  assert_true(flags.contains("TWO_LEVEL"))
}

///|
test "get_load_command_type" {
  // Test segment command
  let segment = {
    load_bytes: { data: Bytes::new(0) },
    header: {
      cmd: LoadCmd::Segment64,
      len: 72_U,
      name: "__TEXT",
      addr: 0_UL,
      memsz: 1000_UL,
      offset: 0_UL,
      filesz: 1000_UL,
      maxprot: 7_U,
      prot: 5_U,
      nsect: 0_U,
      flag: 0_U,
    },
    data: None,
  }
  let seg_cmd = LoadCommand::Segment(segment)
  assert_eq(get_load_command_type(seg_cmd), "SEGMENT_64")

  // Test other command types
  let load_bytes = LoadCommand::LoadBytes({ data: Bytes::new(0) })
  assert_eq(get_load_command_type(load_bytes), "LoadBytes")
}

///|
test "join_strings helper" {
  let strings = ["hello", "world", "test"]
  assert_eq(join_strings(strings, ", "), "hello, world, test")
  let empty : Array[String] = []
  assert_eq(join_strings(empty, ","), "")
  let single = ["only"]
  assert_eq(join_strings(single, ","), "only")
}
