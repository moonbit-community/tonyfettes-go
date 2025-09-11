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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn OSABI::to_int(self : OSABI) -> Int {
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
pub fn OSABI::from_int(i : Int) -> OSABI {
  match i {
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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn SectionType::to_int(self : SectionType) -> Int {
  match self {
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
pub fn SectionType::from_int(i : Int) -> SectionType {
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
    _ => SHT_NULL
  }
}

///|
/// Section flags.
pub(all) enum SectionFlag {
  /// 0x1        Section contains writable data.
  SHF_WRITE
  /// 0x2        Section occupies memory.
  SHF_ALLOC
  /// 0x4        Section contains instructions.
  SHF_EXECINSTR
  /// 0x10       Section may be merged.
  SHF_MERGE
  /// 0x20       Section contains strings.
  SHF_STRINGS
  /// 0x40       sh_info holds section index.
  SHF_INFO_LINK
  /// 0x80       Special ordering requirements.
  SHF_LINK_ORDER
  /// 0x100      OS-specific processing required.
  SHF_OS_NONCONFORMING
  /// 0x200      Member of section group.
  SHF_GROUP
  /// 0x400      Section contains TLS data.
  SHF_TLS
  /// 0x800      Section is compressed.
  SHF_COMPRESSED
  /// 0x0ff00000 OS-specific semantics.
  SHF_MASKOS
  /// 0xf0000000 Processor-specific semantics.
  SHF_MASKPROC
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn SectionFlag::to_int(self : SectionFlag) -> Int {
  match self {
    SHF_WRITE => 0x1
    SHF_ALLOC => 0x2
    SHF_EXECINSTR => 0x4
    SHF_MERGE => 0x10
    SHF_STRINGS => 0x20
    SHF_INFO_LINK => 0x40
    SHF_LINK_ORDER => 0x80
    SHF_OS_NONCONFORMING => 0x100
    SHF_GROUP => 0x200
    SHF_TLS => 0x400
    SHF_COMPRESSED => 0x800
    SHF_MASKOS => 0x0ff00000
    SHF_MASKPROC => 0xf0000000
  }
}

///|
/// Section compression type.
pub(all) enum CompressionType {
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
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn CompressionType::to_int(self : CompressionType) -> Int {
  match self {
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
} derive(Eq, Show, ToJson(style="flat"))

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
} derive(Eq, Show, ToJson(style="flat"))

///|
pub fn ProgFlag::to_int(self : ProgFlag) -> Int {
  match self {
    PF_X => 0x1
    PF_W => 0x2
    PF_R => 0x4
    PF_MASKOS => 0x0ff00000
    PF_MASKPROC => 0xf0000000
  }
}
