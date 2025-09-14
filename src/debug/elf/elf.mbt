///|
/// Package elf implements access to ELF object files.
///
/// # Security
///
/// This package is not designed to be hardened against adversarial inputs, and is
/// outside the scope of https://go.dev/security/policy. In particular, only basic
/// validation is done when parsing object files. As such, care should be taken when
/// parsing untrusted inputs, as parsing malformed files may consume significant
/// resources, or cause panics.

///|
/// Constants

/// Indexes into the Header.Ident array.

///|
/// Class of machine.
pub const EI_CLASS : Int = 4

///|
/// Data format.
pub const EI_DATA : Int = 5

///|
/// ELF format version.
pub const EI_VERSION : Int = 6

///|
/// Operating system / ABI identification
pub const EI_OSABI : Int = 7

///|
/// ABI version
pub const EI_ABIVERSION : Int = 8

///|
/// Start of padding (per SVR4 ABI).
pub const EI_PAD : Int = 9

///|
/// Size of e_ident array.
pub const EI_NIDENT : Int = 16

///|
/// Initial magic number for ELF files.
pub const ELFMAG : Bytes = "\x7FELF"

///|
/// Version is found in Header.Ident[EI_VERSION] and Header.Version.
pub(all) enum Version {
  /// 0
  EV_NONE
  /// 1
  EV_CURRENT
} derive(Eq, Show, ToJson)

///|
pub fn Version::to_byte(self : Version) -> Byte {
  match self {
    EV_NONE => 0
    EV_CURRENT => 1
  }
}

///|
pub fn Version::from_byte(i : Byte) -> Version {
  match i {
    0 => EV_NONE
    1 => EV_CURRENT
    _ => EV_NONE // Default case
  }
}

///|
/// Class is found in Header.Ident[EI_CLASS] and Header.Class.
pub(all) enum Class {
  /// 0 Unknown class.
  ELFCLASSNONE
  /// 1 32-bit architecture.
  ELFCLASS32
  /// 2 64-bit architecture.
  ELFCLASS64
} derive(Eq, Show, ToJson)

///|
pub fn Class::to_int(self : Class) -> Int {
  match self {
    ELFCLASSNONE => 0
    ELFCLASS32 => 1
    ELFCLASS64 => 2
  }
}

///|
pub fn Class::from_int(i : Int) -> Class {
  match i {
    0 => ELFCLASSNONE
    1 => ELFCLASS32
    2 => ELFCLASS64
    _ => ELFCLASSNONE
  }
}

///|
/// Data is found in Header.Ident[EI_DATA] and Header.Data.
pub(all) enum Data {
  /// 0 Unknown data format.
  ELFDATANONE
  /// 1 2's complement little-endian.
  ELFDATA2LSB
  /// 2 2's complement big-endian.
  ELFDATA2MSB
} derive(Eq, Show, ToJson)

///|
pub fn Data::to_byte(self : Data) -> Byte {
  match self {
    ELFDATANONE => 0
    ELFDATA2LSB => 1
    ELFDATA2MSB => 2
  }
}

///|
pub fn Data::from_byte(b : Byte) -> Data {
  match b {
    0 => ELFDATANONE
    1 => ELFDATA2LSB
    2 => ELFDATA2MSB
    _ => ELFDATANONE
  }
}

///|
/// OSABI is found in Header.Ident[EI_OSABI] and Header.OSABI.
pub(all) enum OSABI {
  /// 0   UNIX System V ABI
  ELFOSABI_NONE
  /// 1   HP-UX operating system
  ELFOSABI_HPUX
  /// 2   NetBSD
  ELFOSABI_NETBSD
  /// 3   Linux
  ELFOSABI_LINUX
  /// 4   Hurd
  ELFOSABI_HURD
  /// 5   86Open common IA32 ABI
  ELFOSABI_86OPEN
  /// 6   Solaris
  ELFOSABI_SOLARIS
  /// 7   AIX
  ELFOSABI_AIX
  /// 8   IRIX
  ELFOSABI_IRIX
  /// 9   FreeBSD
  ELFOSABI_FREEBSD
  /// 10  TRU64 UNIX
  ELFOSABI_TRU64
  /// 11  Novell Modesto
  ELFOSABI_MODESTO
  /// 12  OpenBSD
  ELFOSABI_OPENBSD
  /// 13  Open VMS
  ELFOSABI_OPENVMS
  /// 14  HP Non-Stop Kernel
  ELFOSABI_NSK
  /// 15  Amiga Research OS
  ELFOSABI_AROS
  /// 16  The FenixOS highly scalable multi-core OS
  ELFOSABI_FENIXOS
  /// 17  Nuxi CloudABI
  ELFOSABI_CLOUDABI
  /// 97  ARM
  ELFOSABI_ARM
  /// 255 Standalone (embedded) application
  ELFOSABI_STANDALONE
} derive(Eq, Show, ToJson)

///|
pub impl Default for OSABI with default() {
  ELFOSABI_NONE
}

///|
pub fn OSABI::to_byte(self : OSABI) -> Byte {
  match self {
    ELFOSABI_NONE => 0
    ELFOSABI_HPUX => 1
    ELFOSABI_NETBSD => 2
    ELFOSABI_LINUX => 3
    ELFOSABI_HURD => 4
    ELFOSABI_86OPEN => 5
    ELFOSABI_SOLARIS => 6
    ELFOSABI_AIX => 7
    ELFOSABI_IRIX => 8
    ELFOSABI_FREEBSD => 9
    ELFOSABI_TRU64 => 10
    ELFOSABI_MODESTO => 11
    ELFOSABI_OPENBSD => 12
    ELFOSABI_OPENVMS => 13
    ELFOSABI_NSK => 14
    ELFOSABI_AROS => 15
    ELFOSABI_FENIXOS => 16
    ELFOSABI_CLOUDABI => 17
    ELFOSABI_ARM => 97
    ELFOSABI_STANDALONE => 255
  }
}

///|
pub fn OSABI::from_byte(b : Byte) -> OSABI {
  match b {
    0 => ELFOSABI_NONE
    1 => ELFOSABI_HPUX
    2 => ELFOSABI_NETBSD
    3 => ELFOSABI_LINUX
    4 => ELFOSABI_HURD
    5 => ELFOSABI_86OPEN
    6 => ELFOSABI_SOLARIS
    7 => ELFOSABI_AIX
    8 => ELFOSABI_IRIX
    9 => ELFOSABI_FREEBSD
    10 => ELFOSABI_TRU64
    11 => ELFOSABI_MODESTO
    12 => ELFOSABI_OPENBSD
    13 => ELFOSABI_OPENVMS
    14 => ELFOSABI_NSK
    15 => ELFOSABI_AROS
    16 => ELFOSABI_FENIXOS
    17 => ELFOSABI_CLOUDABI
    97 => ELFOSABI_ARM
    255 => ELFOSABI_STANDALONE
    _ => ELFOSABI_NONE
  }
}

///|
/// Type is found in Header.Type.
pub(all) enum Type {
  /// 0      Unknown type.
  ET_NONE
  /// 1      Relocatable.
  ET_REL
  /// 2      Executable.
  ET_EXEC
  /// 3      Shared object.
  ET_DYN
  /// 4      Core file.
  ET_CORE
  /// 0xfe00 First operating system specific.
  ET_LOOS
  /// 0xfeff Last operating system-specific.
  ET_HIOS
  /// 0xff00 First processor-specific.
  ET_LOPROC
  /// 0xffff Last processor-specific.
  ET_HIPROC
} derive(Eq, Show, ToJson)

///|
pub fn Type::to_int(self : Type) -> Int {
  match self {
    ET_NONE => 0
    ET_REL => 1
    ET_EXEC => 2
    ET_DYN => 3
    ET_CORE => 4
    ET_LOOS => 0xfe00
    ET_HIOS => 0xfeff
    ET_LOPROC => 0xff00
    ET_HIPROC => 0xffff
  }
}

///|
pub fn Type::from_int(i : Int) -> Type {
  match i {
    0 => ET_NONE
    1 => ET_REL
    2 => ET_EXEC
    3 => ET_DYN
    4 => ET_CORE
    0xfe00 => ET_LOOS
    0xfeff => ET_HIOS
    0xff00 => ET_LOPROC
    0xffff => ET_HIPROC
    _ => ET_NONE
  }
}

///|
/// Machine is found in Header.Machine.
pub(all) enum Machine {
  /// 0   Unknown machine.
  EM_NONE
  /// 1   AT&T WE32100.
  EM_M32
  /// 2   Sun SPARC.
  EM_SPARC
  /// 3   Intel i386.
  EM_386
  /// 4   Motorola 68000.
  EM_68K
  /// 5   Motorola 88000.
  EM_88K
  /// 7   Intel i860.
  EM_860
  /// 8   MIPS R3000 Big-Endian only.
  EM_MIPS
  /// 9   IBM System/370.
  EM_S370
  /// 10  MIPS R3000 Little-Endian.
  EM_MIPS_RS3_LE
  /// 15  HP PA-RISC.
  EM_PARISC
  /// 17  Fujitsu VPP500.
  EM_VPP500
  /// 18  SPARC v8plus.
  EM_SPARC32PLUS
  /// 19  Intel 80960.
  EM_960
  /// 20  PowerPC 32-bit.
  EM_PPC
  /// 21  PowerPC 64-bit.
  EM_PPC64
  /// 22  IBM System/390.
  EM_S390
  /// 36  NEC V800.
  EM_V800
  /// 37  Fujitsu FR20.
  EM_FR20
  /// 38  TRW RH-32.
  EM_RH32
  /// 39  Motorola RCE.
  EM_RCE
  /// 40  ARM.
  EM_ARM
  /// 42  Hitachi SH.
  EM_SH
  /// 43  SPARC v9 64-bit.
  EM_SPARCV9
  /// 44  Siemens TriCore embedded processor.
  EM_TRICORE
  /// 45  Argonaut RISC Core.
  EM_ARC
  /// 46  Hitachi H8/300.
  EM_H8_300
  /// 47  Hitachi H8/300H.
  EM_H8_300H
  /// 48  Hitachi H8S.
  EM_H8S
  /// 49  Hitachi H8/500.
  EM_H8_500
  /// 50  Intel IA-64 Processor.
  EM_IA_64
  /// 51  Stanford MIPS-X.
  EM_MIPS_X
  /// 52  Motorola ColdFire.
  EM_COLDFIRE
  /// 53  Motorola M68HC12.
  EM_68HC12
  /// 54  Fujitsu MMA.
  EM_MMA
  /// 55  Siemens PCP.
  EM_PCP
  /// 56  Sony nCPU.
  EM_NCPU
  /// 57  Denso NDR1 microprocessor.
  EM_NDR1
  /// 58  Motorola Star*Core processor.
  EM_STARCORE
  /// 59  Toyota ME16 processor.
  EM_ME16
  /// 60  STMicroelectronics ST100 processor.
  EM_ST100
  /// 61  Advanced Logic Corp. TinyJ processor.
  EM_TINYJ
  /// 62  Advanced Micro Devices x86-64
  EM_X86_64
  /// 63  Sony DSP Processor
  EM_PDSP
  /// 64  Digital Equipment Corp. PDP-10
  EM_PDP10
  /// 65  Digital Equipment Corp. PDP-11
  EM_PDP11
  /// 66  Siemens FX66 microcontroller
  EM_FX66
  /// 67  STMicroelectronics ST9+ 8/16 bit microcontroller
  EM_ST9PLUS
  /// 68  STMicroelectronics ST7 8-bit microcontroller
  EM_ST7
  /// 69  Motorola MC68HC16 Microcontroller
  EM_68HC16
  /// 70  Motorola MC68HC11 Microcontroller
  EM_68HC11
  /// 71  Motorola MC68HC08 Microcontroller
  EM_68HC08
  /// 72  Motorola MC68HC05 Microcontroller
  EM_68HC05
  /// 73  Silicon Graphics SVx
  EM_SVX
  /// 74  STMicroelectronics ST19 8-bit microcontroller
  EM_ST19
  /// 75  Digital VAX
  EM_VAX
  /// 76  Axis Communications 32-bit embedded processor
  EM_CRIS
  /// 77  Infineon Technologies 32-bit embedded processor
  EM_JAVELIN
  /// 78  Element 14 64-bit DSP Processor
  EM_FIREPATH
  /// 79  LSI Logic 16-bit DSP Processor
  EM_ZSP
  /// 80  Donald Knuth's educational 64-bit processor
  EM_MMIX
  /// 81  Harvard University machine-independent object files
  EM_HUANY
  /// 82  SiTera Prism
  EM_PRISM
  /// 83  Atmel AVR 8-bit microcontroller
  EM_AVR
  /// 84  Fujitsu FR30
  EM_FR30
  /// 85  Mitsubishi D10V
  EM_D10V
  /// 86  Mitsubishi D30V
  EM_D30V
  /// 87  NEC v850
  EM_V850
  /// 88  Mitsubishi M32R
  EM_M32R
  /// 89  Matsushita MN10300
  EM_MN10300
  /// 90  Matsushita MN10200
  EM_MN10200
  /// 91  picoJava
  EM_PJ
  /// 92  OpenRISC 32-bit embedded processor
  EM_OPENRISC
  /// 93  ARC International ARCompact processor
  EM_ARC_COMPACT
  /// 94  Tensilica Xtensa Architecture
  EM_XTENSA
  /// 95  Alphamosaic VideoCore processor
  EM_VIDEOCORE
  /// 96  Thompson Multimedia General Purpose Processor
  EM_TMM_GPP
  /// 97  National Semiconductor 32000 series
  EM_NS32K
  /// 98  Tenor Network TPC processor
  EM_TPC
  /// 99  Trebia SNP 1000 processor
  EM_SNP1K
  /// 100 STMicroelectronics ST200 microcontroller
  EM_ST200
  /// 101 Ubicom IP2xxx microcontroller family
  EM_IP2K
  /// 102 MAX Processor
  EM_MAX
  /// 103 National Semiconductor CompactRISC microprocessor
  EM_CR
  /// 104 Fujitsu F2MC16
  EM_F2MC16
  /// 105 Texas Instruments embedded microcontroller msp430
  EM_MSP430
  /// 106 Analog Devices Blackfin (DSP) processor
  EM_BLACKFIN
  /// 107 S1C33 Family of Seiko Epson processors
  EM_SE_C33
  /// 108 Sharp embedded microprocessor
  EM_SEP
  /// 109 Arca RISC Microprocessor
  EM_ARCA
  /// 110 Microprocessor series from PKU-Unity Ltd.
  EM_UNICORE
  /// 111 eXcess: 16/32/64-bit configurable embedded CPU
  EM_EXCESS
  /// 112 Icera Semiconductor Inc. Deep Execution Processor
  EM_DXP
  /// 113 Altera Nios II soft-core processor
  EM_ALTERA_NIOS2
  /// 114 National Semiconductor CompactRISC CRX
  EM_CRX
  /// 115 Motorola XGATE embedded processor
  EM_XGATE
  /// 116 Infineon C16x/XC16x processor
  EM_C166
  /// 117 Renesas M16C series microprocessors
  EM_M16C
  /// 118 Microchip Technology dsPIC30F Digital Signal Controller
  EM_DSPIC30F
  /// 119 Freescale Communication Engine RISC core
  EM_CE
  /// 120 Renesas M32C series microprocessors
  EM_M32C
  /// 131 Altium TSK3000 core
  EM_TSK3000
  /// 132 Freescale RS08 embedded processor
  EM_RS08
  /// 133 Analog Devices SHARC family of 32-bit DSP processors
  EM_SHARC
  /// 134 Cyan Technology eCOG2 microprocessor
  EM_ECOG2
  /// 135 Sunplus S+core7 RISC processor
  EM_SCORE7
  /// 136 New Japan Radio (NJR) 24-bit DSP Processor
  EM_DSP24
  /// 137 Broadcom VideoCore III processor
  EM_VIDEOCORE3
  /// 138 RISC processor for Lattice FPGA architecture
  EM_LATTICEMICO32
  /// 139 Seiko Epson C17 family
  EM_SE_C17
  /// 140 Texas Instruments TMS320C6000 DSP family
  EM_TI_C6000
  /// 141 Texas Instruments TMS320C2000 DSP family
  EM_TI_C2000
  /// 142 Texas Instruments TMS320C55x DSP family
  EM_TI_C5500
  /// 143 Texas Instruments Application Specific RISC Processor
  EM_TI_ARP32
  /// 144 Texas Instruments Programmable Realtime Unit
  EM_TI_PRU
  /// 160 STMicroelectronics 64bit VLIW Data Signal Processor
  EM_MMDSP_PLUS
  /// 161 Cypress M8C microprocessor
  EM_CYPRESS_M8C
  /// 162 Renesas R32C series microprocessors
  EM_R32C
  /// 163 NXP Semiconductors TriMedia architecture family
  EM_TRIMEDIA
  /// 164 QUALCOMM DSP6 Processor
  EM_QDSP6
  /// 165 Intel 8051 and variants
  EM_8051
  /// 166 STMicroelectronics STxP7x family
  EM_STXP7X
  /// 167 Andes Technology compact code size embedded RISC
  EM_NDS32
  /// 168 Cyan Technology eCOG1X family
  EM_ECOG1
  /// 168 Cyan Technology eCOG1X family (alternate)
  EM_ECOG1X
  /// 169 Dallas Semiconductor MAXQ30 Core Micro-controllers
  EM_MAXQ30
  /// 170 New Japan Radio (NJR) 16-bit DSP Processor
  EM_XIMO16
  /// 171 M2000 Reconfigurable RISC Microprocessor
  EM_MANIK
  /// 172 Cray Inc. NV2 vector architecture
  EM_CRAYNV2
  /// 173 Renesas RX family
  EM_RX
  /// 174 Imagination Technologies META processor architecture
  EM_METAG
  /// 175 MCST Elbrus general purpose hardware architecture
  EM_MCST_ELBRUS
  /// 176 Cyan Technology eCOG16 family
  EM_ECOG16
  /// 177 National Semiconductor CompactRISC CR16
  EM_CR16
  /// 178 Freescale Extended Time Processing Unit
  EM_ETPU
  /// 179 Infineon Technologies SLE9X core
  EM_SLE9X
  /// 180 Intel L10M
  EM_L10M
  /// 181 Intel K10M
  EM_K10M
  /// 183 ARM 64-bit Architecture (AArch64)
  EM_AARCH64
  /// 185 Atmel Corporation 32-bit microprocessor family
  EM_AVR32
  /// 186 STMicroeletronics STM8 8-bit microcontroller
  EM_STM8
  /// 187 Tilera TILE64 multicore architecture family
  EM_TILE64
  /// 188 Tilera TILEPro multicore architecture family
  EM_TILEPRO
  /// 189 Xilinx MicroBlaze 32-bit RISC soft processor core
  EM_MICROBLAZE
  /// 190 NVIDIA CUDA architecture
  EM_CUDA
  /// 191 Tilera TILE-Gx multicore architecture family
  EM_TILEGX
  /// 192 CloudShield architecture family
  EM_CLOUDSHIELD
  /// 193 KIPO-KAIST Core-A 1st generation processor family
  EM_COREA_1ST
  /// 194 KIPO-KAIST Core-A 2nd generation processor family
  EM_COREA_2ND
  /// 195 Synopsys ARCompact V2
  EM_ARC_COMPACT2
  /// 196 Open8 8-bit RISC soft processor core
  EM_OPEN8
  /// 197 Renesas RL78 family
  EM_RL78
  /// 198 Broadcom VideoCore V processor
  EM_VIDEOCORE5
  /// 199 Renesas 78KOR family
  EM_78KOR
  /// 200 Freescale 56800EX Digital Signal Controller (DSC)
  EM_56800EX
  /// 201 Beyond BA1 CPU architecture
  EM_BA1
  /// 202 Beyond BA2 CPU architecture
  EM_BA2
  /// 203 XMOS xCORE processor family
  EM_XCORE
  /// 204 Microchip 8-bit PIC(r) family
  EM_MCHP_PIC
  /// 205 Reserved by Intel
  EM_INTEL205
  /// 206 Reserved by Intel
  EM_INTEL206
  /// 207 Reserved by Intel
  EM_INTEL207
  /// 208 Reserved by Intel
  EM_INTEL208
  /// 209 Reserved by Intel
  EM_INTEL209
  /// 210 KM211 KM32 32-bit processor
  EM_KM32
  /// 211 KM211 KMX32 32-bit processor
  EM_KMX32
  /// 212 KM211 KMX16 16-bit processor
  EM_KMX16
  /// 213 KM211 KMX8 8-bit processor
  EM_KMX8
  /// 214 KM211 KVARC processor
  EM_KVARC
  /// 215 Paneve CDP architecture family
  EM_CDP
  /// 216 Cognitive Smart Memory Processor
  EM_COGE
  /// 217 Bluechip Systems CoolEngine
  EM_COOL
  /// 218 Nanoradio Optimized RISC
  EM_NORC
  /// 219 CSR Kalimba architecture family
  EM_CSR_KALIMBA
  /// 220 Zilog Z80
  EM_Z80
  /// 221 Controls and Data Services VISIUMcore processor
  EM_VISIUM
  /// 222 FTDI Chip FT32 high performance 32-bit RISC
  EM_FT32
  /// 223 Moxie processor family
  EM_MOXIE
  /// 224 AMD GPU architecture
  EM_AMDGPU
  /// 243 RISC-V
  EM_RISCV
  /// 244 Lanai 32-bit processor
  EM_LANAI
  /// 247 Linux BPF in-kernel virtual machine
  EM_BPF
  /// 258 LoongArch
  EM_LOONGARCH
  /// Non-standard or deprecated.
  /// 6   Intel i486.
  EM_486
  /// 10  MIPS R4000 Big-Endian
  EM_MIPS_RS4_BE
  /// 41  Digital Alpha (standard value).
  EM_ALPHA_STD
  /// 0x9026 Alpha (written in the absence of an ABI)
  EM_ALPHA
} derive(Eq, Show, ToJson)

