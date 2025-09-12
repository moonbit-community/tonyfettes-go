///|
pub fn close_on_exec(fd : Int) -> Unit {
  ignore(fcntl(fd, F_SETFD, FD_CLOEXEC)) catch {
    _ => ()
  }
}

///|
pub fn set_nonblock(fd : Int, nonblocking : Bool) -> Unit raise {
  let mut flag = fcntl(fd, F_GETFL, 0)
  if ((flag & O_NONBLOCK) != 0) == nonblocking {
    return
  }
  if nonblocking {
    flag = flag | O_NONBLOCK
  } else {
    flag = flag & O_NONBLOCK.lnot()
  }
  ignore(fcntl(fd, F_SETFL, flag))
}
