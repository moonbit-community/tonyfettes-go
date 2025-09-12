///|
/// FD is a file descriptor. The net and os packages use this type as a
/// field of a larger type representing a network connection or OS file.
pub(all) struct FD {
  /// Lock sysfd and serialize access to Read and Write methods.
  priv fdmu : FdMutex
  /// System file descriptor. Immutable until Close.
  mut sysfd : Int
  /// Platform dependent state of the file descriptor.
  mut sys_file : SysFile
  /// I/O poller.
  priv pd : PollDesc
  /// Semaphore signaled when file is closed.
  priv csema : FixedArray[UInt]
  /// Non-zero if this file has been set to blocking mode.
  /// An extra `FixedArray` wrap is necessary to perform atomic operations on it.
  priv is_blocking : FixedArray[UInt]
  /// Whether this is a streaming descriptor, as opposed to a
  /// packet-based descriptor like a UDP socket. Immutable.
  is_stream : Bool
  /// Whether a zero byte read indicates EOF. This is false for a
  /// message based socket connection.
  zero_read_is_eof : Bool
  /// Whether this is a file rather than a network socket.
  priv is_file : Bool
}

///|
pub fn FD::new(
  sysfd~ : Int,
  is_blocking? : Bool = false,
  is_stream? : Bool = false,
  zero_read_is_eof? : Bool = false,
) -> FD {
  let is_blocking : FixedArray[UInt] = if is_blocking { [1] } else { [0] }
  FD::{
    fdmu: FdMutex::new(),
    sysfd,
    sys_file: SysFile::new(),
    pd: PollDesc::new(),
    csema: [0],
    is_blocking,
    is_stream,
    zero_read_is_eof,
    is_file: false,
  }
}

///|
fn FD::destroy(self : FD) -> Unit raise {
  self.pd.close()
  let err = try? self.sys_file.destroy(self.sysfd)
  self.sysfd = -1
  runtime_semrelease(self.csema, 0)
  err.unwrap_or_error()
}

///|
/// close closes the FD. The underlying file descriptor is closed by the
/// destroy method when there are no remaining references.
pub fn FD::close(self : FD) -> Unit raise {
  if !self.fdmu.incref_and_close() {
    raise error_closing(is_file=self.is_file)
  }

  // Unblock any I/O.  Once it all unblocks and returns,
  // so that it cannot be referring to fd.sysfd anymore,
  // the final decref will close fd.sysfd. This should happen
  // fairly quickly, since all the I/O is non-blocking, and any
  // attempts to block in the pollDesc will return errClosing(fd.isFile).
  self.pd.evict()

  // The call to decref will call destroy if there are no other
  // references.
  let err = try? self.decref()

  // Wait until the descriptor is closed. If this was the only
  // reference, it is already closed. Only wait if the file has
  // not been set to blocking mode, as otherwise any current I/O
  // may be blocking, and that would block the Close.
  // No need for an atomic read of isBlocking, increfAndClose means
  // we have exclusive access to fd.
  if self.is_blocking[0] == 0 {
    runtime_semrelease(self.csema, 0)
  }
  err.unwrap_or_error()
}

///|
pub fn FD::set_blocking(self : FD) -> Unit raise Error {
  self.incref()
  // Atomic store so that concurrent calls to SetBlocking
  // do not cause a race condition. isBlocking only ever goes
  // from 0 to 1 so there is no real race here.
  @atomic.store_uint32(self.is_blocking, 0, 1)
  return @syscall.set_nonblock(self.sysfd, false)
}

///|
const MaxRW : Int = 1 << 30

///|
fn FD::eof_error(self : FD, n_err : Result[Int, Error]) -> Result[Int, Error] {
  match n_err {
    Ok(0) if self.zero_read_is_eof => Err(@io.EOF)
    Ok(n) => Ok(n)
    Err(err) => Err(err)
  }
}

///|
pub fn FD::pread(self : FD, p : @slice.Slice[Byte], off : Int64) -> Int raise {
  self.incref()
  let p = if self.is_stream && p.length() > MaxRW { p[:MaxRW] } else { p }
  let n_err = try? ignoring_EINTR(() => @syscall.pread(self.sysfd, p, off))
  self.decref()
  self.eof_error(n_err).unwrap_or_error()
}

///|
fn[T] ignoring_EINTR(f : () -> T raise) -> T raise {
  for {
    return f() catch {
      @syscall.Errno::EINTR => continue
      err => raise err
    }
  }
}

///|
fn[T] ignoring_EINTRIO(
  f : (Int, @slice.Slice[Byte]) -> T raise,
  fd : Int,
  p : @slice.Slice[Byte],
) -> T raise {
  for {
    return f(fd, p) catch {
      @syscall.Errno::EINTR => continue
      err => raise err
    }
  }
}