///|
pub fn Machine::to_int(self : Machine) -> Int {
  match self {
    EM_NONE => 0
    EM_M32 => 1
    EM_SPARC => 2
    EM_386 => 3
    EM_68K => 4
    EM_88K => 5
    EM_860 => 7
    EM_MIPS => 8
    EM_S370 => 9
    EM_MIPS_RS3_LE => 10
    EM_PARISC => 15
    EM_VPP500 => 17
    EM_SPARC32PLUS => 18
    EM_960 => 19
    EM_PPC => 20
    EM_PPC64 => 21
    EM_S390 => 22
    EM_V800 => 36
    EM_FR20 => 37
    EM_RH32 => 38
    EM_RCE => 39
    EM_ARM => 40
    EM_SH => 42
    EM_SPARCV9 => 43
    EM_TRICORE => 44
    EM_ARC => 45
    EM_H8_300 => 46
    EM_H8_300H => 47
    EM_H8S => 48
    EM_H8_500 => 49
    EM_IA_64 => 50
    EM_MIPS_X => 51
    EM_COLDFIRE => 52
    EM_68HC12 => 53
    EM_MMA => 54
    EM_PCP => 55
    EM_NCPU => 56
    EM_NDR1 => 57
    EM_STARCORE => 58
    EM_ME16 => 59
    EM_ST100 => 60
    EM_TINYJ => 61
    EM_X86_64 => 62
    EM_PDSP => 63
    EM_PDP10 => 64
    EM_PDP11 => 65
    EM_FX66 => 66
    EM_ST9PLUS => 67
    EM_ST7 => 68
    EM_68HC16 => 69
    EM_68HC11 => 70
    EM_68HC08 => 71
    EM_68HC05 => 72
    EM_SVX => 73
    EM_ST19 => 74
    EM_VAX => 75
    EM_CRIS => 76
    EM_JAVELIN => 77
    EM_FIREPATH => 78
    EM_ZSP => 79
    EM_MMIX => 80
    EM_HUANY => 81
    EM_PRISM => 82
    EM_AVR => 83
    EM_FR30 => 84
    EM_D10V => 85
    EM_D30V => 86
    EM_V850 => 87
    EM_M32R => 88
    EM_MN10300 => 89
    EM_MN10200 => 90
    EM_PJ => 91
    EM_OPENRISC => 92
    EM_ARC_COMPACT => 93
    EM_XTENSA => 94
    EM_VIDEOCORE => 95
    EM_TMM_GPP => 96
    EM_NS32K => 97
    EM_TPC => 98
    EM_SNP1K => 99
    EM_ST200 => 100
    EM_IP2K => 101
    EM_MAX => 102
    EM_CR => 103
    EM_F2MC16 => 104
    EM_MSP430 => 105
    EM_BLACKFIN => 106
    EM_SE_C33 => 107
    EM_SEP => 108
    EM_ARCA => 109
    EM_UNICORE => 110
    EM_EXCESS => 111
    EM_DXP => 112
    EM_ALTERA_NIOS2 => 113
    EM_CRX => 114
    EM_XGATE => 115
    EM_C166 => 116
    EM_M16C => 117
    EM_DSPIC30F => 118
    EM_CE => 119
    EM_M32C => 120
    EM_TSK3000 => 131
    EM_RS08 => 132
    EM_SHARC => 133
    EM_ECOG2 => 134
    EM_SCORE7 => 135
    EM_DSP24 => 136
    EM_VIDEOCORE3 => 137
    EM_LATTICEMICO32 => 138
    EM_SE_C17 => 139
    EM_TI_C6000 => 140
    EM_TI_C2000 => 141
    EM_TI_C5500 => 142
    EM_TI_ARP32 => 143
    EM_TI_PRU => 144
    EM_MMDSP_PLUS => 160
    EM_CYPRESS_M8C => 161
    EM_R32C => 162
    EM_TRIMEDIA => 163
    EM_QDSP6 => 164
    EM_8051 => 165
    EM_STXP7X => 166
    EM_NDS32 => 167
    EM_ECOG1 => 168
    EM_ECOG1X => 168 // Same as EM_ECOG1
    EM_MAXQ30 => 169
    EM_XIMO16 => 170
    EM_MANIK => 171
    EM_CRAYNV2 => 172
    EM_RX => 173
    EM_METAG => 174
    EM_MCST_ELBRUS => 175
    EM_ECOG16 => 176
    EM_CR16 => 177
    EM_ETPU => 178
    EM_SLE9X => 179
    EM_L10M => 180
    EM_K10M => 181
    EM_AARCH64 => 183
    EM_AVR32 => 185
    EM_STM8 => 186
    EM_TILE64 => 187
    EM_TILEPRO => 188
    EM_MICROBLAZE => 189
    EM_CUDA => 190
    EM_TILEGX => 191
    EM_CLOUDSHIELD => 192
    EM_COREA_1ST => 193
    EM_COREA_2ND => 194
    EM_ARC_COMPACT2 => 195
    EM_OPEN8 => 196
    EM_RL78 => 197
    EM_VIDEOCORE5 => 198
    EM_78KOR => 199
    EM_56800EX => 200
    EM_BA1 => 201
    EM_BA2 => 202
    EM_XCORE => 203
    EM_MCHP_PIC => 204
    EM_INTEL205 => 205
    EM_INTEL206 => 206
    EM_INTEL207 => 207
    EM_INTEL208 => 208
    EM_INTEL209 => 209
    EM_KM32 => 210
    EM_KMX32 => 211
    EM_KMX16 => 212
    EM_KMX8 => 213
    EM_KVARC => 214
    EM_CDP => 215
    EM_COGE => 216
    EM_COOL => 217
    EM_NORC => 218
    EM_CSR_KALIMBA => 219
    EM_Z80 => 220
    EM_VISIUM => 221
    EM_FT32 => 222
    EM_MOXIE => 223
    EM_AMDGPU => 224
    EM_RISCV => 243
    EM_LANAI => 244
    EM_BPF => 247
    EM_LOONGARCH => 258
    EM_486 => 6
    EM_MIPS_RS4_BE => 10 // Same as EM_MIPS_RS3_LE
    EM_ALPHA_STD => 41
    EM_ALPHA => 0x9026
  }
}

///|
pub fn Machine::from_int(i : Int) -> Machine {
  match i {
    0 => EM_NONE
    1 => EM_M32
    2 => EM_SPARC
    3 => EM_386
    4 => EM_68K
    5 => EM_88K
    6 => EM_486
    7 => EM_860
    8 => EM_MIPS
    9 => EM_S370
    10 => EM_MIPS_RS3_LE
    15 => EM_PARISC
    17 => EM_VPP500
    18 => EM_SPARC32PLUS
    19 => EM_960
    20 => EM_PPC
    21 => EM_PPC64
    22 => EM_S390
    36 => EM_V800
    37 => EM_FR20
    38 => EM_RH32
    39 => EM_RCE
    40 => EM_ARM
    41 => EM_ALPHA_STD
    42 => EM_SH
    43 => EM_SPARCV9
    44 => EM_TRICORE
    45 => EM_ARC
    46 => EM_H8_300
    47 => EM_H8_300H
    48 => EM_H8S
    49 => EM_H8_500
    50 => EM_IA_64
    51 => EM_MIPS_X
    52 => EM_COLDFIRE
    53 => EM_68HC12
    54 => EM_MMA
    55 => EM_PCP
    56 => EM_NCPU
    57 => EM_NDR1
    58 => EM_STARCORE
    59 => EM_ME16
    60 => EM_ST100
    61 => EM_TINYJ
    62 => EM_X86_64
    63 => EM_PDSP
    64 => EM_PDP10
    65 => EM_PDP11
    66 => EM_FX66
    67 => EM_ST9PLUS
    68 => EM_ST7
    69 => EM_68HC16
    70 => EM_68HC11
    71 => EM_68HC08
    72 => EM_68HC05
    73 => EM_SVX
    74 => EM_ST19
    75 => EM_VAX
    76 => EM_CRIS
    77 => EM_JAVELIN
    78 => EM_FIREPATH
    79 => EM_ZSP
    80 => EM_MMIX
    81 => EM_HUANY
    82 => EM_PRISM
    83 => EM_AVR
    84 => EM_FR30
    85 => EM_D10V
    86 => EM_D30V
    87 => EM_V850
    88 => EM_M32R
    89 => EM_MN10300
    90 => EM_MN10200
    91 => EM_PJ
    92 => EM_OPENRISC
    93 => EM_ARC_COMPACT
    94 => EM_XTENSA
    95 => EM_VIDEOCORE
    96 => EM_TMM_GPP
    97 => EM_NS32K
    98 => EM_TPC
    99 => EM_SNP1K
    100 => EM_ST200
    101 => EM_IP2K
    102 => EM_MAX
    103 => EM_CR
    104 => EM_F2MC16
    105 => EM_MSP430
    106 => EM_BLACKFIN
    107 => EM_SE_C33
    108 => EM_SEP
    109 => EM_ARCA
    110 => EM_UNICORE
    111 => EM_EXCESS
    112 => EM_DXP
    113 => EM_ALTERA_NIOS2
    114 => EM_CRX
    115 => EM_XGATE
    116 => EM_C166
    117 => EM_M16C
    118 => EM_DSPIC30F
    119 => EM_CE
    120 => EM_M32C
    131 => EM_TSK3000
    132 => EM_RS08
    133 => EM_SHARC
    134 => EM_ECOG2
    135 => EM_SCORE7
    136 => EM_DSP24
    137 => EM_VIDEOCORE3
    138 => EM_LATTICEMICO32
    139 => EM_SE_C17
    140 => EM_TI_C6000
    141 => EM_TI_C2000
    142 => EM_TI_C5500
    143 => EM_TI_ARP32
    144 => EM_TI_PRU
    160 => EM_MMDSP_PLUS
    161 => EM_CYPRESS_M8C
    162 => EM_R32C
    163 => EM_TRIMEDIA
    164 => EM_QDSP6
    165 => EM_8051
    166 => EM_STXP7X
    167 => EM_NDS32
    168 => EM_ECOG1
    169 => EM_MAXQ30
    170 => EM_XIMO16
    171 => EM_MANIK
    172 => EM_CRAYNV2
    173 => EM_RX
    174 => EM_METAG
    175 => EM_MCST_ELBRUS
    176 => EM_ECOG16
    177 => EM_CR16
    178 => EM_ETPU
    179 => EM_SLE9X
    180 => EM_L10M
    181 => EM_K10M
    183 => EM_AARCH64
    185 => EM_AVR32
    186 => EM_STM8
    187 => EM_TILE64
    188 => EM_TILEPRO
    189 => EM_MICROBLAZE
    190 => EM_CUDA
    191 => EM_TILEGX
    192 => EM_CLOUDSHIELD
    193 => EM_COREA_1ST
    194 => EM_COREA_2ND
    195 => EM_ARC_COMPACT2
    196 => EM_OPEN8
    197 => EM_RL78
    198 => EM_VIDEOCORE5
    199 => EM_78KOR
    200 => EM_56800EX
    201 => EM_BA1
    202 => EM_BA2
    203 => EM_XCORE
    204 => EM_MCHP_PIC
    205 => EM_INTEL205
    206 => EM_INTEL206
    207 => EM_INTEL207
    208 => EM_INTEL208
    209 => EM_INTEL209
    210 => EM_KM32
    211 => EM_KMX32
    212 => EM_KMX16
    213 => EM_KMX8
    214 => EM_KVARC
    215 => EM_CDP
    216 => EM_COGE
    217 => EM_COOL
    218 => EM_NORC
    219 => EM_CSR_KALIMBA
    220 => EM_Z80
    221 => EM_VISIUM
    222 => EM_FT32
    223 => EM_MOXIE
    224 => EM_AMDGPU
    243 => EM_RISCV
    244 => EM_LANAI
    247 => EM_BPF
    258 => EM_LOONGARCH
    0x9026 => EM_ALPHA
    _ => EM_NONE
  }
}

