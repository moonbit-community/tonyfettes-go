/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
pub(all) struct FileHeader {
  machine : UInt16
  number_of_sections : UInt16
  time_date_stamp : UInt
  pointer_to_symbol_table : UInt
  number_of_symbols : UInt
  size_of_optional_header : UInt16
  characteristics : UInt16
} derive(Show, Eq, ToJson)

///|
pub impl @binary.Readable for FileHeader with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> FileHeader raise {
  FileHeader::{
    machine: @binary.read(r, order),
    number_of_sections: @binary.read(r, order),
    time_date_stamp: @binary.read(r, order),
    pointer_to_symbol_table: @binary.read(r, order),
    number_of_symbols: @binary.read(r, order),
    size_of_optional_header: @binary.read(r, order),
    characteristics: @binary.read(r, order),
  }
}

///|
pub impl @binary.Sized for FileHeader with size() -> Int {
  20
}

///|
pub(all) struct DataDirectory {
  virtual_address : UInt
  size : UInt
} derive(Show, Eq, ToJson, Default)

///|
impl @binary.Readable for DataDirectory with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> DataDirectory raise {
  DataDirectory::{
    virtual_address: @binary.read(r, order),
    size: @binary.read(r, order),
  }
}

///|
pub(all) struct OptionalHeader32 {
  magic : UInt16
  major_linker_version : Byte
  minor_linker_version : Byte
  size_of_code : UInt
  size_of_initialized_data : UInt
  size_of_uninitialized_data : UInt
  address_of_entry_point : UInt
  base_of_code : UInt
  base_of_data : UInt
  image_base : UInt
  section_alignment : UInt
  file_alignment : UInt
  major_operating_system_version : UInt16
  minor_operating_system_version : UInt16
  major_image_version : UInt16
  minor_image_version : UInt16
  major_subsystem_version : UInt16
  minor_subsystem_version : UInt16
  win32_version_value : UInt
  size_of_image : UInt
  size_of_headers : UInt
  check_sum : UInt
  subsystem : UInt16
  dll_characteristics : UInt16
  size_of_stack_reserve : UInt
  size_of_stack_commit : UInt
  size_of_heap_reserve : UInt
  size_of_heap_commit : UInt
  loader_flags : UInt
  number_of_rva_and_sizes : UInt
  data_directory : FixedArray[DataDirectory] // [16]DataDirectory
} derive(Show, Eq, ToJson, Default)

///|
pub(all) struct OptionalHeader64 {
  magic : UInt16
  major_linker_version : Byte
  minor_linker_version : Byte
  size_of_code : UInt
  size_of_initialized_data : UInt
  size_of_uninitialized_data : UInt
  address_of_entry_point : UInt
  base_of_code : UInt
  image_base : Int64
  section_alignment : UInt
  file_alignment : UInt
  major_operating_system_version : UInt16
  minor_operating_system_version : UInt16
  major_image_version : UInt16
  minor_image_version : UInt16
  major_subsystem_version : UInt16
  minor_subsystem_version : UInt16
  win32_version_value : UInt
  size_of_image : UInt
  size_of_headers : UInt
  check_sum : UInt
  subsystem : UInt16
  dll_characteristics : UInt16
  size_of_stack_reserve : UInt64
  size_of_stack_commit : UInt64
  size_of_heap_reserve : UInt64
  size_of_heap_commit : UInt64
  loader_flags : UInt
  number_of_rva_and_sizes : UInt
  data_directory : FixedArray[DataDirectory] // [16]DataDirectory
} derive(Show, Eq, ToJson)

///|
pub const IMAGE_FILE_MACHINE_UNKNOWN : UInt16 = 0x0

///|
pub const IMAGE_FILE_MACHINE_AM33 : UInt16 = 0x1d3

///|
pub const IMAGE_FILE_MACHINE_AMD64 : UInt16 = 0x8664

///|
pub const IMAGE_FILE_MACHINE_ARM : UInt16 = 0x1c0

///|
pub const IMAGE_FILE_MACHINE_ARMNT : UInt16 = 0x1c4

///|
pub const IMAGE_FILE_MACHINE_ARM64 : UInt16 = 0xaa64

///|
pub const IMAGE_FILE_MACHINE_EBC : Int = 0xebc

///|
pub const IMAGE_FILE_MACHINE_I386 : UInt16 = 0x14c

///|
pub const IMAGE_FILE_MACHINE_IA64 : UInt16 = 0x200

///|
pub const IMAGE_FILE_MACHINE_LOONGARCH32 : Int = 0x6232

///|
pub const IMAGE_FILE_MACHINE_LOONGARCH64 : Int = 0x6264

///|
pub const IMAGE_FILE_MACHINE_M32R : Int = 0x9041

///|
pub const IMAGE_FILE_MACHINE_MIPS16 : Int = 0x266

///|
pub const IMAGE_FILE_MACHINE_MIPSFPU : Int = 0x366

///|
pub const IMAGE_FILE_MACHINE_MIPSFPU16 : Int = 0x466

///|
pub const IMAGE_FILE_MACHINE_POWERPC : Int = 0x1f0

///|
pub const IMAGE_FILE_MACHINE_POWERPCFP : Int = 0x1f1

///|
pub const IMAGE_FILE_MACHINE_R4000 : Int = 0x166

///|
pub const IMAGE_FILE_MACHINE_SH3 : Int = 0x1a2

///|
pub const IMAGE_FILE_MACHINE_SH3DSP : Int = 0x1a3

///|
pub const IMAGE_FILE_MACHINE_SH4 : Int = 0x1a6

///|
pub const IMAGE_FILE_MACHINE_SH5 : Int = 0x1a8

