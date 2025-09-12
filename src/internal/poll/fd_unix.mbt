///|
pub struct FD {
  priv fdmu : FdMutex
  sysfd : Int
  sys_file : SysFile
  priv fd : PollDesc
  priv csema : UInt
  is_stream : Bool
  zero_read_is_eof : Bool
  priv is_file : Bool
}

///|
pub fn FD::new(
  sysfd~ : Int,
  is_stream? : Bool = false,
  zero_read_is_eof? : Bool = false,
) -> FD {
  FD::{
    fdmu: FdMutex::new(),
    sysfd,
    sys_file: SysFile::new(),
    fd: PollDesc::new(),
    csema: 0,
    is_stream,
    zero_read_is_eof,
    is_file: false,
  }
}