///|
/// Special section indices.
pub(all) enum SectionIndex {
  /// 0      Undefined, missing, irrelevant.
  SHN_UNDEF
  /// 0xff00 First of reserved range.
  SHN_LORESERVE
  /// 0xff00 First processor-specific.
  SHN_LOPROC
  /// 0xff1f Last processor-specific.
  SHN_HIPROC
  /// 0xff20 First operating system-specific.
  SHN_LOOS
  /// 0xff3f Last operating system-specific.
  SHN_HIOS
  /// 0xfff1 Absolute values.
  SHN_ABS
  /// 0xfff2 Common data.
  SHN_COMMON
  /// 0xffff Escape; index stored elsewhere.
  SHN_XINDEX
  /// 0xffff Last of reserved range.
  SHN_HIRESERVE
} derive(Eq, Show, ToJson)

///|
pub fn SectionIndex::to_int(self : SectionIndex) -> Int {
  match self {
    SHN_UNDEF => 0
    SHN_LORESERVE => 0xff00
    SHN_LOPROC => 0xff00
    SHN_HIPROC => 0xff1f
    SHN_LOOS => 0xff20
    SHN_HIOS => 0xff3f
    SHN_ABS => 0xfff1
    SHN_COMMON => 0xfff2
    SHN_XINDEX => 0xffff
    SHN_HIRESERVE => 0xffff
  }
}

///|
pub fn SectionIndex::from_int(i : Int) -> SectionIndex {
  match i {
    0 => SHN_UNDEF
    0xff00 => SHN_LORESERVE
    0xff1f => SHN_HIPROC
    0xff20 => SHN_LOOS
    0xff3f => SHN_HIOS
    0xfff1 => SHN_ABS
    0xfff2 => SHN_COMMON
    0xffff => SHN_XINDEX
    _ => SHN_UNDEF
  }
}

///|
/// Section type.
pub(all) enum SectionType {
  SHT(UInt)
  /// 0          inactive
  SHT_NULL
  /// 1          program defined information
  SHT_PROGBITS
  /// 2          symbol table section
  SHT_SYMTAB
  /// 3          string table section
  SHT_STRTAB
  /// 4          relocation section with addends
  SHT_RELA
  /// 5          symbol hash table section
  SHT_HASH
  /// 6          dynamic section
  SHT_DYNAMIC
  /// 7          note section
  SHT_NOTE
  /// 8          no space section
  SHT_NOBITS
  /// 9          relocation section - no addends
  SHT_REL
  /// 10         reserved - purpose unknown
  SHT_SHLIB
  /// 11         dynamic symbol table section
  SHT_DYNSYM
  /// 14         Initialization function pointers.
  SHT_INIT_ARRAY
  /// 15         Termination function pointers.
  SHT_FINI_ARRAY
  /// 16         Pre-initialization function ptrs.
  SHT_PREINIT_ARRAY
  /// 17         Section group.
  SHT_GROUP
  /// 18         Section indexes (see SHN_XINDEX).
  SHT_SYMTAB_SHNDX
  /// 0x60000000 First of OS specific semantics
  SHT_LOOS
  /// 0x6ffffff5 GNU object attributes
  SHT_GNU_ATTRIBUTES
  /// 0x6ffffff6 GNU hash table
  SHT_GNU_HASH
  /// 0x6ffffff7 GNU prelink library list
  SHT_GNU_LIBLIST
  /// 0x6ffffffd GNU version definition section
  SHT_GNU_VERDEF
  /// 0x6ffffffe GNU version needs section
  SHT_GNU_VERNEED
  /// 0x6fffffff GNU version symbol table
  SHT_GNU_VERSYM
  /// 0x6fffffff Last of OS specific semantics
  SHT_HIOS
  /// 0x70000000 reserved range for processor
  SHT_LOPROC
  /// 0x70000003 RISCV object attributes
  SHT_RISCV_ATTRIBUTES
  /// 0x7000002a .MIPS.abiflags
  SHT_MIPS_ABIFLAGS
  /// 0x7fffffff specific section header types
  SHT_HIPROC
  /// 0x80000000 reserved range for application
  SHT_LOUSER
  /// 0xffffffff specific indexes
  SHT_HIUSER
} derive(Eq, Show, ToJson)

///|
pub impl Default for SectionType with default() -> SectionType {
  SHT_NULL
}

///|
pub fn SectionType::to_uint(self : SectionType) -> UInt {
  match self {
    SHT(type_) => type_
    SHT_NULL => 0
    SHT_PROGBITS => 1
    SHT_SYMTAB => 2
    SHT_STRTAB => 3
    SHT_RELA => 4
    SHT_HASH => 5
    SHT_DYNAMIC => 6
    SHT_NOTE => 7
    SHT_NOBITS => 8
    SHT_REL => 9
    SHT_SHLIB => 10
    SHT_DYNSYM => 11
    SHT_INIT_ARRAY => 14
    SHT_FINI_ARRAY => 15
    SHT_PREINIT_ARRAY => 16
    SHT_GROUP => 17
    SHT_SYMTAB_SHNDX => 18
    SHT_LOOS => 0x60000000
    SHT_GNU_ATTRIBUTES => 0x6ffffff5
    SHT_GNU_HASH => 0x6ffffff6
    SHT_GNU_LIBLIST => 0x6ffffff7
    SHT_GNU_VERDEF => 0x6ffffffd
    SHT_GNU_VERNEED => 0x6ffffffe
    SHT_GNU_VERSYM => 0x6fffffff
    SHT_HIOS => 0x6fffffff
    SHT_LOPROC => 0x70000000
    SHT_RISCV_ATTRIBUTES => 0x70000003
    SHT_MIPS_ABIFLAGS => 0x7000002a
    SHT_HIPROC => 0x7fffffff
    SHT_LOUSER => 0x80000000
    SHT_HIUSER => 0xffffffff
  }
}

///|
pub fn SectionType::from_uint(i : UInt) -> SectionType {
  match i {
    0 => SHT_NULL
    1 => SHT_PROGBITS
    2 => SHT_SYMTAB
    3 => SHT_STRTAB
    4 => SHT_RELA
    5 => SHT_HASH
    6 => SHT_DYNAMIC
    7 => SHT_NOTE
    8 => SHT_NOBITS
    9 => SHT_REL
    10 => SHT_SHLIB
    11 => SHT_DYNSYM
    14 => SHT_INIT_ARRAY
    15 => SHT_FINI_ARRAY
    16 => SHT_PREINIT_ARRAY
    17 => SHT_GROUP
    18 => SHT_SYMTAB_SHNDX
    0x60000000 => SHT_LOOS
    0x6ffffff5 => SHT_GNU_ATTRIBUTES
    0x6ffffff6 => SHT_GNU_HASH
    0x6ffffff7 => SHT_GNU_LIBLIST
    0x6ffffffd => SHT_GNU_VERDEF
    0x6ffffffe => SHT_GNU_VERNEED
    0x6fffffff => SHT_GNU_VERSYM
    0x70000000 => SHT_LOPROC
    0x70000003 => SHT_RISCV_ATTRIBUTES
    0x7000002a => SHT_MIPS_ABIFLAGS
    0x7fffffff => SHT_HIPROC
    0x80000000 => SHT_LOUSER
    0xffffffff => SHT_HIUSER
    i => SHT(i)
  }
}

///|
/// Section flags.
pub(all) struct SectionFlag(UInt)

///|
/// 0x1        Section contains writable data.
const SHF_WRITE : UInt = 0x1

///|
/// 0x2        Section occupies memory.
const SHF_ALLOC : UInt = 0x2

///|
/// 0x4        Section contains instructions.
const SHF_EXECINSTR : UInt = 0x4

///|
/// 0x10       Section may be merged.
const SHF_MERGE : UInt = 0x10

///|
/// 0x20       Section contains strings.
const SHF_STRINGS : UInt = 0x20

///|
/// 0x40       sh_info holds section index.
const SHF_INFO_LINK : UInt = 0x40

///|
/// 0x80       Special ordering requirements.
const SHF_LINK_ORDER : UInt = 0x80

///|
/// 0x100      OS-specific processing required.
const SHF_OS_NONCONFORMING : UInt = 0x100

///|
/// 0x200      Member of section group.
const SHF_GROUP : UInt = 0x200

///|
/// 0x400      Section contains TLS data.
const SHF_TLS : UInt = 0x400

///|
/// 0x800      Section is compressed.
const SHF_COMPRESSED : UInt = 0x800

///|
/// 0x0ff00000 OS-specific semantics.
const SHF_MASKOS : UInt = 0x0ff00000

///|
/// 0xf0000000 Processor-specific semantics.
const SHF_MASKPROC : UInt = 0xf0000000

///|
pub impl Default for SectionFlag with default() -> SectionFlag {
  0
}

///|
pub impl BitAnd for SectionFlag with land(
  self : SectionFlag,
  other : SectionFlag,
) -> SectionFlag {
  SectionFlag(self.0 & other.0)
}

///|
pub impl ToJson for SectionFlag with to_json(self : SectionFlag) -> Json {
  self.0.to_json()
}

///|
pub impl Show for SectionFlag with output(self : SectionFlag, logger : &Logger) -> Unit {
  self.0.output(logger)
}

///|
/// Section compression type.
pub(all) enum CompressionType {
  /// 0          No compression.
  COMPRESS_NONE
  /// 1          ZLIB compression.
  COMPRESS_ZLIB
  /// 2          ZSTD compression.
  COMPRESS_ZSTD
  /// 0x60000000 First OS-specific.
  COMPRESS_LOOS
  /// 0x6fffffff Last OS-specific.
  COMPRESS_HIOS
  /// 0x70000000 First processor-specific type.
  COMPRESS_LOPROC
  /// 0x7fffffff Last processor-specific type.
  COMPRESS_HIPROC
} derive(Eq, Show, ToJson)

///|
pub impl Default for CompressionType with default() -> CompressionType {
  COMPRESS_NONE
}

///|
pub fn CompressionType::to_int(self : CompressionType) -> Int {
  match self {
    COMPRESS_NONE => 0
    COMPRESS_ZLIB => 1
    COMPRESS_ZSTD => 2
    COMPRESS_LOOS => 0x60000000
    COMPRESS_HIOS => 0x6fffffff
    COMPRESS_LOPROC => 0x70000000
    COMPRESS_HIPROC => 0x7fffffff
  }
}

///|
pub fn CompressionType::from_int(i : Int) -> CompressionType {
  match i {
    0 => COMPRESS_NONE
    1 => COMPRESS_ZLIB
    2 => COMPRESS_ZSTD
    0x60000000 => COMPRESS_LOOS
    0x6fffffff => COMPRESS_HIOS
    0x70000000 => COMPRESS_LOPROC
    0x7fffffff => COMPRESS_HIPROC
    _ => COMPRESS_ZLIB
  }
}

///|
/// Prog.Type
pub(all) enum ProgType {
  /// 0 Unused entry.
  PT_NULL
  /// 1 Loadable segment.
  PT_LOAD
  /// 2 Dynamic linking information segment.
  PT_DYNAMIC
  /// 3 Pathname of interpreter.
  PT_INTERP
  /// 4 Auxiliary information.
  PT_NOTE
  /// 5 Reserved (not used).
  PT_SHLIB
  /// 6 Location of program header itself.
  PT_PHDR
  /// 7 Thread local storage segment
  PT_TLS
  /// 0x60000000 First OS-specific.
  PT_LOOS
  /// 0x6474e550 Frame unwind information
  PT_GNU_EH_FRAME
  /// 0x6474e551 Stack flags
  PT_GNU_STACK
  /// 0x6474e552 Read only after relocs
  PT_GNU_RELRO
  /// 0x6474e553 GNU property
  PT_GNU_PROPERTY
  /// 0x6474e555 Mbind segments start
  PT_GNU_MBIND_LO
  /// 0x6474f554 Mbind segments finish
  PT_GNU_MBIND_HI
  /// 0x65041580 PAX flags
  PT_PAX_FLAGS
  /// 0x65a3dbe6 Random data
  PT_OPENBSD_RANDOMIZE
  /// 0x65a3dbe7 W^X violations
  PT_OPENBSD_WXNEEDED
  /// 0x65a3dbe8 No branch target CFI
  PT_OPENBSD_NOBTCFI
  /// 0x65a41be6 Boot arguments
  PT_OPENBSD_BOOTDATA
  /// 0x6474e550 Frame unwind information
  PT_SUNW_EH_FRAME
  /// 0x6ffffffb Stack segment
  PT_SUNWSTACK
  /// 0x6fffffff Last OS-specific.
  PT_HIOS
  /// 0x70000000 First processor-specific type.
  PT_LOPROC
  /// 0x70000000 Architecture compatibility
  PT_ARM_ARCHEXT
  /// 0x70000001 Exception unwind tables
  PT_ARM_EXIDX
  /// 0x70000000 Architecture compatibility
  PT_AARCH64_ARCHEXT
  /// 0x70000001 Exception unwind tables
  PT_AARCH64_UNWIND
  /// 0x70000000 Register usage
  PT_MIPS_REGINFO
  /// 0x70000001 Runtime procedures
  PT_MIPS_RTPROC
  /// 0x70000002 Options
  PT_MIPS_OPTIONS
  /// 0x70000003 ABI flags
  PT_MIPS_ABIFLAGS
  /// 0x70000003 RISC-V ELF attribute section.
  PT_RISCV_ATTRIBUTES
  /// 0x70000000 4k page table size
  PT_S390_PGSTE
  /// 0x7fffffff Last processor-specific type.
  PT_HIPROC
} derive(Eq, Show, ToJson)

