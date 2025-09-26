/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
test "names" {
  inspect(@elf.ELFOSABI_LINUX, content="ELFOSABI_LINUX")
  inspect(@elf.ET_EXEC, content="ET_EXEC")
  inspect(@elf.SHT_PROGBITS, content="SHT_PROGBITS")
  inspect(@elf.EM_860, content="EM_860")
  inspect(@elf.SHN_LOPROC, content="SHN_LOPROC")
  inspect(@elf.SHT_PROGBITS, content="SHT_PROGBITS")
  inspect(@elf.shfMerge + @elf.shfTls, content="1040")
  inspect(@elf.PT_LOAD, content="PT_LOAD")
  inspect(@elf.progFlagWrite + @elf.progFlagRead + 0x50, content="86")
  inspect(@elf.DT_SYMBOLIC, content="DT_SYMBOLIC")
  inspect(@elf.dfBindNow, content="DF_BIND_NOW")
  inspect(@elf.df1Pie, content="DF_1_PIE")
  // inspect(@elf.NT_FPREGSET, "NT_FPREGSET")
  // inspect(@elf.STB_GLOBAL, "STB_GLOBAL")
  // inspect(@elf.STT_COMMON, "STT_COMMON")
  // inspect(@elf.STV_HIDDEN, "STV_HIDDEN")
  // inspect(@elf.R_X86_64_PC32, "R_X86_64_PC32")
  // inspect(@elf.R_ALPHA_OP_PUSH, "R_ALPHA_OP_PUSH")
  // inspect(@elf.R_ARM_THM_ABS5, "R_ARM_THM_ABS5")
  // inspect(@elf.R_386_GOT32, "R_386_GOT32")
  // inspect(@elf.R_PPC_GOT16_HI, "R_PPC_GOT16_HI")
  // inspect(@elf.R_SPARC_GOT22, "R_SPARC_GOT22")
  // inspect(@elf.ET_LOOS + 5, "ET_LOOS+5")
  // inspect(@elf.ProgFlag(0x50), "0x50")
  // inspect(@elf.COMPRESS_ZLIB + 2, "COMPRESS_ZSTD+1")
}
