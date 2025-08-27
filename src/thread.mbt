/// Thread State Parsing
/// 
/// Handles parsing of thread state structures and register values from
/// Mach-O THREAD and UNIXTHREAD load commands.
/// Based on Apple's Mach-O specification and Go's debug/macho implementation.

///|
/// 32-bit x86 register structure
pub struct Regs386 {
  ax : UInt // EAX register
  bx : UInt // EBX register
  cx : UInt // ECX register
  dx : UInt // EDX register
  di : UInt // EDI register
  si : UInt // ESI register
  bp : UInt // EBP register (base pointer)
  sp : UInt // ESP register (stack pointer)
  ss : UInt // SS segment register
  flags : UInt // EFLAGS register
  ip : UInt // EIP instruction pointer
  cs : UInt // CS segment register
  ds : UInt // DS segment register
  es : UInt // ES segment register
  fs : UInt // FS segment register
  gs : UInt // GS segment register
} derive(Eq, Show)

///|
/// 64-bit AMD64/x86_64 register structure
pub struct RegsAMD64 {
  ax : UInt64 // RAX register
  bx : UInt64 // RBX register
  cx : UInt64 // RCX register
  dx : UInt64 // RDX register
  di : UInt64 // RDI register
  si : UInt64 // RSI register
  bp : UInt64 // RBP register (base pointer)
  sp : UInt64 // RSP register (stack pointer)
  r8 : UInt64 // R8 register
  r9 : UInt64 // R9 register
  r10 : UInt64 // R10 register
  r11 : UInt64 // R11 register
  r12 : UInt64 // R12 register
  r13 : UInt64 // R13 register
  r14 : UInt64 // R14 register
  r15 : UInt64 // R15 register
  ip : UInt64 // RIP instruction pointer
  flags : UInt64 // RFLAGS register
  cs : UInt64 // CS segment register
  fs : UInt64 // FS segment register
  gs : UInt64 // GS segment register
} derive(Eq, Show)

///|
/// Thread state information for different architectures
pub enum ThreadState {
  I386(Regs386) // 32-bit x86 thread state
  AMD64(RegsAMD64) // 64-bit AMD64 thread state
  Unknown(Bytes) // Raw thread state data for unsupported architectures
} derive(Show)

///|
/// Parse thread state from raw thread command data
pub fn parse_thread_state(
  data : Bytes,
  cpu_type : Cpu,
  byte_order : ByteOrder,
) -> ThreadState raise {
  match cpu_type {
    I386 => {
      let regs = parse_regs_386(data, byte_order)
      I386(regs)
    }
    Amd64 => {
      let regs = parse_regs_amd64(data, byte_order)
      AMD64(regs)
    }
    _ =>
      // For unsupported architectures, return raw data
      Unknown(data)
  }
}

///|
/// Parse 32-bit x86 register state
fn parse_regs_386(data : Bytes, byte_order : ByteOrder) -> Regs386 raise {
  // x86 thread state should be 64 bytes (16 registers * 4 bytes each)
  let expected_size = 64
  if data.length() < expected_size {
    raise ParseError::MissingData(
      offset=0L,
      expected="i386 thread state (64 bytes)",
    )
  }
  {
    ax: read_uint(data, 0, byte_order),
    bx: read_uint(data, 4, byte_order),
    cx: read_uint(data, 8, byte_order),
    dx: read_uint(data, 12, byte_order),
    di: read_uint(data, 16, byte_order),
    si: read_uint(data, 20, byte_order),
    bp: read_uint(data, 24, byte_order),
    sp: read_uint(data, 28, byte_order),
    ss: read_uint(data, 32, byte_order),
    flags: read_uint(data, 36, byte_order),
    ip: read_uint(data, 40, byte_order),
    cs: read_uint(data, 44, byte_order),
    ds: read_uint(data, 48, byte_order),
    es: read_uint(data, 52, byte_order),
    fs: read_uint(data, 56, byte_order),
    gs: read_uint(data, 60, byte_order),
  }
}