///|
pub impl Default for ProgType with default() -> ProgType {
  PT_NULL
}

///|
pub fn ProgType::to_int(self : ProgType) -> Int {
  match self {
    PT_NULL => 0
    PT_LOAD => 1
    PT_DYNAMIC => 2
    PT_INTERP => 3
    PT_NOTE => 4
    PT_SHLIB => 5
    PT_PHDR => 6
    PT_TLS => 7
    PT_LOOS => 0x60000000
    PT_GNU_EH_FRAME => 0x6474e550
    PT_GNU_STACK => 0x6474e551
    PT_GNU_RELRO => 0x6474e552
    PT_GNU_PROPERTY => 0x6474e553
    PT_GNU_MBIND_LO => 0x6474e555
    PT_GNU_MBIND_HI => 0x6474f554
    PT_PAX_FLAGS => 0x65041580
    PT_OPENBSD_RANDOMIZE => 0x65a3dbe6
    PT_OPENBSD_WXNEEDED => 0x65a3dbe7
    PT_OPENBSD_NOBTCFI => 0x65a3dbe8
    PT_OPENBSD_BOOTDATA => 0x65a41be6
    PT_SUNW_EH_FRAME => 0x6474e550 // Same as PT_GNU_EH_FRAME
    PT_SUNWSTACK => 0x6ffffffb
    PT_HIOS => 0x6fffffff
    PT_LOPROC => 0x70000000
    PT_ARM_ARCHEXT => 0x70000000 // Same as PT_LOPROC
    PT_ARM_EXIDX => 0x70000001
    PT_AARCH64_ARCHEXT => 0x70000000 // Same as PT_LOPROC
    PT_AARCH64_UNWIND => 0x70000001 // Same as PT_ARM_EXIDX
    PT_MIPS_REGINFO => 0x70000000 // Same as PT_LOPROC
    PT_MIPS_RTPROC => 0x70000001 // Same as PT_ARM_EXIDX
    PT_MIPS_OPTIONS => 0x70000002
    PT_MIPS_ABIFLAGS => 0x70000003
    PT_RISCV_ATTRIBUTES => 0x70000003 // Same as PT_MIPS_ABIFLAGS
    PT_S390_PGSTE => 0x70000000 // Same as PT_LOPROC
    PT_HIPROC => 0x7fffffff
  }
}

///|
pub fn ProgType::from_int(i : Int) -> ProgType {
  match i {
    0 => PT_NULL
    1 => PT_LOAD
    2 => PT_DYNAMIC
    3 => PT_INTERP
    4 => PT_NOTE
    5 => PT_SHLIB
    6 => PT_PHDR
    7 => PT_TLS
    0x60000000 => PT_LOOS
    0x6474e550 => PT_GNU_EH_FRAME
    0x6474e551 => PT_GNU_STACK
    0x6474e552 => PT_GNU_RELRO
    0x6474e553 => PT_GNU_PROPERTY
    0x6474e555 => PT_GNU_MBIND_LO
    0x6474f554 => PT_GNU_MBIND_HI
    0x65041580 => PT_PAX_FLAGS
    0x65a3dbe6 => PT_OPENBSD_RANDOMIZE
    0x65a3dbe7 => PT_OPENBSD_WXNEEDED
    0x65a3dbe8 => PT_OPENBSD_NOBTCFI
    0x65a41be6 => PT_OPENBSD_BOOTDATA
    0x6ffffffb => PT_SUNWSTACK
    0x6fffffff => PT_HIOS
    0x70000000 => PT_LOPROC
    0x70000001 => PT_ARM_EXIDX
    0x70000002 => PT_MIPS_OPTIONS
    0x70000003 => PT_MIPS_ABIFLAGS
    0x7fffffff => PT_HIPROC
    _ => PT_NULL
  }
}

///|
/// Prog.Flag
pub(all) enum ProgFlag {
  PF(UInt)
  /// 0x1        Executable.
  PF_X
  /// 0x2        Writable.
  PF_W
  /// 0x4        Readable.
  PF_R
  /// 0x0ff00000 Operating system-specific.
  PF_MASKOS
  /// 0xf0000000 Processor-specific.
  PF_MASKPROC
} derive(Eq, Show, ToJson)

///|
pub impl Default for ProgFlag with default() -> ProgFlag {
  PF(0)
}

///|
pub fn ProgFlag::from_uint(i : UInt) -> ProgFlag {
  match i {
    0x1 => PF_X
    0x2 => PF_W
    0x4 => PF_R
    0x0ff00000 => PF_MASKOS
    0xf0000000 => PF_MASKPROC
    i => PF(i)
  }
}

///|
pub fn ProgFlag::to_uint(self : ProgFlag) -> UInt {
  match self {
    PF(i) => i
    PF_X => 0x1
    PF_W => 0x2
    PF_R => 0x4
    PF_MASKOS => 0x0ff00000
    PF_MASKPROC => 0xf0000000
  }
}

///|
/// Dyn.Tag
pub(all) enum DynTag {
  /// 0  Terminating entry.
  DT_NULL
  /// 1  String table offset of a needed shared library.
  DT_NEEDED
  /// 2  Total size in bytes of PLT relocations.
  DT_PLTRELSZ
  /// 3  Processor-dependent address.
  DT_PLTGOT
  /// 4  Address of symbol hash table.
  DT_HASH
  /// 5  Address of string table.
  DT_STRTAB
  /// 6  Address of symbol table.
  DT_SYMTAB
  /// 7  Address of ElfNN_Rela relocations.
  DT_RELA
  /// 8  Total size of ElfNN_Rela relocations.
  DT_RELASZ
  /// 9  Size of each ElfNN_Rela relocation entry.
  DT_RELAENT
  /// 10 Size of string table.
  DT_STRSZ
  /// 11 Size of each symbol table entry.
  DT_SYMENT
  /// 12 Address of initialization function.
  DT_INIT
  /// 13 Address of finalization function.
  DT_FINI
  /// 14 String table offset of shared object name.
  DT_SONAME
  /// 15 String table offset of library path. [sup]
  DT_RPATH
  /// 16 Indicates "symbolic" linking. [sup]
  DT_SYMBOLIC
  /// 17 Address of ElfNN_Rel relocations.
  DT_REL
  /// 18 Total size of ElfNN_Rel relocations.
  DT_RELSZ
  /// 19 Size of each ElfNN_Rel relocation.
  DT_RELENT
  /// 20 Type of relocation used for PLT.
  DT_PLTREL
  /// 21 Reserved (not used).
  DT_DEBUG
  /// 22 Indicates there may be relocations in non-writable segments. [sup]
  DT_TEXTREL
  /// 23 Address of PLT relocations.
  DT_JMPREL
  /// 24 [sup]
  DT_BIND_NOW
  /// 25 Address of the array of pointers to initialization functions
  DT_INIT_ARRAY
  /// 26 Address of the array of pointers to termination functions
  DT_FINI_ARRAY
  /// 27 Size in bytes of the array of initialization functions.
  DT_INIT_ARRAYSZ
  /// 28 Size in bytes of the array of termination functions.
  DT_FINI_ARRAYSZ
  /// 29 String table offset of a null-terminated library search path string.
  DT_RUNPATH
  /// 30 Object specific flag values.
  DT_FLAGS
  /// 32 Values greater than or equal to DT_ENCODING
  /// and less than DT_LOOS follow the rules for
  /// the interpretation of the d_un union
  /// as follows: even == 'd_ptr', even == 'd_val'
  /// or none
  DT_ENCODING
  /// 32 Address of the array of pointers to pre-initialization functions.
  DT_PREINIT_ARRAY
  /// 33 Size in bytes of the array of pre-initialization functions.
  DT_PREINIT_ARRAYSZ
  /// 34 Address of SHT_SYMTAB_SHNDX section.
  DT_SYMTAB_SHNDX
  /// 0x6000000d First OS-specific
  DT_LOOS
  /// 0x6ffff000 Last OS-specific
  DT_HIOS
  /// 0x6ffffd00
  DT_VALRNGLO
  /// 0x6ffffdf5
  DT_GNU_PRELINKED
  /// 0x6ffffdf6
  DT_GNU_CONFLICTSZ
  /// 0x6ffffdf7
  DT_GNU_LIBLISTSZ
  /// 0x6ffffdf8
  DT_CHECKSUM
  /// 0x6ffffdf9
  DT_PLTPADSZ
  /// 0x6ffffdfa
  DT_MOVEENT
  /// 0x6ffffdfb
  DT_MOVESZ
  /// 0x6ffffdfc
  DT_FEATURE
  /// 0x6ffffdfd
  DT_POSFLAG_1
  /// 0x6ffffdfe
  DT_SYMINSZ
  /// 0x6ffffdff
  DT_SYMINENT
  /// 0x6ffffdff
  DT_VALRNGHI
  /// 0x6ffffe00
  DT_ADDRRNGLO
  /// 0x6ffffef5
  DT_GNU_HASH
  /// 0x6ffffef6
  DT_TLSDESC_PLT
  /// 0x6ffffef7
  DT_TLSDESC_GOT
  /// 0x6ffffef8
  DT_GNU_CONFLICT
  /// 0x6ffffef9
  DT_GNU_LIBLIST
  /// 0x6ffffefa
  DT_CONFIG
  /// 0x6ffffefb
  DT_DEPAUDIT
  /// 0x6ffffefc
  DT_AUDIT
  /// 0x6ffffefd
  DT_PLTPAD
  /// 0x6ffffefe
  DT_MOVETAB
  /// 0x6ffffeff
  DT_SYMINFO
  /// 0x6ffffeff
  DT_ADDRRNGHI
  /// 0x6ffffff0
  DT_VERSYM
  /// 0x6ffffff9
  DT_RELACOUNT
  /// 0x6ffffffa
  DT_RELCOUNT
  /// 0x6ffffffb
  DT_FLAGS_1
  /// 0x6ffffffc
  DT_VERDEF
  /// 0x6ffffffd
  DT_VERDEFNUM
  /// 0x6ffffffe
  DT_VERNEED
  /// 0x6fffffff
  DT_VERNEEDNUM
  /// 0x70000000 First processor-specific type.
  DT_LOPROC
  /// 0x70000001
  DT_MIPS_RLD_VERSION
  /// 0x70000002
  DT_MIPS_TIME_STAMP
  /// 0x70000003
  DT_MIPS_ICHECKSUM
  /// 0x70000004
  DT_MIPS_IVERSION
  /// 0x70000005
  DT_MIPS_FLAGS
  /// 0x70000006
  DT_MIPS_BASE_ADDRESS
  /// 0x70000007
  DT_MIPS_MSYM
  /// 0x70000008
  DT_MIPS_CONFLICT
  /// 0x70000009
  DT_MIPS_LIBLIST
  /// 0x7000000a
  DT_MIPS_LOCAL_GOTNO
  /// 0x7000000b
  DT_MIPS_CONFLICTNO
  /// 0x70000010
  DT_MIPS_LIBLISTNO
  /// 0x70000011
  DT_MIPS_SYMTABNO
  /// 0x70000012
  DT_MIPS_UNREFEXTNO
  /// 0x70000013
  DT_MIPS_GOTSYM
  /// 0x70000014
  DT_MIPS_HIPAGENO
  /// 0x70000016
  DT_MIPS_RLD_MAP
  /// 0x70000017
  DT_MIPS_DELTA_CLASS
  /// 0x70000018
  DT_MIPS_DELTA_CLASS_NO
  /// 0x70000019
  DT_MIPS_DELTA_INSTANCE
  /// 0x7000001a
  DT_MIPS_DELTA_INSTANCE_NO
  /// 0x7000001b
  DT_MIPS_DELTA_RELOC
  /// 0x7000001c
  DT_MIPS_DELTA_RELOC_NO
  /// 0x7000001d
  DT_MIPS_DELTA_SYM
  /// 0x7000001e
  DT_MIPS_DELTA_SYM_NO
  /// 0x70000020
  DT_MIPS_DELTA_CLASSSYM
  /// 0x70000021
  DT_MIPS_DELTA_CLASSSYM_NO
  /// 0x70000022
  DT_MIPS_CXX_FLAGS
  /// 0x70000023
  DT_MIPS_PIXIE_INIT
  /// 0x70000024
  DT_MIPS_SYMBOL_LIB
  /// 0x70000025
  DT_MIPS_LOCALPAGE_GOTIDX
  /// 0x70000026
  DT_MIPS_LOCAL_GOTIDX
  /// 0x70000027
  DT_MIPS_HIDDEN_GOTIDX
  /// 0x70000028
  DT_MIPS_PROTECTED_GOTIDX
  /// 0x70000029
  DT_MIPS_OPTIONS
  /// 0x7000002a
  DT_MIPS_INTERFACE
  /// 0x7000002b
  DT_MIPS_DYNSTR_ALIGN
  /// 0x7000002c
  DT_MIPS_INTERFACE_SIZE
  /// 0x7000002d
  DT_MIPS_RLD_TEXT_RESOLVE_ADDR
  /// 0x7000002e
  DT_MIPS_PERF_SUFFIX
  /// 0x7000002f
  DT_MIPS_COMPACT_SIZE
  /// 0x70000030
  DT_MIPS_GP_VALUE
  /// 0x70000031
  DT_MIPS_AUX_DYNAMIC
  /// 0x70000032
  DT_MIPS_PLTGOT
  /// 0x70000034
  DT_MIPS_RWPLT
  /// 0x70000035
  DT_MIPS_RLD_MAP_REL
  /// 0x70000000
  DT_PPC_GOT
  /// 0x70000001
  DT_PPC_OPT
  /// 0x70000000
  DT_PPC64_GLINK
  /// 0x70000001
  DT_PPC64_OPD
  /// 0x70000002
  DT_PPC64_OPDSZ
  /// 0x70000003
  DT_PPC64_OPT
  /// 0x70000001
  DT_SPARC_REGISTER
  /// 0x7ffffffd
  DT_AUXILIARY
  /// 0x7ffffffe
  DT_USED
  /// 0x7fffffff
  DT_FILTER
  /// 0x7fffffff Last processor-specific type.
  DT_HIPROC
} derive(Eq, Show, ToJson)

