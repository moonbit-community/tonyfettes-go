///|
/// Compilation of regexp AST to instruction format

///|
/// An instruction in the compiled regexp program
pub struct Inst {
  pub op : InstOp
  pub out : Int // next instruction index
  pub arg : Int // argument (depends on instruction)
  pub rune : Array[Int] // runes for character matching
} derive(Show, ToJson)

///|
/// Instruction operations
pub enum InstOp {
  InstAlt // alternative, go to Out or Arg
  InstAltMatch // alternative, prefer match at Out
  InstCapture // capturing group, capture at Arg, go to Out
  InstEmptyWidth // empty width assertion, check Arg, go to Out
  InstMatch // match found
  InstFail // no match possible
  InstNop // do nothing, go to Out
  InstRune // match runes in Rune array
  InstRune1 // match single rune Rune[0]
  InstRuneAny // match any rune
  InstRuneAnyNotNL // match any rune except newline
} derive(Eq, Show, ToJson)

///|
/// A compiled regexp program
pub struct Prog {
  pub inst : Array[Inst]
  pub start : Int
  pub num_cap : Int
} derive(Show, ToJson)

///|
/// Create a new instruction
pub fn Inst::new(op : InstOp) -> Inst {
  { op, out: 0, arg: 0, rune: [] }
}

///|
/// Check if instruction matches a rune
pub fn Inst::match_rune(self : Inst, r : Int) -> Bool {
  match self.op {
    InstRune => {
      // Check if rune is in the character class (pairs of ranges)
      let mut i = 0
      while i < self.rune.length() {
        let lo = self.rune[i]
        let hi = self.rune[i + 1]
        if lo <= r && r <= hi {
          return true
        }
        i = i + 2
      }
      false
    }
    InstRune1 => r == self.rune[0]
    InstRuneAny => r != -1 // endOfText
    InstRuneAnyNotNL => r != -1 && r != '\n'
    _ => false
  }
}

///|
/// Get prefix information from program
pub fn Prog::prefix(self : Prog) -> (String, Bool) {
  // Simple implementation - look for literal prefix
  if self.inst.length() > 0 {
    let first = self.inst[self.start]
    match first.op {
      InstRune1 => {
        let char = @utf8.from_rune(first.rune[0])
        (String::from_char(char), false)
      }
      _ => ("", false)
    }
  } else {
    ("", false)
  }
}

///|
/// Get start condition for program
pub fn Prog::start_cond(self : Prog) -> EmptyOp {
  // Simple implementation
  0
}

///|
/// Compile a regexp AST to instruction program
pub fn compile(re : Regexp) -> Result[Prog, Error] {
  let mut inst : Array[Inst] = []
  let result = compile_regexp(re, inst)
  match result {
    Ok(start) => {
      let prog = { inst, start, num_cap: re.max_cap() + 1 }
      Ok(prog)
    }
    Err(e) => Err(e)
  }
}

///|
/// Recursively compile a regexp node
fn compile_regexp(re : Regexp, inst : Array[Inst]) -> Result[Int, Error] {
  match re.op {
    OpEmptyMatch => {
      let i = Inst::new(InstNop)
      inst.push(i)
      Ok(inst.length() - 1)
    }
    OpLiteral =>
      if re.rune.length() == 0 {
        let i = Inst::new(InstNop)
        inst.push(i)
        Ok(inst.length() - 1)
      } else if re.rune.length() == 1 {
        let mut i = Inst::new(InstRune1)
        i.rune = [re.rune[0]]
        inst.push(i)
        Ok(inst.length() - 1)
      } else {
        // Multiple runes - create a sequence
        let mut start = -1
        for j = 0; j < re.rune.length(); j = j + 1 {
          let mut i = Inst::new(InstRune1)
          i.rune = [re.rune[j]]
          inst.push(i)
          if j == 0 {
            start = inst.length() - 1
          } else {
            inst[inst.length() - 2].out = inst.length() - 1
          }
        }
        Ok(start)
      }
    OpAnyChar => {
      let i = Inst::new(InstRuneAny)
      inst.push(i)
      Ok(inst.length() - 1)
    }
    OpAnyCharNotNL => {
      let i = Inst::new(InstRuneAnyNotNL)
      inst.push(i)
      Ok(inst.length() - 1)
    }
    OpCharClass => {
      let i = Inst::new(InstRune)
      i.rune = re.rune
      inst.push(i)
      Ok(inst.length() - 1)
    }
    _ => {
      // For now, placeholder for complex operations
      let i = Inst::new(InstFail)
      inst.push(i)
      Ok(inst.length() - 1)
    }
  }
}
