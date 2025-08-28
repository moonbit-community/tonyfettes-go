///|
/// Tests for DWARF debug information functionality
test "dwarf module basic functionality" {
  // Test DWARF section suffix extraction
  let section_debug_info = Section::{
    header: {
      name: "__debug_info",
      seg: "__DWARF",
      addr: 0_UL,
      size: 100_UL,
      offset: 1000_U,
      align: 0_U,
      reloff: 0_U,
      nreloc: 0_U,
      flags: 0_U,
    },
    relocs: [],
    data: None,
  }
  let suffix = dwarf_suffix(section_debug_info)
  assert_eq(suffix, "info")

  // Test compressed DWARF section
  let section_zdebug_str = Section::{
    header: {
      name: "__zdebug_str",
      seg: "__DWARF",
      addr: 0_UL,
      size: 100_UL,
      offset: 1000_U,
      align: 0_U,
      reloff: 0_U,
      nreloc: 0_U,
      flags: 0_U,
    },
    relocs: [],
    data: None,
  }
  let suffix2 = dwarf_suffix(section_zdebug_str)
  assert_eq(suffix2, "str")

  // Test non-DWARF section
  let section_text = Section::{
    header: {
      name: "__text",
      seg: "__TEXT",
      addr: 0_UL,
      size: 100_UL,
      offset: 1000_U,
      align: 0_U,
      reloff: 0_U,
      nreloc: 0_U,
      flags: 0_U,
    },
    relocs: [],
    data: None,
  }
  let suffix3 = dwarf_suffix(section_text)
  assert_eq(suffix3, "")
}

///|
test "dwarf data structure" {
  // Test DwarfData creation and access
  let sections : Map[Bytes, Bytes] = Map::new()
  sections["info"] = "dummy debug info"
  sections["str"] = "dummy debug strings"
  let dwarf_data = DwarfData::{ sections, }

  // Test section access
  match dwarf_data.get_section("info") {
    Some(data) => assert_eq(data, "dummy debug info")
    None => assert_false(true)
  }

  // Test section names
  let names = dwarf_data.get_section_names()
  assert_true(names.contains("info"))
  assert_true(names.contains("str"))

  // Test has_section
  assert_true(dwarf_data.has_section("info"))
  assert_false(dwarf_data.has_section("nonexistent"))
}

///|
test "big endian uint64 reading" {
  // Test reading 64-bit big-endian integers
  let data = Bytes::from_array([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])
  let result = read_uint64_be(data, 0)
  let expected = 0x0123456789abcdef_UL
  assert_eq(result, expected)
}