///|
pub fn DynTag::to_int(self : DynTag) -> Int {
  match self {
    DT_NULL => 0
    DT_NEEDED => 1
    DT_PLTRELSZ => 2
    DT_PLTGOT => 3
    DT_HASH => 4
    DT_STRTAB => 5
    DT_SYMTAB => 6
    DT_RELA => 7
    DT_RELASZ => 8
    DT_RELAENT => 9
    DT_STRSZ => 10
    DT_SYMENT => 11
    DT_INIT => 12
    DT_FINI => 13
    DT_SONAME => 14
    DT_RPATH => 15
    DT_SYMBOLIC => 16
    DT_REL => 17
    DT_RELSZ => 18
    DT_RELENT => 19
    DT_PLTREL => 20
    DT_DEBUG => 21
    DT_TEXTREL => 22
    DT_JMPREL => 23
    DT_BIND_NOW => 24
    DT_INIT_ARRAY => 25
    DT_FINI_ARRAY => 26
    DT_INIT_ARRAYSZ => 27
    DT_FINI_ARRAYSZ => 28
    DT_RUNPATH => 29
    DT_FLAGS => 30
    DT_ENCODING => 32
    DT_PREINIT_ARRAY => 32
    DT_PREINIT_ARRAYSZ => 33
    DT_SYMTAB_SHNDX => 34
    DT_LOOS => 0x6000000d
    DT_HIOS => 0x6ffff000
    DT_VALRNGLO => 0x6ffffd00
    DT_GNU_PRELINKED => 0x6ffffdf5
    DT_GNU_CONFLICTSZ => 0x6ffffdf6
    DT_GNU_LIBLISTSZ => 0x6ffffdf7
    DT_CHECKSUM => 0x6ffffdf8
    DT_PLTPADSZ => 0x6ffffdf9
    DT_MOVEENT => 0x6ffffdfa
    DT_MOVESZ => 0x6ffffdfb
    DT_FEATURE => 0x6ffffdfc
    DT_POSFLAG_1 => 0x6ffffdfd
    DT_SYMINSZ => 0x6ffffdfe
    DT_SYMINENT => 0x6ffffdff
    DT_VALRNGHI => 0x6ffffdff
    DT_ADDRRNGLO => 0x6ffffe00
    DT_GNU_HASH => 0x6ffffef5
    DT_TLSDESC_PLT => 0x6ffffef6
    DT_TLSDESC_GOT => 0x6ffffef7
    DT_GNU_CONFLICT => 0x6ffffef8
    DT_GNU_LIBLIST => 0x6ffffef9
    DT_CONFIG => 0x6ffffefa
    DT_DEPAUDIT => 0x6ffffefb
    DT_AUDIT => 0x6ffffefc
    DT_PLTPAD => 0x6ffffefd
    DT_MOVETAB => 0x6ffffefe
    DT_SYMINFO => 0x6ffffeff
    DT_ADDRRNGHI => 0x6ffffeff
    DT_VERSYM => 0x6ffffff0
    DT_RELACOUNT => 0x6ffffff9
    DT_RELCOUNT => 0x6ffffffa
    DT_FLAGS_1 => 0x6ffffffb
    DT_VERDEF => 0x6ffffffc
    DT_VERDEFNUM => 0x6ffffffd
    DT_VERNEED => 0x6ffffffe
    DT_VERNEEDNUM => 0x6fffffff
    DT_LOPROC => 0x70000000
    DT_MIPS_RLD_VERSION => 0x70000001
    DT_MIPS_TIME_STAMP => 0x70000002
    DT_MIPS_ICHECKSUM => 0x70000003
    DT_MIPS_IVERSION => 0x70000004
    DT_MIPS_FLAGS => 0x70000005
    DT_MIPS_BASE_ADDRESS => 0x70000006
    DT_MIPS_MSYM => 0x70000007
    DT_MIPS_CONFLICT => 0x70000008
    DT_MIPS_LIBLIST => 0x70000009
    DT_MIPS_LOCAL_GOTNO => 0x7000000a
    DT_MIPS_CONFLICTNO => 0x7000000b
    DT_MIPS_LIBLISTNO => 0x70000010
    DT_MIPS_SYMTABNO => 0x70000011
    DT_MIPS_UNREFEXTNO => 0x70000012
    DT_MIPS_GOTSYM => 0x70000013
    DT_MIPS_HIPAGENO => 0x70000014
    DT_MIPS_RLD_MAP => 0x70000016
    DT_MIPS_DELTA_CLASS => 0x70000017
    DT_MIPS_DELTA_CLASS_NO => 0x70000018
    DT_MIPS_DELTA_INSTANCE => 0x70000019
    DT_MIPS_DELTA_INSTANCE_NO => 0x7000001a
    DT_MIPS_DELTA_RELOC => 0x7000001b
    DT_MIPS_DELTA_RELOC_NO => 0x7000001c
    DT_MIPS_DELTA_SYM => 0x7000001d
    DT_MIPS_DELTA_SYM_NO => 0x7000001e
    DT_MIPS_DELTA_CLASSSYM => 0x70000020
    DT_MIPS_DELTA_CLASSSYM_NO => 0x70000021
    DT_MIPS_CXX_FLAGS => 0x70000022
    DT_MIPS_PIXIE_INIT => 0x70000023
    DT_MIPS_SYMBOL_LIB => 0x70000024
    DT_MIPS_LOCALPAGE_GOTIDX => 0x70000025
    DT_MIPS_LOCAL_GOTIDX => 0x70000026
    DT_MIPS_HIDDEN_GOTIDX => 0x70000027
    DT_MIPS_PROTECTED_GOTIDX => 0x70000028
    DT_MIPS_OPTIONS => 0x70000029
    DT_MIPS_INTERFACE => 0x7000002a
    DT_MIPS_DYNSTR_ALIGN => 0x7000002b
    DT_MIPS_INTERFACE_SIZE => 0x7000002c
    DT_MIPS_RLD_TEXT_RESOLVE_ADDR => 0x7000002d
    DT_MIPS_PERF_SUFFIX => 0x7000002e
    DT_MIPS_COMPACT_SIZE => 0x7000002f
    DT_MIPS_GP_VALUE => 0x70000030
    DT_MIPS_AUX_DYNAMIC => 0x70000031
    DT_MIPS_PLTGOT => 0x70000032
    DT_MIPS_RWPLT => 0x70000034
    DT_MIPS_RLD_MAP_REL => 0x70000035
    DT_PPC_GOT => 0x70000000
    DT_PPC_OPT => 0x70000001
    DT_PPC64_GLINK => 0x70000000
    DT_PPC64_OPD => 0x70000001
    DT_PPC64_OPDSZ => 0x70000002
    DT_PPC64_OPT => 0x70000003
    DT_SPARC_REGISTER => 0x70000001
    DT_AUXILIARY => 0x7ffffffd
    DT_USED => 0x7ffffffe
    DT_FILTER => 0x7fffffff
    DT_HIPROC => 0x7fffffff
  }
}

///|
pub fn DynTag::from_int(i : Int) -> DynTag {
  match i {
    0 => DT_NULL
    1 => DT_NEEDED
    2 => DT_PLTRELSZ
    3 => DT_PLTGOT
    4 => DT_HASH
    5 => DT_STRTAB
    6 => DT_SYMTAB
    7 => DT_RELA
    8 => DT_RELASZ
    9 => DT_RELAENT
    10 => DT_STRSZ
    11 => DT_SYMENT
    12 => DT_INIT
    13 => DT_FINI
    14 => DT_SONAME
    15 => DT_RPATH
    16 => DT_SYMBOLIC
    17 => DT_REL
    18 => DT_RELSZ
    19 => DT_RELENT
    20 => DT_PLTREL
    21 => DT_DEBUG
    22 => DT_TEXTREL
    23 => DT_JMPREL
    24 => DT_BIND_NOW
    25 => DT_INIT_ARRAY
    26 => DT_FINI_ARRAY
    27 => DT_INIT_ARRAYSZ
    28 => DT_FINI_ARRAYSZ
    29 => DT_RUNPATH
    30 => DT_FLAGS
    32 => DT_ENCODING
    33 => DT_PREINIT_ARRAYSZ
    34 => DT_SYMTAB_SHNDX
    0x6000000d => DT_LOOS
    0x6ffff000 => DT_HIOS
    0x6ffffd00 => DT_VALRNGLO
    0x6ffffdf5 => DT_GNU_PRELINKED
    0x6ffffdf6 => DT_GNU_CONFLICTSZ
    0x6ffffdf7 => DT_GNU_LIBLISTSZ
    0x6ffffdf8 => DT_CHECKSUM
    0x6ffffdf9 => DT_PLTPADSZ
    0x6ffffdfa => DT_MOVEENT
    0x6ffffdfb => DT_MOVESZ
    0x6ffffdfc => DT_FEATURE
    0x6ffffdfd => DT_POSFLAG_1
    0x6ffffdfe => DT_SYMINSZ
    0x6ffffdff => DT_SYMINENT
    0x6ffffe00 => DT_ADDRRNGLO
    0x6ffffef5 => DT_GNU_HASH
    0x6ffffef6 => DT_TLSDESC_PLT
    0x6ffffef7 => DT_TLSDESC_GOT
    0x6ffffef8 => DT_GNU_CONFLICT
    0x6ffffef9 => DT_GNU_LIBLIST
    0x6ffffefa => DT_CONFIG
    0x6ffffefb => DT_DEPAUDIT
    0x6ffffefc => DT_AUDIT
    0x6ffffefd => DT_PLTPAD
    0x6ffffefe => DT_MOVETAB
    0x6ffffeff => DT_SYMINFO
    0x6ffffff0 => DT_VERSYM
    0x6ffffff9 => DT_RELACOUNT
    0x6ffffffa => DT_RELCOUNT
    0x6ffffffb => DT_FLAGS_1
    0x6ffffffc => DT_VERDEF
    0x6ffffffd => DT_VERDEFNUM
    0x6ffffffe => DT_VERNEED
    0x6fffffff => DT_VERNEEDNUM
    0x70000000 => DT_LOPROC
    0x70000001 => DT_MIPS_RLD_VERSION
    0x70000002 => DT_MIPS_TIME_STAMP
    0x70000003 => DT_MIPS_ICHECKSUM
    0x70000004 => DT_MIPS_IVERSION
    0x70000005 => DT_MIPS_FLAGS
    0x70000006 => DT_MIPS_BASE_ADDRESS
    0x70000007 => DT_MIPS_MSYM
    0x70000008 => DT_MIPS_CONFLICT
    0x70000009 => DT_MIPS_LIBLIST
    0x7000000a => DT_MIPS_LOCAL_GOTNO
    0x7000000b => DT_MIPS_CONFLICTNO
    0x70000010 => DT_MIPS_LIBLISTNO
    0x70000011 => DT_MIPS_SYMTABNO
    0x70000012 => DT_MIPS_UNREFEXTNO
    0x70000013 => DT_MIPS_GOTSYM
    0x70000014 => DT_MIPS_HIPAGENO
    0x70000016 => DT_MIPS_RLD_MAP
    0x70000017 => DT_MIPS_DELTA_CLASS
    0x70000018 => DT_MIPS_DELTA_CLASS_NO
    0x70000019 => DT_MIPS_DELTA_INSTANCE
    0x7000001a => DT_MIPS_DELTA_INSTANCE_NO
    0x7000001b => DT_MIPS_DELTA_RELOC
    0x7000001c => DT_MIPS_DELTA_RELOC_NO
    0x7000001d => DT_MIPS_DELTA_SYM
    0x7000001e => DT_MIPS_DELTA_SYM_NO
    0x70000020 => DT_MIPS_DELTA_CLASSSYM
    0x70000021 => DT_MIPS_DELTA_CLASSSYM_NO
    0x70000022 => DT_MIPS_CXX_FLAGS
    0x70000023 => DT_MIPS_PIXIE_INIT
    0x70000024 => DT_MIPS_SYMBOL_LIB
    0x70000025 => DT_MIPS_LOCALPAGE_GOTIDX
    0x70000026 => DT_MIPS_LOCAL_GOTIDX
    0x70000027 => DT_MIPS_HIDDEN_GOTIDX
    0x70000028 => DT_MIPS_PROTECTED_GOTIDX
    0x70000029 => DT_MIPS_OPTIONS
    0x7000002a => DT_MIPS_INTERFACE
    0x7000002b => DT_MIPS_DYNSTR_ALIGN
    0x7000002c => DT_MIPS_INTERFACE_SIZE
    0x7000002d => DT_MIPS_RLD_TEXT_RESOLVE_ADDR
    0x7000002e => DT_MIPS_PERF_SUFFIX
    0x7000002f => DT_MIPS_COMPACT_SIZE
    0x70000030 => DT_MIPS_GP_VALUE
    0x70000031 => DT_MIPS_AUX_DYNAMIC
    0x70000032 => DT_MIPS_PLTGOT
    0x70000034 => DT_MIPS_RWPLT
    0x70000035 => DT_MIPS_RLD_MAP_REL
    0x7ffffffd => DT_AUXILIARY
    0x7ffffffe => DT_USED
    0x7fffffff => DT_FILTER
    _ => DT_NULL
  }
}

///|
/// Symbol Binding - ELFNN_ST_BIND - st_info
pub(all) enum SymBind {
  /// 0  Local symbol
  STB_LOCAL
  /// 1  Global symbol
  STB_GLOBAL
  /// 2  like global - lower precedence
  STB_WEAK
  /// 10 Reserved range for operating system
  STB_LOOS
  /// 12   specific semantics.
  STB_HIOS
  /// 13 reserved range for processor
  STB_LOPROC
  /// 15   specific semantics.
  STB_HIPROC
} derive(Eq, Show, ToJson)

///|
pub fn SymBind::to_int(self : SymBind) -> Int {
  match self {
    STB_LOCAL => 0
    STB_GLOBAL => 1
    STB_WEAK => 2
    STB_LOOS => 10
    STB_HIOS => 12
    STB_LOPROC => 13
    STB_HIPROC => 15
  }
}

///|
pub fn SymBind::from_int(i : Int) -> SymBind {
  match i {
    0 => STB_LOCAL
    1 => STB_GLOBAL
    2 => STB_WEAK
    10 => STB_LOOS
    12 => STB_HIOS
    13 => STB_LOPROC
    15 => STB_HIPROC
    _ => STB_LOCAL
  }
}

///|
/// Symbol type - ELFNN_ST_TYPE - st_info
pub(all) enum SymType {
  /// 0  Unspecified type.
  STT_NOTYPE
  /// 1  Data object.
  STT_OBJECT
  /// 2  Function.
  STT_FUNC
  /// 3  Section.
  STT_SECTION
  /// 4  Source file.
  STT_FILE
  /// 5  Uninitialized common block.
  STT_COMMON
  /// 6  TLS object.
  STT_TLS
  /// 10 Reserved range for operating system
  STT_LOOS
  /// 12   specific semantics.
  STT_HIOS
  /// 13 reserved range for processor
  STT_LOPROC
  /// 15   specific semantics.
  STT_HIPROC
  /// Non-standard symbol types.
  /// 8  Complex relocation expression.
  STT_RELC
  /// 9  Signed complex relocation expression.
  STT_SRELC
  /// 10 Indirect code object.
  STT_GNU_IFUNC
} derive(Eq, Show, ToJson)

///|
pub fn SymType::to_int(self : SymType) -> Int {
  match self {
    STT_NOTYPE => 0
    STT_OBJECT => 1
    STT_FUNC => 2
    STT_SECTION => 3
    STT_FILE => 4
    STT_COMMON => 5
    STT_TLS => 6
    STT_RELC => 8
    STT_SRELC => 9
    STT_LOOS => 10
    STT_GNU_IFUNC => 10
    STT_HIOS => 12
    STT_LOPROC => 13
    STT_HIPROC => 15
  }
}

///|
pub fn SymType::from_int(i : Int) -> SymType {
  match i {
    0 => STT_NOTYPE
    1 => STT_OBJECT
    2 => STT_FUNC
    3 => STT_SECTION
    4 => STT_FILE
    5 => STT_COMMON
    6 => STT_TLS
    8 => STT_RELC
    9 => STT_SRELC
    10 => STT_LOOS
    12 => STT_HIOS
    13 => STT_LOPROC
    15 => STT_HIPROC
    _ => STT_NOTYPE
  }
}

///|
/// Symbol binding and type helper functions

///|
/// Dynamic version flags.
pub(all) struct DynamicVersionFlag(UInt16) derive(Show, ToJson, Eq)

///|
/// Version definition of the file.
pub const VER_FLG_BASE : UInt = 0x1U

///|
/// Weak version identifier.
pub const VER_FLG_WEAK : UInt = 0x2U

///|
/// Reference exists for informational purposes.
pub const VER_FLG_INFO : UInt = 0x4U

