/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
pub(all) struct FileHeader {
  machine : Int
  number_of_sections : Int
  time_date_stamp : Int64
  pointer_to_symbol_table : Int64
  number_of_symbols : Int64
  size_of_optional_header : Int
  characteristics : Int
} derive(Show, Eq, ToJson)

///|
pub(all) struct DataDirectory {
  virtual_address : Int
  size : Int
} derive(Show, Eq, ToJson)

///|
pub(all) struct OptionalHeader32 {
  magic : UInt16
  major_linker_version : Byte
  minor_linker_version : Byte
  size_of_code : Int
  size_of_initialized_data : Int
  size_of_uninitialized_data : Int
  address_of_entry_point : Int
  base_of_code : Int
  base_of_data : Int
  image_base : Int
  section_alignment : Int
  file_alignment : Int
  major_operating_system_version : Int16
  minor_operating_system_version : Int16
  major_image_version : Int16
  minor_image_version : Int16
  major_subsystem_version : Int16
  minor_subsystem_version : Int16
  win32_version_value : Int
  size_of_image : Int
  size_of_headers : Int
  check_sum : Int
  subsystem : Int16
  dll_characteristics : Int16
  size_of_stack_reserve : Int
  size_of_stack_commit : Int
  size_of_heap_reserve : Int
  size_of_heap_commit : Int
  loader_flags : Int
  number_of_rva_and_sizes : Int
  data_directory : FixedArray[DataDirectory] // [16]DataDirectory
} derive(Show, Eq, ToJson, Default)

///|
pub(all) struct OptionalHeader64 {
  magic : Int
  major_linker_version : Int
  minor_linker_version : Int
  size_of_code : Int64
  size_of_initialized_data : Int64
  size_of_uninitialized_data : Int64
  address_of_entry_point : Int64
  base_of_code : Int64
  image_base : Int64
  section_alignment : Int64
  file_alignment : Int64
  major_operating_system_version : Int
  minor_operating_system_version : Int
  major_image_version : Int
  minor_image_version : Int
  major_subsystem_version : Int
  minor_subsystem_version : Int
  win32_version_value : Int64
  size_of_image : Int64
  size_of_headers : Int64
  check_sum : Int64
  subsystem : Int
  dll_characteristics : Int
  size_of_stack_reserve : Int64
  size_of_stack_commit : Int64
  size_of_heap_reserve : Int64
  size_of_heap_commit : Int64
  loader_flags : Int64
  number_of_rva_and_sizes : Int64
  data_directory : FixedArray[DataDirectory] // [16]DataDirectory
} derive(Show, Eq, ToJson)

///|
pub const IMAGE_FILE_MACHINE_UNKNOWN : Int = 0x0

///|
pub const IMAGE_FILE_MACHINE_AM33 : Int = 0x1d3

///|
pub const IMAGE_FILE_MACHINE_AMD64 : Int = 0x8664

///|
pub const IMAGE_FILE_MACHINE_ARM : Int = 0x1c0

///|
pub const IMAGE_FILE_MACHINE_ARMNT : Int = 0x1c4

///|
pub const IMAGE_FILE_MACHINE_ARM64 : Int = 0xaa64

///|
pub const IMAGE_FILE_MACHINE_EBC : Int = 0xebc

///|
pub const IMAGE_FILE_MACHINE_I386 : Int = 0x14c

///|
pub const IMAGE_FILE_MACHINE_IA64 : Int = 0x200

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
pub const IMAGE_FILE_MACHINE_RISCV32 : Int = 0x5032

///|
pub const IMAGE_FILE_MACHINE_RISCV64 : Int = 0x5064

///|
pub const IMAGE_FILE_MACHINE_RISCV128 : Int = 0x5128

///|
/// IMAGE_DIRECTORY_ENTRY constants
pub const IMAGE_DIRECTORY_ENTRY_EXPORT : Int64 = 0

///|
pub const IMAGE_DIRECTORY_ENTRY_IMPORT : Int64 = 1

///|
pub const IMAGE_DIRECTORY_ENTRY_RESOURCE : Int64 = 2

///|
pub const IMAGE_DIRECTORY_ENTRY_EXCEPTION : Int64 = 3

///|
pub const IMAGE_DIRECTORY_ENTRY_SECURITY : Int64 = 4

///|
pub const IMAGE_DIRECTORY_ENTRY_BASERELOC : Int64 = 5

///|
pub const IMAGE_DIRECTORY_ENTRY_DEBUG : Int64 = 6

///|
pub const IMAGE_DIRECTORY_ENTRY_ARCHITECTURE : Int64 = 7

///|
pub const IMAGE_DIRECTORY_ENTRY_GLOBALPTR : Int64 = 8

///|
pub const IMAGE_DIRECTORY_ENTRY_TLS : Int64 = 9

///|
pub const IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG : Int64 = 10

///|
pub const IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT : Int64 = 11

///|
pub const IMAGE_DIRECTORY_ENTRY_IAT : Int64 = 12

///|
pub const IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT : Int64 = 13

///|
pub const IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR : Int64 = 14

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
