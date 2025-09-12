///|
priv struct PollDesc {
  runtime_ctx : UInt64
}

///|
fn PollDesc::new() -> PollDesc {
  PollDesc::{ runtime_ctx: 0 }
}
