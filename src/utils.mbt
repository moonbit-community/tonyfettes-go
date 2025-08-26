///|
pub fn is_64bit(file : File) -> Bool {
  file.header.magic == magic_64
}

///|
pub fn is_32bit(file : File) -> Bool {
  file.header.magic == magic_32
}

///|
pub fn get_architecture(file : File) -> String {
  match file.header.cpu {
    I386 => "i386"
    Amd64 => "x86_64"
    Arm => "arm"
    Arm64 => "arm64"
    Ppc => "ppc"
    Ppc64 => "ppc64"
    Unknown(val) => "unknown(" + val.to_string() + ")"
  }
}

///|
pub fn get_file_type(file : File) -> String {
  match file.header.type_ {
    Object => "Object"
    Exec => "Executable"
    Dylib => "Dynamic Library"
    Bundle => "Bundle"
    Unknown(val) => "Unknown(" + val.to_string() + ")"
  }
}

///|
pub fn get_file_summary(file : File) -> String {
  let arch = get_architecture(file)
  let ftype = get_file_type(file)
  let bit_size = if is_64bit(file) { "64-bit" } else { "32-bit" }
  let load_cmd_count = file.header.ncmd.to_string()
  let section_count = file.sections.length().to_string()
  "Mach-O " +
  bit_size +
  " " +
  ftype +
  " (" +
  arch +
  ")\n" +
  "Load Commands: " +
  load_cmd_count +
  "\n" +
  "Sections: " +
  section_count
}

///|
pub fn has_flag(file : File, flag : UInt) -> Bool {
  (file.header.flags & flag) != 0_U
}

///|
pub fn get_flags_description(file : File) -> Array[Bytes] {
  let flags : Array[Bytes] = []
  if has_flag(file, flag_no_undefs) {
    flags.push("NO_UNDEFS")
  }
  if has_flag(file, flag_incr_link) {
    flags.push("INCR_LINK")
  }
  if has_flag(file, flag_dyld_link) {
    flags.push("DYLD_LINK")
  }
  if has_flag(file, flag_bind_at_load) {
    flags.push("BIND_AT_LOAD")
  }
  if has_flag(file, flag_prebound) {
    flags.push("PREBOUND")
  }
  if has_flag(file, flag_split_segs) {
    flags.push("SPLIT_SEGS")
  }
  if has_flag(file, flag_lazy_init) {
    flags.push("LAZY_INIT")
  }
  if has_flag(file, flag_two_level) {
    flags.push("TWO_LEVEL")
  }
  if has_flag(file, flag_force_flat) {
    flags.push("FORCE_FLAT")
  }
  if has_flag(file, flag_no_multi_defs) {
    flags.push("NO_MULTI_DEFS")
  }
  if has_flag(file, flag_no_fix_prebinding) {
    flags.push("NO_FIX_PREBINDING")
  }
  if has_flag(file, flag_prebindable) {
    flags.push("PREBINDABLE")
  }
  if has_flag(file, flag_all_mods_bound) {
    flags.push("ALL_MODS_BOUND")
  }
  if has_flag(file, flag_subsections_via_symbols) {
    flags.push("SUBSECTIONS_VIA_SYMBOLS")
  }
  if has_flag(file, flag_canonical) {
    flags.push("CANONICAL")
  }
  if has_flag(file, flag_weak_defines) {
    flags.push("WEAK_DEFINES")
  }
  if has_flag(file, flag_binds_to_weak) {
    flags.push("BINDS_TO_WEAK")
  }
  if has_flag(file, flag_allow_stack_execution) {
    flags.push("ALLOW_STACK_EXECUTION")
  }
  if has_flag(file, flag_root_safe) {
    flags.push("ROOT_SAFE")
  }
  if has_flag(file, flag_setuid_safe) {
    flags.push("SETUID_SAFE")
  }
  if has_flag(file, flag_no_reexported_dylibs) {
    flags.push("NO_REEXPORTED_DYLIBS")
  }
  if has_flag(file, flag_pie) {
    flags.push("PIE")
  }
  if has_flag(file, flag_dead_strippable_dylib) {
    flags.push("DEAD_STRIPPABLE_DYLIB")
  }
  if has_flag(file, flag_has_tlv_descriptors) {
    flags.push("HAS_TLV_DESCRIPTORS")
  }
  if has_flag(file, flag_no_heap_execution) {
    flags.push("NO_HEAP_EXECUTION")
  }
  if has_flag(file, flag_app_extension_safe) {
    flags.push("APP_EXTENSION_SAFE")
  }
  flags
}

///|
pub fn get_load_command_type(cmd : LoadCommand) -> Bytes {
  match cmd {
    LoadBytes(_) => "LoadBytes"
    Segment(segment) =>
      match segment.header.cmd {
        LoadCmd::Segment => "SEGMENT"
        LoadCmd::Segment64 => "SEGMENT_64"
        _ => "SEGMENT"
      }
    Dylib(_) => "DYLIB"
    Symtab(_) => "SYMTAB"
    Dysymtab(_) => "DYSYMTAB"
    Rpath(_) => "RPATH"
    Thread(_) => "THREAD"
  }
}

///|
pub fn count_load_commands_by_type(file : File) -> Array[(Bytes, Int)] {
  let counts : Array[(Bytes, Int)] = []
  let mut segment_count = 0
  let mut dylib_count = 0
  let mut symtab_count = 0
  let mut dysymtab_count = 0
  let mut rpath_count = 0
  let mut thread_count = 0
  let mut other_count = 0
  for load_cmd in file.loads {
    match load_cmd {
      Segment(_) => segment_count = segment_count + 1
      Dylib(_) => dylib_count = dylib_count + 1
      Symtab(_) => symtab_count = symtab_count + 1
      Dysymtab(_) => dysymtab_count = dysymtab_count + 1
      Rpath(_) => rpath_count = rpath_count + 1
      Thread(_) => thread_count = thread_count + 1
      LoadBytes(_) => other_count = other_count + 1
    }
  }
  if segment_count > 0 {
    counts.push(("SEGMENT", segment_count))
  }
  if dylib_count > 0 {
    counts.push(("DYLIB", dylib_count))
  }
  if symtab_count > 0 {
    counts.push(("SYMTAB", symtab_count))
  }
  if dysymtab_count > 0 {
    counts.push(("DYSYMTAB", dysymtab_count))
  }
  if rpath_count > 0 {
    counts.push(("RPATH", rpath_count))
  }
  if thread_count > 0 {
    counts.push(("THREAD", thread_count))
  }
  if other_count > 0 {
    counts.push(("OTHER", other_count))
  }
  counts
}
