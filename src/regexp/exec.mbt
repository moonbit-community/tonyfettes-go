///|
/// Execution engine for regular expressions

///|
/// A thread represents the state of a single path through the NFA
struct Thread {
  inst : @syntax.Inst // current instruction
  cap : Array[Int] // capture array
} derive(Show)

///|
/// Create a new thread
fn Thread::new(inst : @syntax.Inst) -> Thread {
  { inst, cap: [] }
}

///|
/// A queue entry for NFA simulation
struct Entry {
  pc : Int // program counter
  t : Thread? // thread (None for placeholder entries)
} derive(Show)

///|
/// Sparse queue for NFA simulation
struct Queue {
  sparse : Array[Int] // sparse array
  dense : Array[Entry] // dense array
} derive(Show)

///|
/// Create a new queue
fn Queue::new(size : Int) -> Queue {
  { sparse: Array::make(size, 0), dense: [] }
}

///|
/// Clear the queue
fn Queue::clear(self : Queue) -> Unit {
  self.dense.clear()
}

///|
/// Check if queue has entry at pc
fn Queue::has(self : Queue, pc : Int) -> Bool {
  if pc >= 0 && pc < self.sparse.length() {
    let j = self.sparse[pc]
    j < self.dense.length() && self.dense[j].pc == pc
  } else {
    false
  }
}

///|
/// Add entry to queue
fn Queue::add(self : Queue, pc : Int, t : Thread?) -> Unit {
  if not(self.has(pc)) {
    let j = self.dense.length()
    self.dense.push({ pc, t })
    if pc >= 0 && pc < self.sparse.length() {
      self.sparse[pc] = j
    }
  }
}

///|
/// Machine state for NFA execution
struct Machine {
  re : Regexp // the regexp being executed
  prog : @syntax.Prog // compiled program
  q0 : Queue // current queue
  q1 : Queue // next queue  
  matched : Bool // whether a match was found
  match_cap : Array[Int] // capture information for the match
} derive(Show)

///|
/// Create a new machine
fn Machine::new(re : Regexp) -> Machine {
  let prog = re.prog
  let size = prog.inst.length()
  {
    re,
    prog,
    q0: Queue::new(size),
    q1: Queue::new(size),
    matched: false,
    match_cap: Array::make(re.num_subexp * 2, -1),
  }
}

///|
/// Initialize machine for execution
fn Machine::init(self : Machine, ncap : Int) -> Unit {
  self.matched = false
  for i = 0; i < self.match_cap.length() && i < ncap; i = i + 1 {
    self.match_cap[i] = -1
  }
}

///|
/// Execute NFA on input
fn[T : Input] Machine::execute(self : Machine, input : T, pos : Int) -> Bool {
  self.init(0)

  // Simple implementation for basic matching
  let current_pos = Ref::new(pos)
  let runq = Ref::new(self.q0)
  let nextq = Ref::new(self.q1)

  // Add start state
  runq.val.add(self.prog.start, None)
  while current_pos.val <= input.context(0) { // simplified end condition
    let step_result = input.step(current_pos.val)
    let r = step_result.0
    let width = step_result.1
    if r == -1 { // end of text
      break
    }
    self.step(runq.val, nextq.val, current_pos.val, current_pos.val + width, r)
    if self.matched {
      return true
    }
    if width == 0 {
      break
    }
    current_pos.val = current_pos.val + width

    // Swap queues
    let temp = runq.val
    runq.val = nextq.val
    nextq.val = temp
    nextq.val.clear()
  }
  self.matched
}

///|
/// Execute one step of the NFA
fn Machine::step(
  self : Machine,
  runq : Queue,
  nextq : Queue,
  pos : Int,
  next_pos : Int,
  c : Int,
) -> Unit {
  for entry in runq.dense {
    match entry.t {
      None => continue
      Some(t) => {
        let inst = self.prog.inst[entry.pc]
        match inst.op {
          @syntax.InstMatch => {
            self.matched = true
            if self.match_cap.length() > 1 {
              self.match_cap[1] = pos
            }
          }
          @syntax.InstRune =>
            if inst.match_rune(c) {
              nextq.add(inst.out, Some(t))
            }
          @syntax.InstRune1 =>
            if inst.match_rune(c) {
              nextq.add(inst.out, Some(t))
            }
          @syntax.InstRuneAny => nextq.add(inst.out, Some(t))
          @syntax.InstRuneAnyNotNL =>
            if c != '\n' {
              nextq.add(inst.out, Some(t))
            }
          _ => {} // Handle other instruction types
        }
      }
    }
  }
}

///|
/// Execute regexp on input and return match information
pub fn[T : Input] Regexp::do_execute(
  self : Regexp,
  input : T,
  pos : Int,
  ncap : Int,
) -> Array[Int]? {
  if self.prefix != "" && input.can_check_prefix() {
    if not(input.has_prefix(self)) {
      return None
    }
  }
  let machine = Machine::new(self)
  if machine.execute(input, pos) {
    let result : Array[Int] = []
    for i = 0; i < ncap && i < machine.match_cap.length(); i = i + 1 {
      result.push(machine.match_cap[i])
    }
    Some(result)
  } else {
    None
  }
}
