///|
/// MoonBit translation of Go's regexp package
/// 
/// Package regexp implements regular expression search.
///
/// The syntax of the regular expressions accepted is the same
/// general syntax used by Perl, Python, and other languages.
/// More precisely, it is the syntax accepted by RE2.

///|
/// Input interface for different input types
trait Input {
  step(Self, Int) -> (Int, Int) // advance one rune, return (rune, width)
  can_check_prefix(Self) -> Bool
  has_prefix(Self, Regexp) -> Bool
  index(Self, Regexp, Int) -> Int
  context(Self, Int) -> Int // lazy flag
}

///|
/// String input implementation
struct InputString {
  str : String
} derive(Show)

///|
impl Input for InputString with step(self, pos) {
  if pos < self.str.length() {
    let c = self.str[pos]
    if c < 128 { // ASCII
      (c, 1)
    } else {
      // Simple implementation - just return the character
      (self.str[pos], 1)
    }
  } else {
    (-1, 0) // endOfText
  }
}

///|
impl Input for InputString with can_check_prefix(self) {
  true
}

///|
impl Input for InputString with has_prefix(self, re) {
  self.str.has_prefix(re.prefix)
}

///|
impl Input for InputString with index(self, re, pos) {
  @strings.index_from(self.str, re.prefix, pos)
}

///|
impl Input for InputString with context(self, pos) {
  // Simplified context calculation
  0
}

///|
/// Bytes input implementation  
struct InputBytes {
  str : Bytes
} derive(Show)

///|
impl Input for InputBytes with step(self, pos) {
  if pos < self.str.length() {
    let c = self.str[pos]
    if c < 128 { // ASCII
      (c.to_int(), 1)
    } else {
      @utf8.decode_rune(self.str, pos)
    }
  } else {
    (-1, 0) // endOfText
  }
}

///|
impl Input for InputBytes with can_check_prefix(self) {
  true
}

///|
impl Input for InputBytes with has_prefix(self, re) {
  // Convert prefix to bytes and check
  @bytes.has_prefix(self.str, re.prefix_bytes)
}

///|
impl Input for InputBytes with index(self, re, pos) {
  @bytes.index_from(self.str, re.prefix_bytes, pos)
}

///|
impl Input for InputBytes with context(self, pos) {
  // Simplified context calculation
  0
}

///|
/// Regexp is the representation of a compiled regular expression.
/// A Regexp is safe for concurrent use by multiple goroutines.
pub struct Regexp {
  expr : String // as passed to Compile
  prog : @syntax.Prog // compiled program  
  num_subexp : Int // number of subexpressions
  subexp_names : Array[String] // names of capturing groups
  prefix : String // required prefix in unanchored matches
  prefix_bytes : Bytes // prefix, as bytes
  prefix_complete : Bool // prefix is the entire regexp
  cond : @syntax.EmptyOp // empty-width conditions required at start
  min_input_len : Int // minimum length of input in bytes
  longest : Bool // whether regexp prefers leftmost-longest match
} derive(Show)

///|
/// String returns the source text used to compile the regular expression.
pub fn Regexp::to_string(self : Regexp) -> String {
  self.expr
}

///|
/// Copy returns a new Regexp object copied from re.
/// Note: In MoonBit this is less necessary due to value semantics
pub fn Regexp::copy(self : Regexp) -> Regexp {
  self // Value copy in MoonBit
}

///|
/// Compile parses a regular expression and returns, if successful,
/// a Regexp object that can be used to match against text.
pub fn compile(expr : String) -> Result[Regexp, @syntax.Error] {
  compile_internal(expr, @syntax.perl, false)
}

///|
/// CompilePOSIX is like Compile but restricts the regular expression
/// to POSIX ERE (egrep) syntax and changes the match semantics to
/// leftmost-longest.
pub fn compile_posix(expr : String) -> Result[Regexp, @syntax.Error] {
  compile_internal(expr, @syntax.posix, true)
}

///|
/// Internal compilation function
fn compile_internal(
  expr : String,
  mode : @syntax.Flags,
  longest : Bool,
) -> Result[Regexp, @syntax.Error] {
  // Parse the regexp
  let re_ast = try? @syntax.parse(expr, mode)
  let max_cap = re_ast.max_cap()
  let cap_names = re_ast.cap_names()

  // Simplify and compile
  let simplified = re_ast.simplify()
  let prog = try? @syntax.compile(simplified)

  // Calculate prefix
  let (prefix, prefix_complete) = prog.prefix()
  let regexp = {
    expr,
    prog,
    num_subexp: max_cap,
    subexp_names: cap_names,
    prefix,
    prefix_bytes: prefix.to_bytes(),
    prefix_complete,
    cond: prog.start_cond(),
    min_input_len: min_input_len(re_ast),
    longest,
  }
  Ok(regexp)
}