///|
/// Relocation types for x86-64.
pub(all) enum R_X86_64 {
  /// 0 No relocation.
  R_X86_64_NONE
  /// 1 Add 64 bit symbol value.
  R_X86_64_64
  /// 2 PC-relative 32 bit signed sym value.
  R_X86_64_PC32
  /// 3 PC-relative 32 bit GOT offset.
  R_X86_64_GOT32
  /// 4 PC-relative 32 bit PLT offset.
  R_X86_64_PLT32
  /// 5 Copy data from shared object.
  R_X86_64_COPY
  /// 6 Set GOT entry to data address.
  R_X86_64_GLOB_DAT
  /// 7 Set GOT entry to code address.
  R_X86_64_JMP_SLOT
  /// 8 Add load address of shared object.
  R_X86_64_RELATIVE
  /// 9 Add 32 bit signed pcrel offset to GOT.
  R_X86_64_GOTPCREL
  /// 10 Add 32 bit zero extended symbol value
  R_X86_64_32
  /// 11 Add 32 bit sign extended symbol value
  R_X86_64_32S
  /// 12 Add 16 bit zero extended symbol value
  R_X86_64_16
  /// 13 Add 16 bit signed extended pc relative symbol value
  R_X86_64_PC16
  /// 14 Add 8 bit zero extended symbol value
  R_X86_64_8
  /// 15 Add 8 bit signed extended pc relative symbol value
  R_X86_64_PC8
  /// 16 ID of module containing symbol
  R_X86_64_DTPMOD64
  /// 17 Offset in TLS block
  R_X86_64_DTPOFF64
  /// 18 Offset in static TLS block
  R_X86_64_TPOFF64
  /// 19 PC relative offset to GD GOT entry
  R_X86_64_TLSGD
  /// 20 PC relative offset to LD GOT entry
  R_X86_64_TLSLD
  /// 21 Offset in TLS block
  R_X86_64_DTPOFF32
  /// 22 PC relative offset to IE GOT entry
  R_X86_64_GOTTPOFF
  /// 23 Offset in static TLS block
  R_X86_64_TPOFF32
  /// 24 PC relative 64-bit sign extended symbol value.
  R_X86_64_PC64
  /// 25
  R_X86_64_GOTOFF64
  /// 26
  R_X86_64_GOTPC32
  /// 27
  R_X86_64_GOT64
  /// 28
  R_X86_64_GOTPCREL64
  /// 29
  R_X86_64_GOTPC64
  /// 30
  R_X86_64_GOTPLT64
  /// 31
  R_X86_64_PLTOFF64
  /// 32
  R_X86_64_SIZE32
  /// 33
  R_X86_64_SIZE64
  /// 34
  R_X86_64_GOTPC32_TLSDESC
  /// 35
  R_X86_64_TLSDESC_CALL
  /// 36
  R_X86_64_TLSDESC
  /// 37
  R_X86_64_IRELATIVE
  /// 38
  R_X86_64_RELATIVE64
  /// 39
  R_X86_64_PC32_BND
  /// 40
  R_X86_64_PLT32_BND
  /// 41
  R_X86_64_GOTPCRELX
  /// 42
  R_X86_64_REX_GOTPCRELX
} derive(Eq, Show, ToJson)

///|
pub fn R_X86_64::to_int(self : R_X86_64) -> Int {
  match self {
    R_X86_64_NONE => 0
    R_X86_64_64 => 1
    R_X86_64_PC32 => 2
    R_X86_64_GOT32 => 3
    R_X86_64_PLT32 => 4
    R_X86_64_COPY => 5
    R_X86_64_GLOB_DAT => 6
    R_X86_64_JMP_SLOT => 7
    R_X86_64_RELATIVE => 8
    R_X86_64_GOTPCREL => 9
    R_X86_64_32 => 10
    R_X86_64_32S => 11
    R_X86_64_16 => 12
    R_X86_64_PC16 => 13
    R_X86_64_8 => 14
    R_X86_64_PC8 => 15
    R_X86_64_DTPMOD64 => 16
    R_X86_64_DTPOFF64 => 17
    R_X86_64_TPOFF64 => 18
    R_X86_64_TLSGD => 19
    R_X86_64_TLSLD => 20
    R_X86_64_DTPOFF32 => 21
    R_X86_64_GOTTPOFF => 22
    R_X86_64_TPOFF32 => 23
    R_X86_64_PC64 => 24
    R_X86_64_GOTOFF64 => 25
    R_X86_64_GOTPC32 => 26
    R_X86_64_GOT64 => 27
    R_X86_64_GOTPCREL64 => 28
    R_X86_64_GOTPC64 => 29
    R_X86_64_GOTPLT64 => 30
    R_X86_64_PLTOFF64 => 31
    R_X86_64_SIZE32 => 32
    R_X86_64_SIZE64 => 33
    R_X86_64_GOTPC32_TLSDESC => 34
    R_X86_64_TLSDESC_CALL => 35
    R_X86_64_TLSDESC => 36
    R_X86_64_IRELATIVE => 37
    R_X86_64_RELATIVE64 => 38
    R_X86_64_PC32_BND => 39
    R_X86_64_PLT32_BND => 40
    R_X86_64_GOTPCRELX => 41
    R_X86_64_REX_GOTPCRELX => 42
  }
}

///|
pub fn R_X86_64::from_int(i : Int) -> R_X86_64 {
  match i {
    0 => R_X86_64_NONE
    1 => R_X86_64_64
    2 => R_X86_64_PC32
    3 => R_X86_64_GOT32
    4 => R_X86_64_PLT32
    5 => R_X86_64_COPY
    6 => R_X86_64_GLOB_DAT
    7 => R_X86_64_JMP_SLOT
    8 => R_X86_64_RELATIVE
    9 => R_X86_64_GOTPCREL
    10 => R_X86_64_32
    11 => R_X86_64_32S
    12 => R_X86_64_16
    13 => R_X86_64_PC16
    14 => R_X86_64_8
    15 => R_X86_64_PC8
    16 => R_X86_64_DTPMOD64
    17 => R_X86_64_DTPOFF64
    18 => R_X86_64_TPOFF64
    19 => R_X86_64_TLSGD
    20 => R_X86_64_TLSLD
    21 => R_X86_64_DTPOFF32
    22 => R_X86_64_GOTTPOFF
    23 => R_X86_64_TPOFF32
    24 => R_X86_64_PC64
    25 => R_X86_64_GOTOFF64
    26 => R_X86_64_GOTPC32
    27 => R_X86_64_GOT64
    28 => R_X86_64_GOTPCREL64
    29 => R_X86_64_GOTPC64
    30 => R_X86_64_GOTPLT64
    31 => R_X86_64_PLTOFF64
    32 => R_X86_64_SIZE32
    33 => R_X86_64_SIZE64
    34 => R_X86_64_GOTPC32_TLSDESC
    35 => R_X86_64_TLSDESC_CALL
    36 => R_X86_64_TLSDESC
    37 => R_X86_64_IRELATIVE
    38 => R_X86_64_RELATIVE64
    39 => R_X86_64_PC32_BND
    40 => R_X86_64_PLT32_BND
    41 => R_X86_64_GOTPCRELX
    42 => R_X86_64_REX_GOTPCRELX
    _ => R_X86_64_NONE
  }
}

///|
/// Relocation types for AArch64.
pub(all) enum R_AARCH64 {
  /// 0 No relocation.
  R_AARCH64_NONE
  /// 1 - 255 Reserved.
  R_AARCH64_P32_ABS32
  /// 257 ILP32 ABS32.
  R_AARCH64_P32_COPY
  /// 258 ILP32 copy.
  R_AARCH64_P32_GLOB_DAT
  /// 259 ILP32 GOT entry.
  R_AARCH64_P32_JUMP_SLOT
  /// 260 ILP32 PLT entry.
  R_AARCH64_P32_RELATIVE
  /// 261 ILP32 relative.
  R_AARCH64_P32_TLS_DTPMOD
  /// 262 ILP32 TLS module number.
  R_AARCH64_P32_TLS_DTPREL
  /// 263 ILP32 TLS byte offset.
  R_AARCH64_P32_TLS_TPREL
  /// 264 ILP32 TLS offset.
  R_AARCH64_P32_TLSDESC
  /// 265 ILP32 TLS Descriptor.
  R_AARCH64_P32_IRELATIVE
  /// 266 ILP32 Indirect.
  R_AARCH64_ABS64
  /// 257 Direct 64 bit.
  R_AARCH64_ABS32
  /// 258 Direct 32 bit.
  R_AARCH64_ABS16
  /// 259 Direct 16-bit.
  R_AARCH64_PREL64
  /// 260 PC-relative 64-bit.
  R_AARCH64_PREL32
  /// 261 PC-relative 32-bit.
  R_AARCH64_PREL16
  /// 262 PC-relative 16-bit.
  R_AARCH64_MOVW_UABS_G0
  /// 263 Dir. MOVZ imm. from bits 15:0.
  R_AARCH64_MOVW_UABS_G0_NC
  /// 264 Dir. MOVZ imm. from bits 15:0.
  R_AARCH64_MOVW_UABS_G1
  /// 265 Dir. MOVZ imm. from bits 31:16.
  R_AARCH64_MOVW_UABS_G1_NC
  /// 266 Dir. MOVZ imm. from bits 31:16.
  R_AARCH64_MOVW_UABS_G2
  /// 267 Dir. MOVZ imm. from bits 47:32.
  R_AARCH64_MOVW_UABS_G2_NC
  /// 268 Dir. MOVZ imm. from bits 47:32.
  R_AARCH64_MOVW_UABS_G3
  /// 269 Dir. MOV{K,Z} imm. from 63:48.
  R_AARCH64_MOVW_SABS_G0
  /// 270 Dir. MOV{N,Z} imm. from 15:0.
  R_AARCH64_MOVW_SABS_G1
  /// 271 Dir. MOV{N,Z} imm. from 31:16.
  R_AARCH64_MOVW_SABS_G2
  /// 272 Dir. MOV{N,Z} imm. from 47:32.
  R_AARCH64_LD_PREL_LO19
  /// 273 PC-rel. LD imm. from bits 20:2.
  R_AARCH64_ADR_PREL_LO21
  /// 274 PC-rel. ADR imm. from bits 20:0.
  R_AARCH64_ADR_PREL_PG_HI21
  /// 275 Page-rel. ADRP imm. from 32:12.
  R_AARCH64_ADR_PREL_PG_HI21_NC
  /// 276 Page-rel. ADRP imm. from 32:12.
  R_AARCH64_ADD_ABS_LO12_NC
  /// 277 Dir. ADD imm. from bits 11:0.
  R_AARCH64_LDST8_ABS_LO12_NC
  /// 278 Dir. LDST imm. from bits 11:0.
  R_AARCH64_TSTBR14
  /// 279 PC-rel. TBZ/TBNZ imm. from 15:2.
  R_AARCH64_CONDBR19
  /// 280 PC-rel. cond. br. imm. from 20:2.
  R_AARCH64_JUMP26
  /// 281 PC-rel. B imm. from bits 27:2.
  R_AARCH64_CALL26
  /// 282 PC-rel. BL imm. from bits 27:2.
  R_AARCH64_LDST16_ABS_LO12_NC
  /// 283 Dir. LDST imm. from bits 11:1.
  R_AARCH64_LDST32_ABS_LO12_NC
  /// 284 Dir. LDST imm. from bits 11:2.
  R_AARCH64_LDST64_ABS_LO12_NC
  /// 285 Dir. LDST imm. from bits 11:3.
  R_AARCH64_MOVW_PREL_G0
  /// 286 PC-rel. MOV{N,Z} imm. from 15:0.
  R_AARCH64_MOVW_PREL_G0_NC
  /// 287 PC-rel. MOV{N,Z} imm. from 15:0.
  R_AARCH64_MOVW_PREL_G1
  /// 288 PC-rel. MOV{N,Z} imm. from 31:16.
  R_AARCH64_MOVW_PREL_G1_NC
  /// 289 PC-rel. MOV{N,Z} imm. from 31:16.
  R_AARCH64_MOVW_PREL_G2
  /// 290 PC-rel. MOV{N,Z} imm. from 47:32.
  R_AARCH64_MOVW_PREL_G2_NC
  /// 291 PC-rel. MOV{N,Z} imm. from 47:32.
  R_AARCH64_MOVW_PREL_G3
  /// 292 PC-rel. MOV{N,Z} imm. from 63:48.
  R_AARCH64_LDST128_ABS_LO12_NC
  /// 293 Dir. LDST imm. from bits 11:4.
  R_AARCH64_MOVW_GOTOFF_G0
  /// 294 GOT-rel. off. MOV{N,Z} imm. 15:0.
  R_AARCH64_MOVW_GOTOFF_G0_NC
  /// 295 GOT-rel. o. MOV{N,Z} imm. 15:0.
  R_AARCH64_MOVW_GOTOFF_G1
  /// 296 GOT-rel. o. MOV{N,Z} imm. 31:16.
  R_AARCH64_MOVW_GOTOFF_G1_NC
  /// 297 GOT-rel. o. MOV{N,Z} imm. 31:16.
  R_AARCH64_MOVW_GOTOFF_G2
  /// 298 GOT-rel. o. MOV{N,Z} imm. 47:32.
  R_AARCH64_MOVW_GOTOFF_G2_NC
  /// 299 GOT-rel. o. MOV{N,Z} imm. 47:32.
  R_AARCH64_MOVW_GOTOFF_G3
  /// 300 GOT-rel. o. MOV{N,Z} imm. 63:48.
  R_AARCH64_GOTREL64
  /// 301 GOT-relative 64-bit.
  R_AARCH64_GOTREL32
  /// 302 GOT-relative 32-bit.
  R_AARCH64_GOT_LD_PREL19
  /// 303 PC-rel. GOT off. load imm. 20:2.
  R_AARCH64_LD64_GOTOFF_LO15
  /// 304 GOT-rel. off. LD/ST imm. 14:3.
  R_AARCH64_ADR_GOT_PAGE
  /// 305 P-page-rel. GOT off. ADRP 32:12.
  R_AARCH64_LD64_GOT_LO12_NC
  /// 306 Dir. GOT off. LD/ST imm. 11:3.
  R_AARCH64_LD64_GOTPAGE_LO15
  /// 307 GOT-page-rel. GOT off. LD/ST 14:3
  R_AARCH64_TLSGD_ADR_PREL21
  /// 512 PC-relative ADR imm. 20:0.
  R_AARCH64_TLSGD_ADR_PAGE21
  /// 513 page-rel. ADRP imm. 32:12.
  R_AARCH64_TLSGD_ADD_LO12_NC
  /// 514 direct ADD imm. from 11:0.
  R_AARCH64_TLSGD_MOVW_G1
  /// 515 GOT-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSGD_MOVW_G0_NC
  /// 516 GOT-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLD_ADR_PREL21
  /// 517 PC-relative ADR imm. 20:0.
  R_AARCH64_TLSLD_ADR_PAGE21
  /// 518 page-rel. ADRP imm. 32:12.
  R_AARCH64_TLSLD_ADD_LO12_NC
  /// 519 direct ADD imm. from 11:0.
  R_AARCH64_TLSLD_MOVW_G1
  /// 520 GOT-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSLD_MOVW_G0_NC
  /// 521 GOT-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLD_LD_PREL19
  /// 522 TLS PC-rel. load imm. 20:2.
  R_AARCH64_TLSLD_MOVW_DTPREL_G2
  /// 523 TLS DTP-rel. MOV{N,Z} 47:32.
  R_AARCH64_TLSLD_MOVW_DTPREL_G1
  /// 524 TLS DTP-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSLD_MOVW_DTPREL_G1_NC
  /// 525 TLS DTP-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSLD_MOVW_DTPREL_G0
  /// 526 TLS DTP-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLD_MOVW_DTPREL_G0_NC
  /// 527 TLS DTP-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLD_ADD_DTPREL_HI12
  /// 528 TLS DTP-rel. ADD imm. 23:12.
  R_AARCH64_TLSLD_ADD_DTPREL_LO12
  /// 529 TLS DTP-rel. ADD imm. 11:0.
  R_AARCH64_TLSLD_ADD_DTPREL_LO12_NC
  /// 530 TLS DTP-rel. ADD imm. 11:0.
  R_AARCH64_TLSLD_LDST8_DTPREL_LO12
  /// 531 TLS DTP-rel. LD/ST imm. 11:0.
  R_AARCH64_TLSLD_LDST8_DTPREL_LO12_NC
  /// 532 TLS DTP-rel. LD/ST imm. 11:0.
  R_AARCH64_TLSLD_LDST16_DTPREL_LO12
  /// 533 TLS DTP-rel. LD/ST imm. 11:1.
  R_AARCH64_TLSLD_LDST16_DTPREL_LO12_NC
  /// 534 TLS DTP-rel. LD/ST imm. 11:1.
  R_AARCH64_TLSLD_LDST32_DTPREL_LO12
  /// 535 TLS DTP-rel. LD/ST imm. 11:2.
  R_AARCH64_TLSLD_LDST32_DTPREL_LO12_NC
  /// 536 TLS DTP-rel. LD/ST imm. 11:2.
  R_AARCH64_TLSLD_LDST64_DTPREL_LO12
  /// 537 TLS DTP-rel. LD/ST imm. 11:3.
  R_AARCH64_TLSLD_LDST64_DTPREL_LO12_NC
  /// 538 TLS DTP-rel. LD/ST imm. 11:3.
  R_AARCH64_TLSIE_MOVW_GOTTPREL_G1
  /// 539 TLS IE GOT-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSIE_MOVW_GOTTPREL_G0_NC
  /// 540 TLS IE GOT-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21
  /// 541 TLS IE GOT-rel. ADRP 32:12.
  R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC
  /// 542 TLS IE GOT-rel. LD/ST 11:3.
  R_AARCH64_TLSIE_LD_GOTTPREL_PREL19
  /// 543 TLS IE GOT-rel. load 20:2.
  R_AARCH64_TLSLE_MOVW_TPREL_G2
  /// 544 TLS LE TP-rel. MOV{N,Z} 47:32.
  R_AARCH64_TLSLE_MOVW_TPREL_G1
  /// 545 TLS LE TP-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSLE_MOVW_TPREL_G1_NC
  /// 546 TLS LE TP-rel. MOV{N,Z} 31:16.
  R_AARCH64_TLSLE_MOVW_TPREL_G0
  /// 547 TLS LE TP-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLE_MOVW_TPREL_G0_NC
  /// 548 TLS LE TP-rel. MOV{N,Z} 15:0.
  R_AARCH64_TLSLE_ADD_TPREL_HI12
  /// 549 TLS LE TP-rel. ADD imm. 23:12.
  R_AARCH64_TLSLE_ADD_TPREL_LO12
  /// 550 TLS LE TP-rel. ADD imm. 11:0.
  R_AARCH64_TLSLE_ADD_TPREL_LO12_NC
  /// 551 TLS LE TP-rel. ADD imm. 11:0.
  R_AARCH64_TLSLE_LDST8_TPREL_LO12
  /// 552 TLS LE TP-rel. LD/ST 11:0.
  R_AARCH64_TLSLE_LDST8_TPREL_LO12_NC
  /// 553 TLS LE TP-rel. LD/ST 11:0.
  R_AARCH64_TLSLE_LDST16_TPREL_LO12
  /// 554 TLS LE TP-rel. LD/ST 11:1.
  R_AARCH64_TLSLE_LDST16_TPREL_LO12_NC
  /// 555 TLS LE TP-rel. LD/ST 11:1.
  R_AARCH64_TLSLE_LDST32_TPREL_LO12
  /// 556 TLS LE TP-rel. LD/ST 11:2.
  R_AARCH64_TLSLE_LDST32_TPREL_LO12_NC
  /// 557 TLS LE TP-rel. LD/ST 11:2.
  R_AARCH64_TLSLE_LDST64_TPREL_LO12
  /// 558 TLS LE TP-rel. LD/ST 11:3.
  R_AARCH64_TLSLE_LDST64_TPREL_LO12_NC
  /// 559 TLS LE TP-rel. LD/ST 11:3.
  R_AARCH64_TLSDESC_LD_PREL19
  /// 560 TLS DESC PC-rel. load 20:2.
  R_AARCH64_TLSDESC_ADR_PREL21
  /// 561 TLS DESC PC-rel. ADR 20:0.
  R_AARCH64_TLSDESC_ADR_PAGE21
  /// 562 TLS DESC PC-rel. ADRP 32:12.
  R_AARCH64_TLSDESC_LD64_LO12
  /// 563 TLS DESC LD/ST imm. 11:3.
  R_AARCH64_TLSDESC_ADD_LO12
  /// 564 TLS DESC ADD imm. 11:0.
  R_AARCH64_TLSDESC_OFF_G1
  /// 565 TLS DESC MOV{N,Z} 31:16.
  R_AARCH64_TLSDESC_OFF_G0_NC
  /// 566 TLS DESC MOV{N,Z} 15:0.
  R_AARCH64_TLSDESC_LDR
  /// 567 TLS DESC load.
  R_AARCH64_TLSDESC_ADD
  /// 568 TLS DESC add.
  R_AARCH64_TLSDESC_CALL
  /// 569 TLS DESC call.
  R_AARCH64_TLSLE_LDST128_TPREL_LO12
  /// 570 TLS LE TP-rel. LD/ST 11:4.
  R_AARCH64_TLSLE_LDST128_TPREL_LO12_NC
  /// 571 TLS LE TP-rel. LD/ST 11:4.
  R_AARCH64_TLSLD_LDST128_DTPREL_LO12
  /// 572 TLS DTP-rel. LD/ST imm. 11:4.
  R_AARCH64_TLSLD_LDST128_DTPREL_LO12_NC
  /// 573 TLS DTP-rel. LD/ST imm. 11:4.
  R_AARCH64_COPY
  /// 1024 Copy symbol at runtime.
  R_AARCH64_GLOB_DAT
  /// 1025 Create GOT entry.
  R_AARCH64_JUMP_SLOT
  /// 1026 Create PLT entry.
  R_AARCH64_RELATIVE
  /// 1027 Adjust by program base.
  R_AARCH64_TLS_DTPMOD64
  /// 1028 Module number, 64 bit.
  R_AARCH64_TLS_DTPREL64
  /// 1029 Module-relative offset, 64 bit.
  R_AARCH64_TLS_TPREL64
  /// 1030 TP-relative offset, 64 bit.
  R_AARCH64_TLSDESC
  /// 1031 TLS Descriptor.
  R_AARCH64_IRELATIVE
  /// 1032 STT_GNU_IFUNC relocation.
} derive(Eq, Show, ToJson)