///|
pub const IMAGE_FILE_MACHINE_THUMB : Int = 0x1c2

///|
pub const IMAGE_FILE_MACHINE_WCEMIPSV2 : Int = 0x169

///|
pub const IMAGE_FILE_MACHINE_RISCV32 : UInt16 = 0x5032

///|
pub const IMAGE_FILE_MACHINE_RISCV64 : UInt16 = 0x5064

///|
pub const IMAGE_FILE_MACHINE_RISCV128 : UInt16 = 0x5128

///|
/// IMAGE_DIRECTORY_ENTRY constants
pub const IMAGE_DIRECTORY_ENTRY_EXPORT : Int = 0

///|
pub const IMAGE_DIRECTORY_ENTRY_IMPORT : Int = 1

///|
pub const IMAGE_DIRECTORY_ENTRY_RESOURCE : Int = 2

///|
pub const IMAGE_DIRECTORY_ENTRY_EXCEPTION : Int = 3

///|
pub const IMAGE_DIRECTORY_ENTRY_SECURITY : Int = 4

///|
pub const IMAGE_DIRECTORY_ENTRY_BASERELOC : Int = 5

///|
pub const IMAGE_DIRECTORY_ENTRY_DEBUG : Int = 6

///|
pub const IMAGE_DIRECTORY_ENTRY_ARCHITECTURE : Int = 7

///|
pub const IMAGE_DIRECTORY_ENTRY_GLOBALPTR : Int = 8

///|
pub const IMAGE_DIRECTORY_ENTRY_TLS : Int = 9

///|
pub const IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG : Int = 10

///|
pub const IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT : Int = 11

///|
pub const IMAGE_DIRECTORY_ENTRY_IAT : Int = 12

///|
pub const IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT : Int = 13

///|
pub const IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR : Int = 14

///|
/// Values of IMAGE_FILE_HEADER.Characteristics. These can be combined together.
pub const IMAGE_FILE_RELOCS_STRIPPED : Int = 0x0001

///|
pub const IMAGE_FILE_EXECUTABLE_IMAGE : Int = 0x0002

///|
pub const IMAGE_FILE_LINE_NUMS_STRIPPED : Int = 0x0004

///|
pub const IMAGE_FILE_LOCAL_SYMS_STRIPPED : Int = 0x0008

///|
pub const IMAGE_FILE_AGGRESIVE_WS_TRIM : Int = 0x0010

///|
pub const IMAGE_FILE_LARGE_ADDRESS_AWARE : Int = 0x0020

///|
pub const IMAGE_FILE_BYTES_REVERSED_LO : Int = 0x0080

///|
pub const IMAGE_FILE_32BIT_MACHINE : Int = 0x0100

///|
pub const IMAGE_FILE_DEBUG_STRIPPED : Int = 0x0200

///|
pub const IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP : Int = 0x0400

///|
pub const IMAGE_FILE_NET_RUN_FROM_SWAP : Int = 0x0800

///|
pub const IMAGE_FILE_SYSTEM : Int = 0x1000

///|
pub const IMAGE_FILE_DLL : Int = 0x2000

///|
pub const IMAGE_FILE_UP_SYSTEM_ONLY : Int = 0x4000

///|
pub const IMAGE_FILE_BYTES_REVERSED_HI : Int = 0x8000

///|
/// OptionalHeader64.Subsystem and OptionalHeader32.Subsystem values.
pub const IMAGE_SUBSYSTEM_UNKNOWN : Int = 0

///|
pub const IMAGE_SUBSYSTEM_NATIVE : Int = 1

///|
pub const IMAGE_SUBSYSTEM_WINDOWS_GUI : Int = 2

///|
pub const IMAGE_SUBSYSTEM_WINDOWS_CUI : Int = 3

///|
pub const IMAGE_SUBSYSTEM_OS2_CUI : Int = 5

///|
pub const IMAGE_SUBSYSTEM_POSIX_CUI : Int = 7

///|
pub const IMAGE_SUBSYSTEM_NATIVE_WINDOWS : Int = 8

///|
pub const IMAGE_SUBSYSTEM_WINDOWS_CE_GUI : Int = 9

///|
pub const IMAGE_SUBSYSTEM_EFI_APPLICATION : Int = 10

///|
pub const IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER : Int = 11

///|
pub const IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER : Int = 12

///|
pub const IMAGE_SUBSYSTEM_EFI_ROM : Int = 13

///|
pub const IMAGE_SUBSYSTEM_XBOX : Int = 14

///|
pub const IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION : Int = 16

///|
/// OptionalHeader64.DllCharacteristics and OptionalHeader32.DllCharacteristics
/// values. These can be combined together.
pub const IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA : Int = 0x0020

///|
pub const IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE : Int = 0x0040

///|
pub const IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY : Int = 0x0080

///|
pub const IMAGE_DLLCHARACTERISTICS_NX_COMPAT : Int = 0x0100

///|
pub const IMAGE_DLLCHARACTERISTICS_NO_ISOLATION : Int = 0x0200

///|
pub const IMAGE_DLLCHARACTERISTICS_NO_SEH : Int = 0x0400

///|
pub const IMAGE_DLLCHARACTERISTICS_NO_BIND : Int = 0x0800

///|
pub const IMAGE_DLLCHARACTERISTICS_APPCONTAINER : Int = 0x1000

///|
pub const IMAGE_DLLCHARACTERISTICS_WDM_DRIVER : Int = 0x2000

///|
pub const IMAGE_DLLCHARACTERISTICS_GUARD_CF : Int = 0x4000

///|
pub const IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE : Int = 0x8000
