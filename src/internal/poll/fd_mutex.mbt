///|
priv struct FdMutex(FixedArray[@atomic.AtomicUInt64])

///|
fn FdMutex::new() -> FdMutex {
  FdMutex(@atomic.make_uint64_fixedarray(2, 0))
}

///|
let mutex_closed : UInt64 = 1 << 0

///|
let mutex_ref : UInt64 = 1 << 3

///|
let mutex_ref_mask : UInt64 = ((1 << 20) - 1) << 3

///|
let mutex_r_wait : UInt64 = 1 << 23

///|
let mutex_r_mask : UInt64 = ((1 << 20) - 1) << 23

///|
let mutex_w_wait : UInt64 = 1 << 43

///|
let mutex_w_mask : UInt64 = ((1 << 20) - 1) << 43

///|
const OverflowMsg : String = "too many concurrent operations on a single file or socket (max 1048575)"

///|
fn FdMutex::incref(self : FdMutex) -> Bool {
  for {
    let old = @atomic.load_uint64(self.0, 0)
    if (old & mutex_closed) != 0 {
      return false
    }
    let new = old + mutex_ref
    if (new & mutex_ref_mask) == 0 {
      abort(OverflowMsg)
    }
    if @atomic.compare_and_swap_uint64(self.0, 0, old, new) {
      return true
    }
  }
}

///|
fn[A, B] FixedArray::reinterpret(array : FixedArray[A]) -> FixedArray[B] = "%identity"

///|
fn FdMutex::incref_and_close(self : FdMutex) -> Bool {
  for {
    let mut old = @atomic.load_uint64(self.0, 0)
    if (old & mutex_closed) != 0 {
      return false
    }
    let new = (old | mutex_closed) + mutex_ref
    if (new & mutex_ref_mask) == 0 {
      abort(OverflowMsg)
    }
    // Remove all read and write waiters.
    let new = new & (mutex_r_mask | mutex_w_mask).lnot()
    if @atomic.compare_and_swap_uint64(self.0, 0, old, new) {
      // Wake all read and write waiters,
      // they will observe closed flag after wakeup.
      while (old & mutex_r_mask) != 0 {
        old = old - mutex_r_wait
        runtime_semrelease(self.0.reinterpret(), 0)
      }
      while (old & mutex_w_mask) != 0 {
        old = old - mutex_w_wait
        runtime_semrelease(self.0.reinterpret(), 0)
      }
      return true
    }
  }
}

///|
fn FdMutex::decref(self : FdMutex) -> Bool {
  for {
    let old = @atomic.load_uint64(self.0, 0)
    if (old & mutex_ref_mask) == 0 {
      abort("inconsistent poll.fdMutex")
    }
    let new = old - mutex_ref
    if @atomic.compare_and_swap_uint64(self.0, 0, old, new) {
      return (new & (mutex_closed | mutex_ref_mask)) == mutex_closed
    }
  }
}

///|
#borrow(sema)
extern "c" fn runtime_semacquire(sema : FixedArray[UInt], index : Int) = "moonbit_tonyfettes_go_runtime_semacquire"

///|
#borrow(sema)
extern "c" fn runtime_semrelease(sema : FixedArray[UInt], index : Int) = "moonbit_tonyfettes_go_runtime_semrelease"

///|
fn FD::incref(self : FD) -> Unit raise {
  if !self.fdmu.incref() {
    raise error_closing(is_file=self.is_file)
  }
}

///|
fn FD::decref(self : FD) -> Unit raise {
  if self.fdmu.decref() {
    return self.destroy()
  }
}