///|
/// Calculate minimum input length
fn min_input_len(re : @syntax.Regexp) -> Int {
  match re.op {
    @syntax.OpLiteral => re.rune.length()
    @syntax.OpAnyChar | @syntax.OpAnyCharNotNL | @syntax.OpCharClass => 1
    @syntax.OpCapture | @syntax.OpPlus =>
      if re.sub.length() > 0 {
        min_input_len(re.sub[0])
      } else {
        0
      }
    @syntax.OpRepeat =>
      if re.sub.length() > 0 {
        re.min * min_input_len(re.sub[0])
      } else {
        0
      }
    @syntax.OpConcat => {
      let mut total = 0
      for sub in re.sub {
        total = total + min_input_len(sub)
      }
      total
    }
    @syntax.OpAlternate =>
      if re.sub.length() > 0 {
        let mut min_len = min_input_len(re.sub[0])
        for i = 1; i < re.sub.length(); i = i + 1 {
          let len = min_input_len(re.sub[i])
          if len < min_len {
            min_len = len
          }
        }
        min_len
      } else {
        0
      }
    _ => 0
  }
}

///|
/// Longest makes future searches prefer the leftmost-longest match.
pub fn Regexp::longest(self : Regexp) -> Unit {
  // Note: In MoonBit, we'd need to make this mutable or return a new Regexp
  // For now, this is a placeholder
}

///|
/// NumSubexp returns the number of parenthesized subexpressions in this Regexp.
pub fn Regexp::num_subexp(self : Regexp) -> Int {
  self.num_subexp
}

///|
/// SubexpNames returns the names of the parenthesized subexpressions
/// in this Regexp.
pub fn Regexp::subexp_names(self : Regexp) -> Array[String] {
  self.subexp_names
}

///|
/// SubexpIndex returns the index of the first subexpression with the given name,
/// or -1 if there is no subexpression with that name.
pub fn Regexp::subexp_index(self : Regexp, name : String) -> Int {
  if name != "" {
    for i = 0; i < self.subexp_names.length(); i = i + 1 {
      if name == self.subexp_names[i] {
        return i
      }
    }
  }
  -1
}

///|
/// LiteralPrefix returns a literal string that must begin any match
/// of the regular expression re.
pub fn Regexp::literal_prefix(self : Regexp) -> (String, Bool) {
  (self.prefix, self.prefix_complete)
}

///|
/// MatchString reports whether the string s contains any match of the regular expression re.
pub fn Regexp::match_string(self : Regexp, s : String) -> Bool {
  self.do_match_string(s)
}

///|
/// Match reports whether the byte slice b contains any match of the regular expression re.
pub fn Regexp::match_bytes(self : Regexp, b : Bytes) -> Bool {
  self.do_match_bytes(b)
}

///|
/// Internal string matching
fn Regexp::do_match_string(self : Regexp, s : String) -> Bool {
  let input = InputString::{ str: s }
  self.do_execute_input(input, 0, 0).is_some()
}

///|
/// Internal bytes matching
fn Regexp::do_match_bytes(self : Regexp, b : Bytes) -> Bool {
  let input = InputBytes::{ str: b }
  self.do_execute_input(input, 0, 0).is_some()
}

///|
/// Internal execution with input interface
fn[T : Input] Regexp::do_execute_input(
  self : Regexp,
  input : T,
  pos : Int,
  ncap : Int,
) -> Array[Int]? {
  // Simple NFA execution - placeholder implementation
  // This would need full NFA execution logic

  if input.has_prefix(self) {
    // Found a match at the beginning
    Some([0, self.prefix.length()])
  } else {
    None
  }
}

///|
/// MustCompile is like Compile but panics if the expression cannot be parsed.
pub fn must_compile(str : String) -> Regexp {
  match compile(str) {
    Ok(regexp) => regexp
    Err(err) =>
      @builtin.panic("regexp: Compile(" + str + "): " + err.to_string())
  }
}

///|
/// MustCompilePOSIX is like CompilePOSIX but panics if the expression cannot be parsed.
pub fn must_compile_posix(str : String) -> Regexp {
  match compile_posix(str) {
    Ok(regexp) => regexp
    Err(err) =>
      @builtin.panic("regexp: CompilePOSIX(" + str + "): " + err.to_string())
  }
}

///|
/// Package-level convenience functions

///|
/// MatchString reports whether the string s contains any match of the regular expression pattern.
pub fn match_string(
  pattern : String,
  s : String,
) -> Result[Bool, @syntax.Error] {
  let re = try? compile(pattern)
  Ok(re.match_string(s))
}

///|
/// Match reports whether the byte slice b contains any match of the regular expression pattern.
pub fn match_bytes(pattern : String, b : Bytes) -> Result[Bool, @syntax.Error] {
  let re = try? compile(pattern)
  Ok(re.match_bytes(b))
}
