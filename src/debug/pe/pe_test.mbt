/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// Test basic PE constants
test "PE constants" {
  // Test machine constants
  @json.inspect(@pe.IMAGE_FILE_MACHINE_I386, content=332)
  @json.inspect(@pe.IMAGE_FILE_MACHINE_AMD64, content=34404)
  @json.inspect(@pe.IMAGE_FILE_MACHINE_ARM64, content=43620)

  // Test directory entry constants
  @json.inspect(@pe.IMAGE_DIRECTORY_ENTRY_IMPORT, content="1")
  @json.inspect(@pe.IMAGE_DIRECTORY_ENTRY_EXPORT, content="0")

  // Test file characteristics constants
  @json.inspect(@pe.IMAGE_FILE_EXECUTABLE_IMAGE, content=2)
  @json.inspect(@pe.IMAGE_FILE_DLL, content=8192)
}

///|
/// Test basic types creation and serialization
test "PE types" {
  let file_header = @pe.FileHeader::{
    machine: @pe.IMAGE_FILE_MACHINE_AMD64,
    number_of_sections: 5,
    time_date_stamp: 1609459200,
    pointer_to_symbol_table: 0,
    number_of_symbols: 0,
    size_of_optional_header: 240,
    characteristics: @pe.IMAGE_FILE_EXECUTABLE_IMAGE |
    @pe.IMAGE_FILE_LARGE_ADDRESS_AWARE,
  }
  @json.inspect(file_header, content={
    "machine": 34404,
    "number_of_sections": 5,
    "time_date_stamp": "1609459200",
    "pointer_to_symbol_table": "0",
    "number_of_symbols": "0",
    "size_of_optional_header": 240,
    "characteristics": 34,
  })
  let data_dir = @pe.DataDirectory::{ virtual_address: 8192, size: 1024 }
  @json.inspect(data_dir, content={ "virtual_address": "8192", "size": "1024" })
}

///|
/// Test section header creation
test "Section header" {
  let section_header = @pe.SectionHeader::{
    name: ".text",
    virtual_size: 4096,
    virtual_address: 8192,
    size: 4096,
    offset: 1024,
    pointer_to_relocations: 0,
    pointer_to_line_numbers: 0,
    number_of_relocations: 0,
    number_of_line_numbers: 0,
    characteristics: @pe.IMAGE_SCN_CNT_CODE |
    @pe.IMAGE_SCN_MEM_EXECUTE |
    @pe.IMAGE_SCN_MEM_READ,
  }
  @json.inspect(section_header, content={
    "name": ".text",
    "virtual_size": "4096",
    "virtual_address": "8192",
    "size": "4096",
    "offset": "1024",
    "pointer_to_relocations": "0",
    "pointer_to_line_numbers": "0",
    "number_of_relocations": 0,
    "number_of_line_numbers": 0,
    "characteristics": "1610612768",
  })
}

///|
/// Test symbol creation
test "COFF Symbol" {
  let name_array : FixedArray[Byte] = [
    ('t' : Byte),
    ('e' : Byte),
    ('s' : Byte),
    ('t' : Byte),
    (0 : Byte),
    (0 : Byte),
    (0 : Byte),
    (0 : Byte),
  ]
  let coff_symbol = @pe.COFFSymbol::{
    name: name_array,
    value: 4096,
    section_number: 1,
    type_: 0,
    storage_class: 2,
    number_of_aux_symbols: 0,
  }
  @json.inspect(coff_symbol.value, content="4096")
  @json.inspect(coff_symbol.section_number, content=1)
  let symbol = @pe.Symbol::{
    name: "test_function",
    value: 8192,
    section_number: 1,
    type_: 32,
    storage_class: 2,
  }
  @json.inspect(symbol, content={
    "name": "test_function",
    "value": "8192",
    "section_number": 1,
    "type_": 32,
    "storage_class": 2,
  })
}

///|
/// Test optional header variants
test "Optional header variants" {
  let header32 = @pe.OptionalHeader32::{
    magic: 267,
    major_linker_version: 14,
    minor_linker_version: 0,
    size_of_code: 4096,
    size_of_initialized_data: 2048,
    size_of_uninitialized_data: 0,
    address_of_entry_point: 8192,
    base_of_code: 4096,
    base_of_data: 12288,
    image_base: 4194304,
    section_alignment: 4096,
    file_alignment: 512,
    major_operating_system_version: 6,
    minor_operating_system_version: 0,
    major_image_version: 0,
    minor_image_version: 0,
    major_subsystem_version: 6,
    minor_subsystem_version: 0,
    win32_version_value: 0,
    size_of_image: 16384,
    size_of_headers: 1024,
    check_sum: 0,
    subsystem: @pe.IMAGE_SUBSYSTEM_WINDOWS_CUI,
    dll_characteristics: 0,
    size_of_stack_reserve: 1048576,
    size_of_stack_commit: 4096,
    size_of_heap_reserve: 1048576,
    size_of_heap_commit: 4096,
    loader_flags: 0,
    number_of_rva_and_sizes: 16,
    data_directory: [],
  }
  @json.inspect(header32.magic, content=267)
  @json.inspect(header32.subsystem, content=3)
  let header_variant = @pe.OptionalHeaderVariant::Header32(header32)
  match header_variant {
    @pe.OptionalHeaderVariant::Header32(h) =>
      @json.inspect(h.magic, content=267)
    @pe.OptionalHeaderVariant::Header64(_) => @json.inspect(false, content=true)
    @pe.OptionalHeaderVariant::None => @json.inspect(false, content=true)
  }
}

///|
/// Test file structure
test "PE File structure" {
  let empty_file = @pe.open("nonexistent.exe")
  @json.inspect(empty_file.file_header.machine, content=0)
  @json.inspect(empty_file.sections.length(), content=0)
  @json.inspect(empty_file.symbols.length(), content=0)
  match empty_file.optional_header {
    @pe.OptionalHeaderVariant::None => @json.inspect(true, content=true)
    _ => @json.inspect(false, content=true)
  }
}

///|
/// Test import directory structure
test "Import directory" {
  let import_dir = @pe.ImportDirectory::{
    original_first_thunk: 8192,
    time_date_stamp: 0,
    forwarder_chain: 0,
    name: 16384,
    first_thunk: 12288,
    dll: "kernel32.dll",
  }
  @json.inspect(import_dir, content={
    "original_first_thunk": "8192",
    "time_date_stamp": "0",
    "forwarder_chain": "0",
    "name": "16384",
    "first_thunk": "12288",
    "dll": "kernel32.dll",
  })
}

///|
/// Test string table functionality
test "String table" {
  let string_table = @pe.string_table_string(@slice.new(), 4)
  @json.inspect(string_table, content="")
}

///|
/// Test error handling
test "Format error" {
  let format_error = @pe.FormatError::{  }
  let error_msg = format_error.error()
  @json.inspect(error_msg, content="unknown error")
}

///|
/// Test section operations  
test "Section operations" {
  let empty_file = @pe.open("test.exe")
  let section = empty_file.section(".text")
  match section {
    None => @json.inspect(true, content=true)
    Some(_) => @json.inspect(false, content=true)
  }
  let imported_symbols = empty_file.imported_symbols()
  @json.inspect(imported_symbols.length(), content=0)
  let imported_libraries = empty_file.imported_libraries()
  @json.inspect(imported_libraries.length(), content=0)
}
