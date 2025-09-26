/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// Translated from Go's debug/elf package file_test.go

///|
/// Test structure for ELF file testing
priv struct FileTest {
  file : String
  hdr : FileHeader
  sections : Array[SectionHeader]
  progs : Array[ProgHeader]
  needed : Array[String]
  symbols : Array[Symbol]?
} derive(Show, ToJson)

///|
let file_tests : Array[FileTest] = [
  // 32-bit FreeBSD executable
  {
    file: "testdata/gcc-386-freebsd-exec",
    hdr: {
      class: ELFCLASS32,
      data: ELFDATA2LSB,
      version: EV_CURRENT,
      osabi: ELFOSABI_FREEBSD,
      abi_version: 0,
      byte_order: @binary.little_endian,
      type_: ET_EXEC,
      machine: EM_386,
      entry: 0x80483cc,
    },
    sections: [
      {
        name: "",
        type_: SHT_NULL,
        flags: SectionFlag(0x0),
        addr: 0x0,
        offset: 0x0,
        size: 0x0,
        link: 0x0,
        info: 0x0,
        addralign: 0x0,
        entsize: 0x0,
        file_size: 0x0,
      },
      {
        name: ".interp",
        type_: SHT_PROGBITS,
        flags: shfAlloc,
        addr: 0x80480d4,
        offset: 0xd4,
        size: 0x15,
        link: 0x0,
        info: 0x0,
        addralign: 0x1,
        entsize: 0x0,
        file_size: 0x15,
      },
      {
        name: ".hash",
        type_: SHT_HASH,
        flags: shfAlloc,
        addr: 0x80480ec,
        offset: 0xec,
        size: 0x90,
        link: 0x3,
        info: 0x0,
        addralign: 0x4,
        entsize: 0x4,
        file_size: 0x90,
      },
    ],
    progs: [
      // Add more sections as needed...
      {
        type_: PT_PHDR,
        flags: progFlagRead | progFlagExec,
        off: 0x34,
        vaddr: 0x8048034,
        paddr: 0x8048034,
        filesz: 0xa0,
        memsz: 0xa0,
        align: 0x4,
      },
      {
        type_: PT_INTERP,
        flags: progFlagRead,
        off: 0xd4,
        vaddr: 0x80480d4,
        paddr: 0x80480d4,
        filesz: 0x15,
        memsz: 0x15,
        align: 0x1,
      },
      // Add more program headers as needed...
    ],
    needed: ["libc.so.6"],
    symbols: Some([
      {
        name: "",
        info: 3,
        other: 0,
        has_version: false,
        version_index: VersionIndex::new(0),
        section: SectionIndex::from_int(1),
        value: 134512852,
        size: 0,
        version: "",
        library: "",
      },
      // Add more symbols as needed...
    ]),
  },
]

///|
/// Test opening and parsing ELF files
test "file open and parse" {
  // Test basic ELF constants work
  @json.inspect(ELFMAG.to_array(), content=[127, 69, 76, 70])
  @json.inspect(EI_CLASS, content=4)
  @json.inspect(EI_DATA, content=5)

  // Test enum conversions
  @json.inspect(Class::ELFCLASS32.to_int(), content=1)
  @json.inspect(Data::ELFDATA2LSB.to_byte(), content=1)
  @json.inspect(Version::EV_CURRENT.to_byte(), content=1)
  @json.inspect(Type::ET_EXEC.to_uint16(), content=2)
  @json.inspect(Machine::EM_386.to_int(), content=3)
}

///|
/// Test section header structure
test "section header structure" {
  let sh : SectionHeader = {
    name: ".text",
    type_: SHT_PROGBITS,
    flags: shfAlloc | shfExecInstr,
    addr: 0x1000,
    offset: 0x200,
    size: 0x100,
    link: 0,
    info: 0,
    addralign: 4,
    entsize: 0,
    file_size: 0x100,
  }
  @json.inspect(sh.name, content=".text")
  @json.inspect(sh.type_, content="SHT_PROGBITS")
  @json.inspect(sh.flags.0, content=6) // SHF_ALLOC | SHF_EXECINSTR = 2 | 4 = 6
  @json.inspect(sh.addr, content="4096")
  @json.inspect(sh.size, content="256")
}

///|
/// Test program header structure
test "program header structure" {
  let ph : ProgHeader = {
    type_: PT_LOAD,
    flags: progFlagRead | progFlagExec,
    off: 0x0,
    vaddr: 0x8048000,
    paddr: 0x8048000,
    filesz: 0x5fb,
    memsz: 0x5fb,
    align: 0x1000,
  }
  @json.inspect(ph.type_, content="PT_LOAD")
  @json.inspect(ph.flags, content=5) // PF_R | PF_X = 4 | 1 = 5
  @json.inspect(ph.vaddr, content="134512640")
  @json.inspect(ph.align, content="4096")
}

