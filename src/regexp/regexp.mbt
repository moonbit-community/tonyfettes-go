///|
/// MoonBit translation of Go's regexp package
///
/// Package regexp implements regular expression search.
///
/// The syntax of the regular expressions accepted is the same
/// general syntax used by Perl, Python, and other languages.
/// More precisely, it is the syntax accepted by RE2.

///|
/// A `LazyFlag` is a lazily-evaluated syntax.EmptyOp,
/// for checking zero-width flags like ^ $ \A \z \B \b.
/// It records the pair of relevant runes and does not
/// determine the implied flags until absolutely necessary
/// (most of the time, that means never).
priv struct LazyFlag(Char?, Char?)

///|
fn new_lazy_flag(r1 : Char?, r2 : Char?) -> LazyFlag {
  LazyFlag(r1, r2)
}

///|
/// input abstracts different representations of the input text. It provides
/// one-character lookahead.
priv trait Input {
  /// advance one rune, return (rune, width)
  step(Self, Int) -> (Char?, Int)
  /// can we look ahead without losing info?
  can_check_prefix(Self) -> Bool
  has_prefix(Self, re : Regexp) -> Bool
  index(Self, re : Regexp, pos : Int) -> Int
  context(Self, Int) -> LazyFlag
}

///|
/// `InputString` scans a string.
priv struct InputString {
  str : String
}

///|
impl Input for InputString with step(self : InputString, pos : Int) -> (
  Char?,
  Int,
) {
  if pos < self.str.length() {
    let c = self.str[pos]
    if c.is_leading_surrogate() {
      if pos + 1 >= self.str.length() {
        return (Some(@utf16.RuneError), 0)
      } else {
        let d = self.str[pos + 1]
        if d.is_trailing_surrogate() {
          return (
            Some(
              (0x10000 + (c - 0xD800) * 0x400 + (d - 0xDC00)).unsafe_to_char(),
            ),
            2,
          )
        } else {
          return (Some(@utf16.RuneError), 0)
        }
      }
    } else {
      (Some(c.unsafe_to_char()), 1)
    }
  } else {
    (None, 0)
  }
}

///|
impl Input for InputString with can_check_prefix(_ : InputString) -> Bool {
  true
}

///|
impl Input for InputString with has_prefix(self, re) {
  @strings.has_prefix(self.str, re.prefix)
}

///|
impl Input for InputString with index(self, re, pos) {
  (try! self.str[pos:]).find(re.prefix).unwrap()
}

///|
impl Input for InputString with context(self : InputString, pos : Int) -> LazyFlag {
  let r1 = if uint(pos - 1) < uint(self.str.length()) {
    let (r1, _) = @utf16.decode_last_rune_in_string(try! self.str[:pos])
    Some(r1)
  } else {
    None
  }
  let r2 = if uint(pos) < uint(self.str.length()) {
    let (r2, _) = @utf16.decode_rune_in_string(try! self.str[pos:])
    Some(r2)
  } else {
    None
  }
  return new_lazy_flag(r1, r2)
}

///|
/// Bytes input implementation
priv struct InputBytes {
  str : @slice.Slice[Byte]
}

///|
impl Input for InputBytes with step(self, pos) {
  if pos < self.str.length() {
    let c = self.str[pos]
    if c < @utf8.RuneSelf { // ASCII
      return (Some(c.to_char()), 1)
    } else {
      let (c, width) = @utf8.decode_rune(self.str[pos:])
      return (Some(c), width)
    }
  } else {
    (None, 0)
  }
}

///|
impl Input for InputBytes with can_check_prefix(_ : InputBytes) {
  true
}

///|
impl Input for InputBytes with has_prefix(self, re) {
  @bytes.has_prefix(self.str, re.prefix_bytes)
}

///|
impl Input for InputBytes with index(self, re, pos) {
  return self.str.bytesview()[pos:]
    .find(re.prefix_bytes.bytesview())
    .unwrap_or(-1)
}

///|
impl Input for InputBytes with context(self, pos) {
  // Simplified context calculation
  new_lazy_flag(None, None)
}

///|
/// Regexp is the representation of a compiled regular expression.
/// A Regexp is safe for concurrent use by multiple goroutines.
pub struct Regexp {
  expr : String // as passed to Compile
  prog : @syntax.Prog // compiled program
  num_subexp : Int // number of subexpressions
  subexp_names : Array[String] // names of capturing groups
  /// required prefix in unanchored matches
  prefix : String
  /// prefix, as bytes
  prefix_bytes : @slice.Slice[Byte]
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
pub fn compile(expr : String) -> Regexp {
  compile_internal(expr, @syntax.perl, false)
}

///|
/// CompilePOSIX is like Compile but restricts the regular expression
/// to POSIX ERE (egrep) syntax and changes the match semantics to
/// leftmost-longest.
pub fn compile_posix(expr : String) -> Regexp {
  compile_internal(expr, @syntax.posix, true)
}

///|
/// Internal compilation function
fn compile_internal(
  expr : String,
  mode : @syntax.Flags,
  longest : Bool,
) -> Regexp {
  // Parse the regexp
  let re_ast = @syntax.parse(expr, mode)
  let max_cap = re_ast.max_cap()
  let cap_names = re_ast.cap_names()

  // Simplify and compile
  let simplified = re_ast.simplify()
  let prog = @syntax.compile(simplified)

  // Calculate prefix
  let (prefix, prefix_complete) = prog.prefix()
  let regexp = {
    expr,
    prog,
    num_subexp: max_cap,
    subexp_names: cap_names,
    prefix,
    prefix_bytes: @slice.bytes(@utf8.encode(prefix)),
    prefix_complete,
    cond: prog.start_cond(),
    min_input_len: min_input_len(re_ast),
    longest,
  }
  regexp
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
pub fn Regexp::match_bytes(self : Regexp, b : @slice.Slice[Byte]) -> Bool {
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
fn Regexp::do_match_bytes(self : Regexp, b : @slice.Slice[Byte]) -> Bool {
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
/// Package-level convenience functions

///|
/// MatchString reports whether the string s contains any match of the regular expression pattern.
pub fn match_string(pattern : String, s : String) -> Bool {
  let re = compile(pattern)
  re.match_string(s)
}

///|
/// Match reports whether the byte slice b contains any match of the regular expression pattern.
pub fn match_bytes(pattern : String, b : @slice.Slice[Byte]) -> Bool {
  let re = compile(pattern)
  re.match_bytes(b)
}
