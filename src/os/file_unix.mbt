///|
struct File {
  pfd : @poll.FD
  name : String
  /// whether we set nonblocking mode
  nonblock : Bool
  /// whether this is stdout or stderr
  stdout_or_err : Bool
  /// whether file is opened for appending
  mut append_mode : Bool
}

///|
fn File::fd(self : File) -> @builtin.UIntPtr {
  if self.nonblock {
    self.pfd.set_blocking() catch {
      _ => ()
    }
  }
  @builtin.UIntPtr::from_int(self.pfd.sysfd)
}

///|
/// open_file_no_log is the Unix implementation of OpenFile.
/// Changes here should be reflected in openDirAt and openDirNolog, if relevant.
fn open_file_no_log(name : String, flag : Int, perm : FileMode) -> File raise {
  let mut set_sticky = false
  if !SupportsCreateWithStickyBit && (flag & O_CREATE) != 0 && perm.is_sticky() {
    set_sticky = true
  }
  // We have to check EINTR here, per issues 11180 and 39237.
  let (r, s) = ignoring_EINTR(() => _open(
    name,
    flag | @syscall.O_CLOEXEC,
    syscall_mode(perm),
  )) catch {
    err => raise @fs.PathError::new(op="open", path=name, err)
  }

  // open(2) itself won't handle the sticky bit on *BSD and Solaris
  if set_sticky {
    set_sticky_bit(name)
  }

  // There's a race here with fork/exec, which we are
  // content to live with. See ../syscall/exec_unix.go.
  if !SupportsCloseOnExec {
    @syscall.close_on_exec(r)
  }
  let f = new_file(r, name, OpenFile, @unix.has_nonblock_flag(flag))
  f.pfd.sys_file = s
  f
}

///|
fn open_dir_nolog(name : String) -> File raise {
  let (r, s) = ignoring_EINTR(() => _open(
    name,
    @syscall.O_RDONLY | @syscall.O_CLOEXEC | @syscall.O_DIRECTORY,
    0o0,
  )) catch {
    err => raise @fs.PathError::new(op="open", path=name, err)
  }
  if !SupportsCloseOnExec {
    @syscall.close_on_exec(r)
  }
  let f = new_file(r, name, OpenFile, false)
  f.pfd.sys_file = s
  f
}

///|
pub impl @io.Closer for File with close(self : File) -> Unit raise {
  self.pfd.close() catch {
    e => {
      let e : Error = if e is @poll.FileClosing { @oserror.Closed } else { e }
      raise @fs.PathError::new(op="close", path=self.name, e)
    }
  }
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
    nonblock: false,
    stdout_or_err: fd == 1 || fd == 2,
    append_mode: false,
  }
  return f
}
