///|
struct File {
  pfd : @poll.FD
  name : String
  stdout_or_err : Bool
  mut append_mode : Bool
}

///|
fn open_file_no_log(name : String, flag : Int, perm : FileMode) -> File raise {
  let mut set_sticky = false
  if !SupportsCreateWithStickyBit && (flag & O_CREATE) != 0 && perm.is_sticky() {
    set_sticky = true
  }
  let (r, s) = ignoring_EINTR(() => _open(
    name,
    flag | @syscall.O_CLOEXEC,
    syscall_mode(perm),
  )) catch {
    err => raise @fs.PathError::new(op="open", path=name, err)
  }
  if set_sticky {
    set_sticky_bit(name)
  }
  let f = new_file(r, name, OpenFile, @unix.has_nonblock_flag(flag))
  f
}

///|
priv enum NewFileKind {
  NewFile
  OpenFile
  Pipe
  Sock
  NoPoll
}

///|
fn new_file(
  fd : Int,
  name : String,
  kind : NewFileKind,
  non_blocking : Bool,
) -> File {
  let f = File::{
    pfd: @poll.FD::new(sysfd=fd, is_stream=true, zero_read_is_eof=false),
    name,
    stdout_or_err: fd == 1 || fd == 2,
    append_mode: false,
  }
  return f
}
