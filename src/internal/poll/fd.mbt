///|
pub(all) suberror NetClosing

///|
pub impl Show for NetClosing with output(self : NetClosing, output : &Logger) -> Unit {
  output.write_string("use of closed network connection")
}

///|
pub fn NetClosing::timeout(self : NetClosing) -> Bool {
  false
}

///|
pub fn NetClosing::temporary(self : NetClosing) -> Bool {
  false
}

///|
pub(all) suberror FileClosing

///|
pub impl Show for FileClosing with output(_ : FileClosing, output : &Logger) -> Unit {
  output.write_string("use of closed file")
}

///|
pub(all) suberror NoDeadline

///|
pub impl Show for NoDeadline with output(_ : NoDeadline, output : &Logger) -> Unit {
  output.write_string("file does not support setting deadlines")
}

///|
pub(all) suberror DeadlineExceeded

///|
pub impl Show for DeadlineExceeded with output(
  _ : DeadlineExceeded,
  output : &Logger,
) -> Unit {
  output.write_string("i/o timeout")
}

///|
pub fn DeadlineExceeded::timeout(_ : DeadlineExceeded) -> Bool {
  true
}

///|
pub fn DeadlineExceeded::temporary(_ : DeadlineExceeded) -> Bool {
  true
}

///|
pub suberror NotPollable
