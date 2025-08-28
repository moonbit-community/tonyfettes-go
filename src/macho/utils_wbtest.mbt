///|
fn create_test_file_helper() -> File {
  {
    header: {
      magic: Magic64,
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
      magic: Magic32,
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
      magic: Magic32,
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
      magic: Magic64,
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
test "has_flag" {
  let file = create_test_file_helper()
  assert_true(has_flag(file, flag_pie))
  assert_true(has_flag(file, flag_two_level))
  assert_false(has_flag(file, flag_no_undefs))
  assert_false(has_flag(file, flag_bind_at_load))
}
