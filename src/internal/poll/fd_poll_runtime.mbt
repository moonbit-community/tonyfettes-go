///|
priv struct PollDesc {
  mut runtime_ctx : @builtin.UIntPtr
}

///|
fn PollDesc::new() -> PollDesc {
  PollDesc::{ runtime_ctx: @builtin.UIntPtr::from_uint64(0) }
}

///|
extern "c" fn runtime_poll_close(ctx : @builtin.UIntPtr) -> Unit = "moonbit_tonyfettes_go_runtime_poll_close"

///|
extern "c" fn runtime_poll_unblock(ctx : @builtin.UIntPtr) -> Unit = "moonbit_tonyfettes_go_runtime_poll_unblock"

///|
fn PollDesc::close(self : PollDesc) -> Unit {
  if self.runtime_ctx.to_uint64() == 0 {
    return
  }
  runtime_poll_close(self.runtime_ctx)
  self.runtime_ctx = @builtin.UIntPtr::from_uint64(0)
}

///|
fn PollDesc::evict(self : PollDesc) -> Unit {
  if self.runtime_ctx.to_uint64() == 0 {
    return
  }
  runtime_poll_unblock(self.runtime_ctx)
}