///|
/// Parse 64-bit AMD64 register state
fn parse_regs_amd64(data : Bytes, byte_order : ByteOrder) -> RegsAMD64 raise {
  // AMD64 thread state should be 168 bytes (21 registers * 8 bytes each)
  let expected_size = 168
  if data.length() < expected_size {
    raise ParseError::MissingData(
      offset=0L,
      expected="AMD64 thread state (168 bytes)",
    )
  }
  {
    ax: read_uint64(data, 0, byte_order),
    bx: read_uint64(data, 8, byte_order),
    cx: read_uint64(data, 16, byte_order),
    dx: read_uint64(data, 24, byte_order),
    di: read_uint64(data, 32, byte_order),
    si: read_uint64(data, 40, byte_order),
    bp: read_uint64(data, 48, byte_order),
    sp: read_uint64(data, 56, byte_order),
    r8: read_uint64(data, 64, byte_order),
    r9: read_uint64(data, 72, byte_order),
    r10: read_uint64(data, 80, byte_order),
    r11: read_uint64(data, 88, byte_order),
    r12: read_uint64(data, 96, byte_order),
    r13: read_uint64(data, 104, byte_order),
    r14: read_uint64(data, 112, byte_order),
    r15: read_uint64(data, 120, byte_order),
    ip: read_uint64(data, 128, byte_order),
    flags: read_uint64(data, 136, byte_order),
    cs: read_uint64(data, 144, byte_order),
    fs: read_uint64(data, 152, byte_order),
    gs: read_uint64(data, 160, byte_order),
  }
}

///|
/// Extract thread state from a Thread load command
pub fn extract_thread_state(
  thread : Thread,
  cpu_type : Cpu,
  byte_order : ByteOrder,
) -> ThreadState raise {
  // The thread command data contains the thread state
  let thread_data = thread.raw()

  // Skip the load command header (8 bytes: cmd + cmdsize)
  let state_data = read_bytes(thread_data, 8, thread_data.length() - 8)
  parse_thread_state(state_data, cpu_type, byte_order)
}

///|
/// Format register values for debugging/display
pub fn format_regs_386(regs : Regs386) -> String {
  "i386 Registers:\n" +
  "  EAX=0x" +
  regs.ax.to_string() +
  " EBX=0x" +
  regs.bx.to_string() +
  " ECX=0x" +
  regs.cx.to_string() +
  " EDX=0x" +
  regs.dx.to_string() +
  "\n" +
  "  EDI=0x" +
  regs.di.to_string() +
  " ESI=0x" +
  regs.si.to_string() +
  " EBP=0x" +
  regs.bp.to_string() +
  " ESP=0x" +
  regs.sp.to_string() +
  "\n" +
  "  EIP=0x" +
  regs.ip.to_string() +
  " EFLAGS=0x" +
  regs.flags.to_string() +
  "\n" +
  "  CS=0x" +
  regs.cs.to_string() +
  " DS=0x" +
  regs.ds.to_string() +
  " ES=0x" +
  regs.es.to_string() +
  " FS=0x" +
  regs.fs.to_string() +
  " GS=0x" +
  regs.gs.to_string() +
  " SS=0x" +
  regs.ss.to_string()
}

///|
pub fn format_regs_amd64(regs : RegsAMD64) -> String {
  "AMD64 Registers:\n" +
  "  RAX=0x" +
  regs.ax.to_string() +
  " RBX=0x" +
  regs.bx.to_string() +
  " RCX=0x" +
  regs.cx.to_string() +
  " RDX=0x" +
  regs.dx.to_string() +
  "\n" +
  "  RDI=0x" +
  regs.di.to_string() +
  " RSI=0x" +
  regs.si.to_string() +
  " RBP=0x" +
  regs.bp.to_string() +
  " RSP=0x" +
  regs.sp.to_string() +
  "\n" +
  "  R8=0x" +
  regs.r8.to_string() +
  " R9=0x" +
  regs.r9.to_string() +
  " R10=0x" +
  regs.r10.to_string() +
  " R11=0x" +
  regs.r11.to_string() +
  "\n" +
  "  R12=0x" +
  regs.r12.to_string() +
  " R13=0x" +
  regs.r13.to_string() +
  " R14=0x" +
  regs.r14.to_string() +
  " R15=0x" +
  regs.r15.to_string() +
  "\n" +
  "  RIP=0x" +
  regs.ip.to_string() +
  " RFLAGS=0x" +
  regs.flags.to_string() +
  "\n" +
  "  CS=0x" +
  regs.cs.to_string() +
  " FS=0x" +
  regs.fs.to_string() +
  " GS=0x" +
  regs.gs.to_string()
}

///|
pub fn format_thread_state(state : ThreadState) -> String {
  match state {
    I386(regs) => format_regs_386(regs)
    AMD64(regs) => format_regs_amd64(regs)
    Unknown(data) =>
      "Unknown thread state (" + data.length().to_string() + " bytes)"
  }
}