///|
/// Relocation types for Alpha.
pub(all) enum R_ALPHA {
  /// 0 No reloc
  R_ALPHA_NONE
  /// 1 Direct 32 bit
  R_ALPHA_REFLONG
  /// 2 Direct 64 bit
  R_ALPHA_REFQUAD
  /// 3 GP relative 32 bit
  R_ALPHA_GPREL32
  /// 4 GP relative 16 bit w/optimization
  R_ALPHA_LITERAL
  /// 5 Optimization hint for LITERAL
  R_ALPHA_LITUSE
  /// 6 Add displacement to GP
  R_ALPHA_GPDISP
  /// 7 PC+4 relative 23 bit shifted
  R_ALPHA_BRADDR
  /// 8 PC+4 relative 16 bit shifted
  R_ALPHA_HINT
  /// 9 PC relative 16 bit
  R_ALPHA_SREL16
  /// 10 PC relative 32 bit
  R_ALPHA_SREL32
  /// 11 PC relative 64 bit
  R_ALPHA_SREL64
  /// 12 OP stack push
  R_ALPHA_OP_PUSH
  /// 13 OP stack pop and store
  R_ALPHA_OP_STORE
  /// 14 OP stack subtract
  R_ALPHA_OP_PSUB
  /// 15 OP stack right shift
  R_ALPHA_OP_PRSHIFT
  /// 16
  R_ALPHA_GPVALUE
  /// 17
  R_ALPHA_GPRELHIGH
  /// 18
  R_ALPHA_GPRELLOW
  /// 19
  R_ALPHA_IMMED_GP_16
  /// 20
  R_ALPHA_IMMED_GP_HI32
  /// 21
  R_ALPHA_IMMED_SCN_HI32
  /// 22
  R_ALPHA_IMMED_BR_HI32
  /// 23
  R_ALPHA_IMMED_LO32
  /// 24 Copy symbol at runtime
  R_ALPHA_COPY
  /// 25 Create GOT entry
  R_ALPHA_GLOB_DAT
  /// 26 Create PLT entry
  R_ALPHA_JMP_SLOT
  /// 27 Adjust by program base
  R_ALPHA_RELATIVE
} derive(Eq, Show, ToJson)

///|
/// Relocation types for ARM.
pub(all) enum R_ARM {
  /// 0 No relocation.
  R_ARM_NONE
  /// 1
  R_ARM_PC24
  /// 2
  R_ARM_ABS32
  /// 3
  R_ARM_REL32
  /// 4
  R_ARM_PC13
  /// 5
  R_ARM_ABS16
  /// 6
  R_ARM_ABS12
  /// 7
  R_ARM_THM_ABS5
  /// 8
  R_ARM_ABS8
  /// 9
  R_ARM_SBREL32
  /// 10
  R_ARM_THM_PC22
  /// 11
  R_ARM_THM_PC8
  /// 12
  R_ARM_AMP_VCALL9
  /// 13
  R_ARM_SWI24
  /// 14
  R_ARM_THM_SWI8
  /// 15
  R_ARM_XPC25
  /// 16
  R_ARM_THM_XPC22
  /// 17
  R_ARM_TLS_DTPMOD32
  /// 18
  R_ARM_TLS_DTPOFF32
  /// 19
  R_ARM_TLS_TPOFF32
  /// 20 Copy data from shared object.
  R_ARM_COPY
  /// 21 Set GOT entry to data address.
  R_ARM_GLOB_DAT
  /// 22 Set GOT entry to code address.
  R_ARM_JUMP_SLOT
  /// 23 Add load address of shared object.
  R_ARM_RELATIVE
  /// 24 Add GOT-relative symbol address.
  R_ARM_GOTOFF
  /// 25 Add PC-relative GOT table address.
  R_ARM_GOTPC
  /// 26 Add PC-relative GOT offset.
  R_ARM_GOT32
  /// 27 Add PC-relative PLT offset.
  R_ARM_PLT32
  /// 28
  R_ARM_CALL
  /// 29
  R_ARM_JUMP24
  /// 30
  R_ARM_THM_JUMP24
  /// 31
  R_ARM_BASE_ABS
  /// 32
  R_ARM_ALU_PCREL_7_0
  /// 33
  R_ARM_ALU_PCREL_15_8
  /// 34
  R_ARM_ALU_PCREL_23_15
  /// 35
  R_ARM_LDR_SBREL_11_10_NC
  /// 36
  R_ARM_ALU_SBREL_19_12_NC
  /// 37
  R_ARM_ALU_SBREL_27_20_CK
  /// 38
  R_ARM_TARGET1
  /// 39
  R_ARM_SBREL31
  /// 40
  R_ARM_V4BX
  /// 41
  R_ARM_TARGET2
  /// 42
  R_ARM_PREL31
  /// 43
  R_ARM_MOVW_ABS_NC
  /// 44
  R_ARM_MOVT_ABS
  /// 45
  R_ARM_MOVW_PREL_NC
  /// 46
  R_ARM_MOVT_PREL
  /// 47
  R_ARM_THM_MOVW_ABS_NC
  /// 48
  R_ARM_THM_MOVT_ABS
  /// 49
  R_ARM_THM_MOVW_PREL_NC
  /// 50
  R_ARM_THM_MOVT_PREL
  /// 51
  R_ARM_THM_JUMP19
  /// 52
  R_ARM_THM_JUMP6
  /// 53
  R_ARM_THM_ALU_PREL_11_0
  /// 54
  R_ARM_THM_PC12
  /// 55
  R_ARM_ABS32_NOI
  /// 56
  R_ARM_REL32_NOI
  /// 57
  R_ARM_ALU_PC_G0_NC
  /// 58
  R_ARM_ALU_PC_G0
  /// 59
  R_ARM_ALU_PC_G1_NC
  /// 60
  R_ARM_ALU_PC_G1
  /// 61
  R_ARM_ALU_PC_G2
  /// 62
  R_ARM_LDR_PC_G1
  /// 63
  R_ARM_LDR_PC_G2
  /// 64
  R_ARM_LDRS_PC_G0
  /// 65
  R_ARM_LDRS_PC_G1
  /// 66
  R_ARM_LDRS_PC_G2
  /// 67
  R_ARM_LDC_PC_G0
  /// 68
  R_ARM_LDC_PC_G1
  /// 69
  R_ARM_LDC_PC_G2
  /// 70
  R_ARM_ALU_SB_G0_NC
  /// 71
  R_ARM_ALU_SB_G0
  /// 72
  R_ARM_ALU_SB_G1_NC
  /// 73
  R_ARM_ALU_SB_G1
  /// 74
  R_ARM_ALU_SB_G2
  /// 75
  R_ARM_LDR_SB_G0
  /// 76
  R_ARM_LDR_SB_G1
  /// 77
  R_ARM_LDR_SB_G2
  /// 78
  R_ARM_LDRS_SB_G0
  /// 79
  R_ARM_LDRS_SB_G1
  /// 80
  R_ARM_LDRS_SB_G2
  /// 81
  R_ARM_LDC_SB_G0
  /// 82
  R_ARM_LDC_SB_G1
  /// 83
  R_ARM_LDC_SB_G2
  /// 84
  R_ARM_MOVW_BREL_NC
  /// 85
  R_ARM_MOVT_BREL
  /// 86
  R_ARM_MOVW_BREL
  /// 87
  R_ARM_THM_MOVW_BREL_NC
  /// 88
  R_ARM_THM_MOVT_BREL
  /// 89
  R_ARM_THM_MOVW_BREL
  /// 90
  R_ARM_TLS_GOTDESC
  /// 91
  R_ARM_TLS_CALL
  /// 92
  R_ARM_TLS_DESCSEQ
  /// 93
  R_ARM_THM_TLS_CALL
  /// 94
  R_ARM_PLT32_ABS
  /// 95
  R_ARM_GOT_ABS
  /// 96
  R_ARM_GOT_PREL
  /// 97
  R_ARM_GOT_BREL12
  /// 98
  R_ARM_GOTOFF12
  /// 99
  R_ARM_GOTRELAX
  /// 100
  R_ARM_GNU_VTENTRY
  /// 101
  R_ARM_GNU_VTINHERIT
  /// 102
  R_ARM_THM_JUMP11
  /// 103
  R_ARM_THM_JUMP8
  /// 104
  R_ARM_TLS_GD32
  /// 105
  R_ARM_TLS_LDM32
  /// 106
  R_ARM_TLS_LDO32
  /// 107
  R_ARM_TLS_IE32
  /// 108
  R_ARM_TLS_LE32
  /// 109
  R_ARM_TLS_LDO12
  /// 110
  R_ARM_TLS_LE12
  /// 111
  R_ARM_TLS_IE12GP
  /// 112
  R_ARM_PRIVATE_0
  /// 113
  R_ARM_PRIVATE_1
  /// 114
  R_ARM_PRIVATE_2
  /// 115
  R_ARM_PRIVATE_3
  /// 116
  R_ARM_PRIVATE_4
  /// 117
  R_ARM_PRIVATE_5
  /// 118
  R_ARM_PRIVATE_6
  /// 119
  R_ARM_PRIVATE_7
  /// 120
  R_ARM_PRIVATE_8
  /// 121
  R_ARM_PRIVATE_9
  /// 122
  R_ARM_PRIVATE_10
  /// 123
  R_ARM_PRIVATE_11
  /// 124
  R_ARM_PRIVATE_12
  /// 125
  R_ARM_PRIVATE_13
  /// 126
  R_ARM_PRIVATE_14
  /// 127
  R_ARM_PRIVATE_15
  /// 128
  R_ARM_ME_TOO
  /// 129
  R_ARM_THM_TLS_DESCSEQ16
  /// 130
  R_ARM_THM_TLS_DESCSEQ32
  /// 131
  R_ARM_THM_GOT_BREL12
  /// 132
  R_ARM_THM_ALU_ABS_G0_NC
  /// 133
  R_ARM_THM_ALU_ABS_G1_NC
  /// 134
  R_ARM_THM_ALU_ABS_G2_NC
  /// 135
  R_ARM_THM_ALU_ABS_G3
  /// 160
  R_ARM_IRELATIVE
  /// 249
  R_ARM_RXPC25
  /// 250
  R_ARM_RSBREL32
  /// 251
  R_ARM_THM_RPC22
  /// 252
  R_ARM_RREL32
  /// 253
  R_ARM_RABS32
  /// 254
  R_ARM_RPC24
  /// 255
  R_ARM_RBASE
} derive(Eq, Show, ToJson)

