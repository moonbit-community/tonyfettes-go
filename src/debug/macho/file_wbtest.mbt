// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

///|
priv struct FileTest {
  file : String
  hdr : FileHeader
  loads : Array[SegmentHeader?]
  sections : Array[SectionHeader]
  relocations : Map[String, Array[Reloc]]
  imported_symbols : Array[String]
} derive(Show)

///|
let file_tests : FixedArray[FileTest] = [
  {
    file: "testdata/gcc-386-darwin-exec.base64",
    hdr: {
      magic: 0xfeedface,
      cpu: I386,
      sub_cpu: 0x3,
      type_: Exec,
      ncmd: 0xc,
      cmdsz: 0x3c0,
      flags: 0x85,
    },
    loads: [
      Some({
        cmd: Segment,
        len: 0x38,
        name: "__PAGEZERO",
        addr: 0x0,
        memsz: 0x1000,
        offset: 0x0,
        filesz: 0x0,
        maxprot: 0x0,
        prot: 0x0,
        nsect: 0x0,
        flag: 0x0,
      }),
      Some({
        cmd: Segment,
        len: 0xc0,
        name: "__TEXT",
        addr: 0x1000,
        memsz: 0x1000,
        offset: 0x0,
        filesz: 0x1000,
        maxprot: 0x7,
        prot: 0x5,
        nsect: 0x2,
        flag: 0x0,
      }),
      Some({
        cmd: Segment,
        len: 0xc0,
        name: "__DATA",
        addr: 0x2000,
        memsz: 0x1000,
        offset: 0x1000,
        filesz: 0x1000,
        maxprot: 0x7,
        prot: 0x3,
        nsect: 0x2,
        flag: 0x0,
      }),
      Some({
        cmd: Segment,
        len: 0x7c,
        name: "__IMPORT",
        addr: 0x3000,
        memsz: 0x1000,
        offset: 0x2000,
        filesz: 0x1000,
        maxprot: 0x7,
        prot: 0x7,
        nsect: 0x1,
        flag: 0x0,
      }),
      Some({
        cmd: Segment,
        len: 0x38,
        name: "__LINKEDIT",
        addr: 0x4000,
        memsz: 0x1000,
        offset: 0x3000,
        filesz: 0x12c,
        maxprot: 0x7,
        prot: 0x1,
        nsect: 0x0,
        flag: 0x0,
      }),
      None, // LC_SYMTAB
      None, // LC_DYSYMTAB
      None, // LC_LOAD_DYLINKER
      None, // LC_UUID
      None, // LC_UNIXTHREAD
      None, // Dylib("/usr/lib/libgcc_s.1.dylib", 0x2, 0x10000, 0x10000)
      None, // Dylib("/usr/lib/libSystem.B.dylib", 0x2, 0x6f0104, 0x10000)
    ],
    sections: [
      {
        name: "__text",
        seg: "__TEXT",
        addr: 0x1f68,
        size: 0x88,
        offset: 0xf68,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x80000400,
      },
      {
        name: "__cstring",
        seg: "__TEXT",
        addr: 0x1ff0,
        size: 0xd,
        offset: 0xff0,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x2,
      },
      {
        name: "__data",
        seg: "__DATA",
        addr: 0x2000,
        size: 0x14,
        offset: 0x1000,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__dyld",
        seg: "__DATA",
        addr: 0x2014,
        size: 0x1c,
        offset: 0x1014,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__jump_table",
        seg: "__IMPORT",
        addr: 0x3000,
        size: 0xa,
        offset: 0x2000,
        align: 0x6,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x4000008,
      },
    ],
    relocations: {},
    imported_symbols: [],
  },
  {
    file: "testdata/gcc-amd64-darwin-exec.base64",
    hdr: {
      magic: 0xfeedfacf,
      cpu: Amd64,
      sub_cpu: 0x80000003,
      type_: Exec,
      ncmd: 0xb,
      cmdsz: 0x568,
      flags: 0x85,
    },
    loads: [
      Some({
        cmd: Segment64,
        len: 0x48,
        name: "__PAGEZERO",
        addr: 0x0,
        memsz: 0x100000000,
        offset: 0x0,
        filesz: 0x0,
        maxprot: 0x0,
        prot: 0x0,
        nsect: 0x0,
        flag: 0x0,
      }),
      Some({
        cmd: Segment64,
        len: 0x1d8,
        name: "__TEXT",
        addr: 0x100000000,
        memsz: 0x1000,
        offset: 0x0,
        filesz: 0x1000,
        maxprot: 0x7,
        prot: 0x5,
        nsect: 0x5,
        flag: 0x0,
      }),
      Some({
        cmd: Segment64,
        len: 0x138,
        name: "__DATA",
        addr: 0x100001000,
        memsz: 0x1000,
        offset: 0x1000,
        filesz: 0x1000,
        maxprot: 0x7,
        prot: 0x3,
        nsect: 0x3,
        flag: 0x0,
      }),
      Some({
        cmd: Segment64,
        len: 0x48,
        name: "__LINKEDIT",
        addr: 0x100002000,
        memsz: 0x1000,
        offset: 0x2000,
        filesz: 0x140,
        maxprot: 0x7,
        prot: 0x1,
        nsect: 0x0,
        flag: 0x0,
      }),
      None, // LC_SYMTAB
      None, // LC_DYSYMTAB
      None, // LC_LOAD_DYLINKER
      None, // LC_UUID
      None, // LC_UNIXTHREAD
      None, // Dylib("/usr/lib/libgcc_s.1.dylib", 0x2, 0x10000, 0x10000)
      None, // Dylib("/usr/lib/libSystem.B.dylib", 0x2, 0x6f0104, 0x10000)
    ],
    sections: [
      {
        name: "__text",
        seg: "__TEXT",
        addr: 0x100000f14,
        size: 0x6d,
        offset: 0xf14,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x80000400,
      },
      {
        name: "__symbol_stub1",
        seg: "__TEXT",
        addr: 0x100000f81,
        size: 0xc,
        offset: 0xf81,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x80000408,
      },
      {
        name: "__stub_helper",
        seg: "__TEXT",
        addr: 0x100000f90,
        size: 0x18,
        offset: 0xf90,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__cstring",
        seg: "__TEXT",
        addr: 0x100000fa8,
        size: 0xd,
        offset: 0xfa8,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x2,
      },
      {
        name: "__eh_frame",
        seg: "__TEXT",
        addr: 0x100000fb8,
        size: 0x48,
        offset: 0xfb8,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x6000000b,
      },
      {
        name: "__data",
        seg: "__DATA",
        addr: 0x100001000,
        size: 0x1c,
        offset: 0x1000,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__dyld",
        seg: "__DATA",
        addr: 0x100001020,
        size: 0x38,
        offset: 0x1020,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__la_symbol_ptr",
        seg: "__DATA",
        addr: 0x100001058,
        size: 0x10,
        offset: 0x1058,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x7,
      },
    ],
    relocations: {},
    imported_symbols: [],
  },
  {
    file: "testdata/gcc-amd64-darwin-exec-debug.base64",
    hdr: {
      magic: 0xfeedfacf,
      cpu: Amd64,
      sub_cpu: 0x80000003,
      type_: Obj,
      ncmd: 0x4,
      cmdsz: 0x5a0,
      flags: 0,
    },
    loads: [
      None, // LC_UUID
      Some({
        cmd: Segment64,
        len: 0x1d8,
        name: "__TEXT",
        addr: 0x100000000,
        memsz: 0x1000,
        offset: 0x0,
        filesz: 0x0,
        maxprot: 0x7,
        prot: 0x5,
        nsect: 0x5,
        flag: 0x0,
      }),
      Some({
        cmd: Segment64,
        len: 0x138,
        name: "__DATA",
        addr: 0x100001000,
        memsz: 0x1000,
        offset: 0x0,
        filesz: 0x0,
        maxprot: 0x7,
        prot: 0x3,
        nsect: 0x3,
        flag: 0x0,
      }),
      Some({
        cmd: Segment64,
        len: 0x278,
        name: "__DWARF",
        addr: 0x100002000,
        memsz: 0x1000,
        offset: 0x1000,
        filesz: 0x1bc,
        maxprot: 0x7,
        prot: 0x3,
        nsect: 0x7,
        flag: 0x0,
      }),
    ],
    sections: [
      {
        name: "__text",
        seg: "__TEXT",
        addr: 0x100000f14,
        size: 0x0,
        offset: 0x0,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x80000400,
      },
      {
        name: "__symbol_stub1",
        seg: "__TEXT",
        addr: 0x100000f81,
        size: 0x0,
        offset: 0x0,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x80000408,
      },
      {
        name: "__stub_helper",
        seg: "__TEXT",
        addr: 0x100000f90,
        size: 0x0,
        offset: 0x0,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__cstring",
        seg: "__TEXT",
        addr: 0x100000fa8,
        size: 0x0,
        offset: 0x0,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x2,
      },
      {
        name: "__eh_frame",
        seg: "__TEXT",
        addr: 0x100000fb8,
        size: 0x0,
        offset: 0x0,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x6000000b,
      },
      {
        name: "__data",
        seg: "__DATA",
        addr: 0x100001000,
        size: 0x0,
        offset: 0x0,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__dyld",
        seg: "__DATA",
        addr: 0x100001020,
        size: 0x0,
        offset: 0x0,
        align: 0x3,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__la_symbol_ptr",
        seg: "__DATA",
        addr: 0x100001058,
        size: 0x0,
        offset: 0x0,
        align: 0x2,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x7,
      },
      {
        name: "__debug_abbrev",
        seg: "__DWARF",
        addr: 0x100002000,
        size: 0x36,
        offset: 0x1000,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_aranges",
        seg: "__DWARF",
        addr: 0x100002036,
        size: 0x30,
        offset: 0x1036,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_frame",
        seg: "__DWARF",
        addr: 0x100002066,
        size: 0x40,
        offset: 0x1066,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_info",
        seg: "__DWARF",
        addr: 0x1000020a6,
        size: 0x54,
        offset: 0x10a6,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_line",
        seg: "__DWARF",
        addr: 0x1000020fa,
        size: 0x47,
        offset: 0x10fa,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_pubnames",
        seg: "__DWARF",
        addr: 0x100002141,
        size: 0x1b,
        offset: 0x1141,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
      {
        name: "__debug_str",
        seg: "__DWARF",
        addr: 0x10000215c,
        size: 0x60,
        offset: 0x115c,
        align: 0x0,
        reloff: 0x0,
        nreloc: 0x0,
        flags: 0x0,
      },
    ],
    relocations: {},
    imported_symbols: [],
  },
  {
    file: "testdata/clang-386-darwin-exec-with-rpath.base64",
    hdr: {
      magic: 0xfeedface,
      cpu: I386,
      sub_cpu: 0x3,
      type_: Exec,
      ncmd: 0x10,
      cmdsz: 0x42c,
      flags: 0x1200085,
    },
    loads: [
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_DYLD_INFO_ONLY
      None, // LC_SYMTAB
      None, // LC_DYSYMTAB
      None, // LC_LOAD_DYLINKER
      None, // LC_UUID
      None, // LC_VERSION_MIN_MACOSX
      None, // LC_SOURCE_VERSION
      None, // LC_MAIN
      None, // LC_LOAD_DYLIB
      None, // Rpath("/my/rpath")
      None, // LC_FUNCTION_STARTS
      None, // LC_DATA_IN_CODE
    ],
    sections: [],
    relocations: {},
    imported_symbols: [],
  },
  {
    file: "testdata/clang-amd64-darwin-exec-with-rpath.base64",
    hdr: {
      magic: 0xfeedfacf,
      cpu: Amd64,
      sub_cpu: 0x80000003,
      type_: Exec,
      ncmd: 0x10,
      cmdsz: 0x4c8,
      flags: 0x200085,
    },
    loads: [
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_SEGMENT
      None, // LC_DYLD_INFO_ONLY
      None, // LC_SYMTAB
      None, // LC_DYSYMTAB
      None, // LC_LOAD_DYLINKER
      None, // LC_UUID
      None, // LC_VERSION_MIN_MACOSX
      None, // LC_SOURCE_VERSION
      None, // LC_MAIN
      None, // LC_LOAD_DYLIB
      None, // Rpath("/my/rpath")
      None, // LC_FUNCTION_STARTS
      None, // LC_DATA_IN_CODE
    ],
    sections: [],
    relocations: {},
    imported_symbols: [],
  },
  {
    file: "testdata/clang-386-darwin.obj.base64",
    hdr: {
      magic: 0xfeedface,
      cpu: I386,
      sub_cpu: 0x3,
      type_: Obj,
      ncmd: 0x4,
      cmdsz: 0x138,
      flags: 0x2000,
    },
    loads: [],
    sections: [],
    relocations: {
      "__text": [
        {
          addr: 0x1d,
          value: 1,
          type_: 0, // GENERIC_RELOC_VANILLA
          len: 2,
          pcrel: true,
          is_extern: true,
          scattered: false,
        },
        {
          addr: 0xe,
          value: 0x2d,
          type_: 1, // GENERIC_RELOC_LOCAL_SECTDIFF
          len: 2,
          pcrel: false,
          is_extern: false,
          scattered: true,
        },
        {
          addr: 0x0,
          value: 0xb,
          type_: 5, // GENERIC_RELOC_PAIR
          len: 2,
          pcrel: false,
          is_extern: false,
          scattered: true,
        },
      ],
    },
    imported_symbols: [],
  },
  {
    file: "testdata/clang-amd64-darwin.obj.base64",
    hdr: {
      magic: 0xfeedfacf,
      cpu: Amd64,
      sub_cpu: 0x3,
      type_: Obj,
      ncmd: 0x4,
      cmdsz: 0x200,
      flags: 0x2000,
    },
    loads: [],
    sections: [],
    relocations: {
      "__text": [
        {
          addr: 0x19,
          value: 1,
          type_: 2, // X86_64_RELOC_BRANCH
          len: 2,
          pcrel: true,
          is_extern: true,
          scattered: false,
        },
        {
          addr: 0xb,
          value: 2,
          type_: 1, // X86_64_RELOC_SIGNED
          len: 2,
          pcrel: true,
          is_extern: false,
          scattered: false,
        },
      ],
      "__compact_unwind": [
        {
          addr: 0x0,
          value: 1,
          type_: 0, // X86_64_RELOC_UNSIGNED
          len: 3,
          pcrel: false,
          is_extern: false,
          scattered: false,
        },
      ],
    },
    imported_symbols: ["_printf"],
  },
  {
    file: "testdata/clang-amd64-darwin-ld-r.obj.base64",
    hdr: {
      magic: 0xfeedfacf,
      cpu: Amd64,
      sub_cpu: 0x3,
      type_: Obj,
      ncmd: 0x4,
      cmdsz: 0x1c0,
      flags: 0x2000,
    },
    loads: [],
    sections: [],
    relocations: {},
    imported_symbols: ["_printf"],
  },
]

///|
fn reader_at_from_obscured(name : String) -> &@io.ReaderAt raise {
  let b = @obscuretestdata.read_file(name)
  return @bytes.new_reader(b)
}

///|
fn open_obscured(name : String) -> File raise {
  let ra = reader_at_from_obscured(name)
  let ff = new_file(ra)
  ff
}

///|
test "open" {
  for tt in file_tests {
    let f = open_obscured("src/debug/macho/" + tt.file)
    assert_eq(f.header, tt.hdr)
  }
}