///|
/// Test symbol structure
test "symbol structure" {
  let sym : Symbol = {
    name: "main",
    info: 18, // STT_FUNC | (STB_GLOBAL << 4) = 2 | (1 << 4) = 18
    other: 0,
    has_version: false,
    version_index: VersionIndex::new(0),
    section: SectionIndex::from_int(8),
    value: 0x8048498,
    size: 27,
    version: "",
    library: "",
  }
  @json.inspect(sym.name, content="main")
  @json.inspect(sym.info, content=18)
  @json.inspect(sym.value, content="134513816")
  @json.inspect(sym.size, content="27")
}

///|
/// Test file header structure
test "file header structure" {
  let fh : FileHeader = {
    class: ELFCLASS64,
    data: ELFDATA2LSB,
    version: EV_CURRENT,
    osabi: ELFOSABI_NONE,
    abi_version: 0,
    byte_order: @binary.little_endian,
    type_: ET_EXEC,
    machine: EM_X86_64,
    entry: 0x4003e0,
  }
  @json.inspect(fh.class, content="ELFCLASS64")
  @json.inspect(fh.data, content="ELFDATA2LSB")
  @json.inspect(fh.version, content="EV_CURRENT")
  @json.inspect(fh.type_, content="ET_EXEC")
  @json.inspect(fh.machine, content="EM_X86_64")
  @json.inspect(fh.entry, content="4195296")
}

///|
/// Test version index operations
test "version index operations" {
  let vi_hidden = VersionIndex::new(0x8001)
  @json.inspect(vi_hidden.is_hidden(), content=true)
  @json.inspect(vi_hidden.index(), content=1)
  let vi_normal = VersionIndex::new(0x0002)
  @json.inspect(vi_normal.is_hidden(), content=false)
  @json.inspect(vi_normal.index(), content=2)
}

///|
/// Test section types and flags
test "section types and flags" {
  @json.inspect(SectionType::SHT_NULL.to_uint(), content=0)
  @json.inspect(SectionType::SHT_PROGBITS.to_uint(), content=1)
  @json.inspect(SectionType::SHT_SYMTAB.to_uint(), content=2)
  @json.inspect(SectionType::SHT_STRTAB.to_uint(), content=3)
  @json.inspect(shfWrite, content=1)
  @json.inspect(shfAlloc, content=2)
  @json.inspect(shfExecInstr, content=4)
  @json.inspect(shfMerge | shfStrings, content=48) // 0x10 | 0x20 = 48
}

///|
/// Test program types and flags
test "program types and flags" {
  @json.inspect(ProgType::PT_NULL.to_int(), content=0)
  @json.inspect(ProgType::PT_LOAD.to_int(), content=1)
  @json.inspect(ProgType::PT_DYNAMIC.to_int(), content=2)
  @json.inspect(ProgType::PT_INTERP.to_int(), content=3)
  @json.inspect(progFlagExec, content=1)
  @json.inspect(progFlagWrite, content=2)
  @json.inspect(progFlagRead, content=4)
}

///|
/// Test machine types
test "machine types" {
  @json.inspect(Machine::EM_NONE.to_int(), content=0)
  @json.inspect(Machine::EM_386.to_int(), content=3)
  @json.inspect(Machine::EM_X86_64.to_int(), content=62)
  @json.inspect(Machine::EM_ARM.to_int(), content=40)
  @json.inspect(Machine::EM_AARCH64.to_int(), content=183)
}

///|
/// Test ELF types
test "elf types" {
  @json.inspect(Type::ET_NONE.to_uint16(), content=0)
  @json.inspect(Type::ET_REL.to_uint16(), content=1)
  @json.inspect(Type::ET_EXEC.to_uint16(), content=2)
  @json.inspect(Type::ET_DYN.to_uint16(), content=3)
  @json.inspect(Type::ET_CORE.to_uint16(), content=4)
}

///|
/// Test imported symbol structure
test "imported symbol structure" {
  let imported : ImportedSymbol = {
    name: "printf",
    version: "GLIBC_2.2.5",
    library: "libc.so.6",
  }
  @json.inspect(imported.name, content="printf")
  @json.inspect(imported.version, content="GLIBC_2.2.5")
  @json.inspect(imported.library, content="libc.so.6")
}

///|
/// Test DynTag values
test "dynamic tag values" {
  @json.inspect(DynTag::DT_NULL.to_int(), content=0)
  @json.inspect(DynTag::DT_NEEDED.to_int(), content=1)
  @json.inspect(DynTag::DT_PLTRELSZ.to_int(), content=2)
  @json.inspect(DynTag::DT_PLTGOT.to_int(), content=3)
  @json.inspect(DynTag::DT_HASH.to_int(), content=4)
  @json.inspect(DynTag::DT_STRTAB.to_int(), content=5)
  @json.inspect(DynTag::DT_SYMTAB.to_int(), content=6)
  @json.inspect(DynTag::DT_RELA.to_int(), content=7)
}

///|
test "dyn_value" {
  let testdata = "testdata/gcc-amd64-linux-exec"
  let f = open(testdata)
  let vals = f.dyn_value(DT_VERNEEDNUM)
  @json.inspect(vals)
}