///|
/// Relocation types for 386.
pub(all) enum R_386 {
  /// 0 No relocation.
  R_386_NONE
  /// 1 Add symbol value.
  R_386_32
  /// 2 Add PC-relative symbol value.
  R_386_PC32
  /// 3 Add PC-relative GOT offset.
  R_386_GOT32
  /// 4 Add PC-relative PLT offset.
  R_386_PLT32
  /// 5 Copy data from shared object.
  R_386_COPY
  /// 6 Set GOT entry to data address.
  R_386_GLOB_DAT
  /// 7 Set GOT entry to code address.
  R_386_JMP_SLOT
  /// 8 Add load address of shared object.
  R_386_RELATIVE
  /// 9 Add GOT-relative symbol address.
  R_386_GOTOFF
  /// 10 Add PC-relative GOT table address.
  R_386_GOTPC
  /// 11
  R_386_32PLT
  /// 14 Negative offset in static TLS block
  R_386_TLS_TPOFF
  /// 15 Absolute address of GOT for -ve static TLS
  R_386_TLS_IE
  /// 16 GOT entry for negative static TLS block
  R_386_TLS_GOTIE
  /// 17 Negative offset relative to static TLS
  R_386_TLS_LE
  /// 18 32 bit offset to GOT (index,off) pair
  R_386_TLS_GD
  /// 19 32 bit offset to GOT (index,zero) pair
  R_386_TLS_LDM
  /// 20
  R_386_16
  /// 21
  R_386_PC16
  /// 22
  R_386_8
  /// 23
  R_386_PC8
  /// 24 32 bit offset to GOT (index,off) pair
  R_386_TLS_GD_32
  /// 25 pushl instruction for Sun ABI GD sequence
  R_386_TLS_GD_PUSH
  /// 26 call instruction for Sun ABI GD sequence
  R_386_TLS_GD_CALL
  /// 27 popl instruction for Sun ABI GD sequence
  R_386_TLS_GD_POP
  /// 28 32 bit offset to GOT (index,zero) pair
  R_386_TLS_LDM_32
  /// 29 pushl instruction for Sun ABI LD sequence
  R_386_TLS_LDM_PUSH
  /// 30 call instruction for Sun ABI LD sequence
  R_386_TLS_LDM_CALL
  /// 31 popl instruction for Sun ABI LD sequence
  R_386_TLS_LDM_POP
  /// 32 32 bit offset from start of TLS block
  R_386_TLS_LDO_32
  /// 33 32 bit offset to GOT static TLS offset entry
  R_386_TLS_IE_32
  /// 34 32 bit offset within static TLS block
  R_386_TLS_LE_32
  /// 35 GOT entry containing TLS index
  R_386_TLS_DTPMOD32
  /// 36 GOT entry containing TLS offset
  R_386_TLS_DTPOFF32
  /// 37 GOT entry of -ve static TLS offset
  R_386_TLS_TPOFF32
  /// 38
  R_386_SIZE32
  /// 39
  R_386_TLS_GOTDESC
  /// 40
  R_386_TLS_DESC_CALL
  /// 41
  R_386_TLS_DESC
  /// 42
  R_386_IRELATIVE
  /// 43
  R_386_GOT32X
} derive(Eq, Show, ToJson)

///|
pub fn R_386::to_int(self : R_386) -> Int {
  match self {
    R_386_NONE => 0
    R_386_32 => 1
    R_386_PC32 => 2
    R_386_GOT32 => 3
    R_386_PLT32 => 4
    R_386_COPY => 5
    R_386_GLOB_DAT => 6
    R_386_JMP_SLOT => 7
    R_386_RELATIVE => 8
    R_386_GOTOFF => 9
    R_386_GOTPC => 10
    R_386_32PLT => 11
    R_386_TLS_TPOFF => 14
    R_386_TLS_IE => 15
    R_386_TLS_GOTIE => 16
    R_386_TLS_LE => 17
    R_386_TLS_GD => 18
    R_386_TLS_LDM => 19
    R_386_16 => 20
    R_386_PC16 => 21
    R_386_8 => 22
    R_386_PC8 => 23
    R_386_TLS_GD_32 => 24
    R_386_TLS_GD_PUSH => 25
    R_386_TLS_GD_CALL => 26
    R_386_TLS_GD_POP => 27
    R_386_TLS_LDM_32 => 28
    R_386_TLS_LDM_PUSH => 29
    R_386_TLS_LDM_CALL => 30
    R_386_TLS_LDM_POP => 31
    R_386_TLS_LDO_32 => 32
    R_386_TLS_IE_32 => 33
    R_386_TLS_LE_32 => 34
    R_386_TLS_DTPMOD32 => 35
    R_386_TLS_DTPOFF32 => 36
    R_386_TLS_TPOFF32 => 37
    R_386_SIZE32 => 38
    R_386_TLS_GOTDESC => 39
    R_386_TLS_DESC_CALL => 40
    R_386_TLS_DESC => 41
    R_386_IRELATIVE => 42
    R_386_GOT32X => 43
  }
}

///|
pub fn R_386::from_int(i : Int) -> R_386 {
  match i {
    0 => R_386_NONE
    1 => R_386_32
    2 => R_386_PC32
    3 => R_386_GOT32
    4 => R_386_PLT32
    5 => R_386_COPY
    6 => R_386_GLOB_DAT
    7 => R_386_JMP_SLOT
    8 => R_386_RELATIVE
    9 => R_386_GOTOFF
    10 => R_386_GOTPC
    11 => R_386_32PLT
    14 => R_386_TLS_TPOFF
    15 => R_386_TLS_IE
    16 => R_386_TLS_GOTIE
    17 => R_386_TLS_LE
    18 => R_386_TLS_GD
    19 => R_386_TLS_LDM
    20 => R_386_16
    21 => R_386_PC16
    22 => R_386_8
    23 => R_386_PC8
    24 => R_386_TLS_GD_32
    25 => R_386_TLS_GD_PUSH
    26 => R_386_TLS_GD_CALL
    27 => R_386_TLS_GD_POP
    28 => R_386_TLS_LDM_32
    29 => R_386_TLS_LDM_PUSH
    30 => R_386_TLS_LDM_CALL
    31 => R_386_TLS_LDM_POP
    32 => R_386_TLS_LDO_32
    33 => R_386_TLS_IE_32
    34 => R_386_TLS_LE_32
    35 => R_386_TLS_DTPMOD32
    36 => R_386_TLS_DTPOFF32
    37 => R_386_TLS_TPOFF32
    38 => R_386_SIZE32
    39 => R_386_TLS_GOTDESC
    40 => R_386_TLS_DESC_CALL
    41 => R_386_TLS_DESC
    42 => R_386_IRELATIVE
    43 => R_386_GOT32X
    _ => R_386_NONE
  }
}

///|
/// Relocation types for MIPS.
pub(all) enum R_MIPS {
  /// 0
  R_MIPS_NONE
  /// 1
  R_MIPS_16
  /// 2
  R_MIPS_32
  /// 3
  R_MIPS_REL32
  /// 4
  R_MIPS_26
  /// 5 high 16 bits of symbol value
  R_MIPS_HI16
  /// 6 low 16 bits of symbol value
  R_MIPS_LO16
  /// 7 GP-relative reference
  R_MIPS_GPREL16
  /// 8 Reference to literal section
  R_MIPS_LITERAL
  /// 9 Reference to global offset table
  R_MIPS_GOT16
  /// 10 16 bit PC relative reference
  R_MIPS_PC16
  /// 11 16 bit call through glbl offset tbl
  R_MIPS_CALL16
  /// 12
  R_MIPS_GPREL32
  /// 16
  R_MIPS_SHIFT5
  /// 17
  R_MIPS_SHIFT6
  /// 18
  R_MIPS_64
  /// 19
  R_MIPS_GOT_DISP
  /// 20
  R_MIPS_GOT_PAGE
  /// 21
  R_MIPS_GOT_OFST
  /// 22
  R_MIPS_GOT_HI16
  /// 23
  R_MIPS_GOT_LO16
  /// 24
  R_MIPS_SUB
  /// 25
  R_MIPS_INSERT_A
  /// 26
  R_MIPS_INSERT_B
  /// 27
  R_MIPS_DELETE
  /// 28
  R_MIPS_HIGHER
  /// 29
  R_MIPS_HIGHEST
  /// 30
  R_MIPS_CALL_HI16
  /// 31
  R_MIPS_CALL_LO16
  /// 32
  R_MIPS_SCN_DISP
  /// 33
  R_MIPS_REL16
  /// 34
  R_MIPS_ADD_IMMEDIATE
  /// 35
  R_MIPS_PJUMP
  /// 36
  R_MIPS_RELGOT
  /// 37
  R_MIPS_JALR
  /// 38 Module number 32 bit
  R_MIPS_TLS_DTPMOD32
  /// 39 Module-relative offset 32 bit
  R_MIPS_TLS_DTPREL32
  /// 40 Module number 64 bit
  R_MIPS_TLS_DTPMOD64
  /// 41 Module-relative offset 64 bit
  R_MIPS_TLS_DTPREL64
  /// 42 16 bit GOT offset for GD
  R_MIPS_TLS_GD
  /// 43 16 bit GOT offset for LDM
  R_MIPS_TLS_LDM
  /// 44 Module-relative offset, high 16 bits
  R_MIPS_TLS_DTPREL_HI16
  /// 45 Module-relative offset, low 16 bits
  R_MIPS_TLS_DTPREL_LO16
  /// 46 16 bit GOT offset for IE
  R_MIPS_TLS_GOTTPREL
  /// 47 TP-relative offset, 32 bit
  R_MIPS_TLS_TPREL32
  /// 48 TP-relative offset, 64 bit
  R_MIPS_TLS_TPREL64
  /// 49 TP-relative offset, high 16 bits
  R_MIPS_TLS_TPREL_HI16
  /// 50 TP-relative offset, low 16 bits
  R_MIPS_TLS_TPREL_LO16
  /// 248 32 bit PC relative reference
  R_MIPS_PC32
} derive(Eq, Show, ToJson)

///|
pub fn R_MIPS::to_int(self : R_MIPS) -> Int {
  match self {
    R_MIPS_NONE => 0
    R_MIPS_16 => 1
    R_MIPS_32 => 2
    R_MIPS_REL32 => 3
    R_MIPS_26 => 4
    R_MIPS_HI16 => 5
    R_MIPS_LO16 => 6
    R_MIPS_GPREL16 => 7
    R_MIPS_LITERAL => 8
    R_MIPS_GOT16 => 9
    R_MIPS_PC16 => 10
    R_MIPS_CALL16 => 11
    R_MIPS_GPREL32 => 12
    R_MIPS_SHIFT5 => 16
    R_MIPS_SHIFT6 => 17
    R_MIPS_64 => 18
    R_MIPS_GOT_DISP => 19
    R_MIPS_GOT_PAGE => 20
    R_MIPS_GOT_OFST => 21
    R_MIPS_GOT_HI16 => 22
    R_MIPS_GOT_LO16 => 23
    R_MIPS_SUB => 24
    R_MIPS_INSERT_A => 25
    R_MIPS_INSERT_B => 26
    R_MIPS_DELETE => 27
    R_MIPS_HIGHER => 28
    R_MIPS_HIGHEST => 29
    R_MIPS_CALL_HI16 => 30
    R_MIPS_CALL_LO16 => 31
    R_MIPS_SCN_DISP => 32
    R_MIPS_REL16 => 33
    R_MIPS_ADD_IMMEDIATE => 34
    R_MIPS_PJUMP => 35
    R_MIPS_RELGOT => 36
    R_MIPS_JALR => 37
    R_MIPS_TLS_DTPMOD32 => 38
    R_MIPS_TLS_DTPREL32 => 39
    R_MIPS_TLS_DTPMOD64 => 40
    R_MIPS_TLS_DTPREL64 => 41
    R_MIPS_TLS_GD => 42
    R_MIPS_TLS_LDM => 43
    R_MIPS_TLS_DTPREL_HI16 => 44
    R_MIPS_TLS_DTPREL_LO16 => 45
    R_MIPS_TLS_GOTTPREL => 46
    R_MIPS_TLS_TPREL32 => 47
    R_MIPS_TLS_TPREL64 => 48
    R_MIPS_TLS_TPREL_HI16 => 49
    R_MIPS_TLS_TPREL_LO16 => 50
    R_MIPS_PC32 => 248
  }
}

///|
pub fn R_MIPS::from_int(i : Int) -> R_MIPS {
  match i {
    0 => R_MIPS_NONE
    1 => R_MIPS_16
    2 => R_MIPS_32
    3 => R_MIPS_REL32
    4 => R_MIPS_26
    5 => R_MIPS_HI16
    6 => R_MIPS_LO16
    7 => R_MIPS_GPREL16
    8 => R_MIPS_LITERAL
    9 => R_MIPS_GOT16
    10 => R_MIPS_PC16
    11 => R_MIPS_CALL16
    12 => R_MIPS_GPREL32
    16 => R_MIPS_SHIFT5
    17 => R_MIPS_SHIFT6
    18 => R_MIPS_64
    19 => R_MIPS_GOT_DISP
    20 => R_MIPS_GOT_PAGE
    21 => R_MIPS_GOT_OFST
    22 => R_MIPS_GOT_HI16
    23 => R_MIPS_GOT_LO16
    24 => R_MIPS_SUB
    25 => R_MIPS_INSERT_A
    26 => R_MIPS_INSERT_B
    27 => R_MIPS_DELETE
    28 => R_MIPS_HIGHER
    29 => R_MIPS_HIGHEST
    30 => R_MIPS_CALL_HI16
    31 => R_MIPS_CALL_LO16
    32 => R_MIPS_SCN_DISP
    33 => R_MIPS_REL16
    34 => R_MIPS_ADD_IMMEDIATE
    35 => R_MIPS_PJUMP
    36 => R_MIPS_RELGOT
    37 => R_MIPS_JALR
    38 => R_MIPS_TLS_DTPMOD32
    39 => R_MIPS_TLS_DTPREL32
    40 => R_MIPS_TLS_DTPMOD64
    41 => R_MIPS_TLS_DTPREL64
    42 => R_MIPS_TLS_GD
    43 => R_MIPS_TLS_LDM
    44 => R_MIPS_TLS_DTPREL_HI16
    45 => R_MIPS_TLS_DTPREL_LO16
    46 => R_MIPS_TLS_GOTTPREL
    47 => R_MIPS_TLS_TPREL32
    48 => R_MIPS_TLS_TPREL64
    49 => R_MIPS_TLS_TPREL_HI16
    50 => R_MIPS_TLS_TPREL_LO16
    248 => R_MIPS_PC32
    _ => R_MIPS_NONE
  }
}
