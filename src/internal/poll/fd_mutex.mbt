///|
priv struct FdMutex {
  state : UInt64
  rsema : UInt
  wsema : UInt
}

///|
fn FdMutex::new() -> FdMutex {
  FdMutex::{ state: 0, rsema: 0, wsema: 0 }
}
