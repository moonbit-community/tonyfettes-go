///|
pub typealias @oserror.Invalid

///|
pub typealias @oserror.Permission

///|
pub typealias @oserror.Exist

///|
pub typealias @oserror.NotExist

///|
pub typealias @oserror.Closed

///|
/// A FileMode represents a file's mode and permission bits.
/// The bits have the same definition on all systems, so that
/// information about files can be moved from one system
/// to another portably. Not all bits apply to all systems.
/// The only required bit is [ModeDir] for directories.
pub struct FileMode(UInt)

///|
pub impl Default for FileMode with default() -> FileMode {
  return FileMode(0)
}

///|
const ModeDir : UInt = 1 << 31

///|
const ModeAppend : UInt = 1 << 30

///|
const ModeExclusive : UInt = 1 << 29

///|
const ModeTemporary : UInt = 1 << 28

///|
const ModeSymlink : UInt = 1 << 27

///|
const ModeDevice : UInt = 1 << 26

///|
const ModeNamedPipe : UInt = 1 << 25

///|
const ModeSocket : UInt = 1 << 24

///|
const ModeSetuid : UInt = 1 << 23

///|
const ModeSetgid : UInt = 1 << 22

///|
const ModeCharDevice : UInt = 1 << 21

///|
const ModeSticky : UInt = 1 << 20

///|
const ModeIrregular : UInt = 1 << 19

///|
pub fn FileMode::dir() -> FileMode {
  ModeDir
}

///|
pub fn FileMode::append() -> FileMode {
  ModeAppend
}

///|
pub fn FileMode::exclusive() -> FileMode {
  ModeExclusive
}

///|
pub fn FileMode::temporary() -> FileMode {
  ModeTemporary
}

///|
pub fn FileMode::symlink() -> FileMode {
  ModeSymlink
}

///|
pub fn FileMode::device() -> FileMode {
  ModeDevice
}

///|
pub fn FileMode::named_pipe() -> FileMode {
  ModeNamedPipe
}

///|
pub fn FileMode::socket() -> FileMode {
  ModeSocket
}

///|
pub fn FileMode::setuid() -> FileMode {
  ModeSetuid
}

///|
pub fn FileMode::setgid() -> FileMode {
  ModeSetgid
}

///|
pub fn FileMode::char_device() -> FileMode {
  ModeCharDevice
}

///|
pub fn FileMode::sticky() -> FileMode {
  ModeSticky
}

///|
pub fn FileMode::irregular() -> FileMode {
  ModeIrregular
}

///|
const ModeType : UInt = ModeDir |
  ModeSymlink |
  ModeNamedPipe |
  ModeSocket |
  ModeDevice |
  ModeCharDevice

///|
const ModePerm : UInt = 0o777

///|
pub impl BitOr for FileMode with lor(self : FileMode, other : FileMode) -> FileMode {
  return FileMode(self.0 | other.0)
}

///|
pub impl BitAnd for FileMode with land(self : FileMode, other : FileMode) -> FileMode {
  return FileMode(self.0 & other.0)
}

///|
pub impl BitXOr for FileMode with lxor(self : FileMode, other : FileMode) -> FileMode {
  return FileMode(self.0 ^ other.0)
}

///|
pub fn FileMode::lnot(self : FileMode) -> FileMode {
  return FileMode(self.0.lnot())
}

///|
pub fn FileMode::to_uint(self : FileMode) -> UInt {
  return self.0
}

///|
pub impl Show for FileMode with output(self : FileMode, logger : &Logger) -> Unit {
  let str : Bytes = "dalTLDpSugct?"
  let buf = StringBuilder::new()
  for i, c in str {
    if (self.0 & (1 << (31 - i))) != 0 {
      buf.write_char(c.to_char())
    }
  }
  if buf.is_empty() {
    buf.write_char('-')
  }
  let rwx : Bytes = "rwxrwxrwx"
  for i, c in rwx {
    if (self.0 & (1 << (8 - i))) != 0 {
      buf.write_char(c.to_char())
    } else {
      buf.write_char('-')
    }
  }
  buf.output(logger)
}

///|
pub fn FileMode::is_dir(self : FileMode) -> Bool {
  return (self.0 & ModeDir) != 0
}

///|
pub fn FileMode::is_symlink(self : FileMode) -> Bool {
  return (self.0 & ModeSymlink) != 0
}

///|
pub fn FileMode::is_setuid(self : FileMode) -> Bool {
  return (self.0 & ModeSetuid) != 0
}

///|
pub fn FileMode::is_setgid(self : FileMode) -> Bool {
  return (self.0 & ModeSetgid) != 0
}

///|
pub fn FileMode::is_sticky(self : FileMode) -> Bool {
  return (self.0 & ModeSticky) != 0
}

///|
pub fn FileMode::type_(self : FileMode) -> FileMode {
  return FileMode(self.0 & ModeType)
}

///|
pub fn FileMode::perm(self : FileMode) -> FileMode {
  return FileMode(self.0 & ModePerm)
}

///|
pub suberror PathError {
  PathError(op~ : String, path~ : String, Error)
}

///|
pub fn PathError::new(op~ : String, path~ : String, err : Error) -> PathError {
  PathError(op~, path~, err)
}

///|
pub impl Show for PathError with output(self : PathError, logger : &Logger) -> Unit {
  let PathError(op~, path~, err) = self
  logger.write_string(op)
  logger.write_char(' ')
  logger.write_string(path)
  logger.write_string(": ")
  logger.write_object(err)
}

///|
pub fn PathError::unwrap(self : PathError) -> Error {
  let PathError(err, ..) = self
  return err
}
