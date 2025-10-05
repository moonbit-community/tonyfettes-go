///|
/// MoonBit translation of Go's regexp/syntax package
/// Contains the AST structure for regular expressions

///|
/// An Op is a single regular expression operator.
/// Operators are listed in precedence order, tightest binding to weakest.
/// Character class operators are listed simplest to most complex
/// (OpLiteral, OpCharClass, OpAnyCharNotNL, OpAnyChar).
pub enum Op {
  OpNoMatch // matches no strings
  OpEmptyMatch // matches empty string
  OpLiteral // matches Runes sequence
  OpCharClass // matches Runes interpreted as range pair list
  OpAnyCharNotNL // matches any character except newline
  OpAnyChar // matches any character
  OpBeginLine // matches empty string at beginning of line
  OpEndLine // matches empty string at end of line
  OpBeginText // matches empty string at beginning of text
  OpEndText // matches empty string at end of text
  OpWordBoundary // matches word boundary `\b`
  OpNoWordBoundary // matches word non-boundary `\B`
  OpCapture // capturing subexpression with index Cap, optional name Name
  OpStar // matches Sub[0] zero or more times
  OpPlus // matches Sub[0] one or more times
  OpQuest // matches Sub[0] zero or one times
  OpRepeat // matches Sub[0] at least Min times, at most Max (Max == -1 is no limit)
  OpConcat // matches concatenation of Subs
  OpAlternate // matches alternation of Subs
} derive(Eq, Show, ToJson)

///|
/// Flags control the behavior of the parser and record information about regexp context.
pub typealias Int as Flags

///|
/// Flag constants
pub let fold_case : Flags = 1 // case-insensitive match

///|
pub let literal : Flags = 2 // treat pattern as literal string

///|
pub let class_nl : Flags = 4 // allow character classes like [^a-z] and [[:space:]] to match newline

///|
pub let dot_nl : Flags = 8 // allow . to match newline

///|
pub let one_line : Flags = 16 // treat ^ and $ as only matching at beginning and end of text

///|
pub let non_greedy : Flags = 32 // make repetition operators default to non-greedy

///|
pub let perl_x : Flags = 64 // allow Perl extensions

///|
pub let unicode_groups : Flags = 128 // allow \p{Han}, \P{Han} for Unicode group and negation

///|
pub let was_dollar : Flags = 256 // regexp OpEndText was $, not \z

///|
pub let simple : Flags = 512 // regexp contains no counted repetition

///|
pub let match_nl : Flags = class_nl | dot_nl

///|
pub let perl : Flags = class_nl | one_line | perl_x | unicode_groups // as close to Perl as possible

///|
pub let posix : Flags = 0 // POSIX syntax

///|
/// Empty operation flags for zero-width assertions
pub typealias Int as EmptyOp

///|
pub let empty_begin_line : EmptyOp = 1

///|
pub let empty_end_line : EmptyOp = 2

///|
pub let empty_begin_text : EmptyOp = 4

///|
pub let empty_end_text : EmptyOp = 8

///|
pub let empty_word_boundary : EmptyOp = 16

///|
pub let empty_no_word_boundary : EmptyOp = 32

///|
/// A Regexp is a node in a regular expression syntax tree.
pub struct Regexp {
  op : Op // operator
  flags : Flags // flags
  sub : Array[Regexp] // subexpressions, if any
  mut rune : Array[Int] // matched runes, for OpLiteral, OpCharClass
  min : Int // min for OpRepeat
  max : Int // max for OpRepeat (-1 means no limit)
  cap : Int // capturing index, for OpCapture
  name : String // capturing name, for OpCapture
} derive(Show, ToJson)

///|
/// Create a new empty Regexp
pub fn Regexp::new(op : Op) -> Regexp {
  { op, flags: 0, sub: [], rune: [], min: 0, max: 0, cap: 0, name: "" }
}

///|
/// Equal reports whether x and y have identical structure.
pub fn equal(x : Regexp?, y : Regexp?) -> Bool {
  match (x, y) {
    (None, None) => true
    (Some(x), Some(y)) =>
      if x.op != y.op {
        false
      } else {
        match x.op {
          OpEndText =>
            // The parse flags remember whether this is \z or \Z.
            (x.flags & was_dollar) == (y.flags & was_dollar)
          OpLiteral | OpCharClass =>
            (x.flags & fold_case) == (y.flags & fold_case) && x.rune == y.rune
          OpAlternate | OpConcat =>
            if x.sub.length() != y.sub.length() {
              false
            } else {
              let mut equal_result = true
              for i = 0; i < x.sub.length(); i = i + 1 {
                if not(equal(Some(x.sub[i]), Some(y.sub[i]))) {
                  equal_result = false
                  break
                }
              }
              equal_result
            }
          OpStar | OpPlus | OpQuest =>
            (x.flags & non_greedy) == (y.flags & non_greedy) &&
            equal(
              if x.sub.length() > 0 {
                Some(x.sub[0])
              } else {
                None
              },
              if y.sub.length() > 0 {
                Some(y.sub[0])
              } else {
                None
              },
            )
          OpRepeat =>
            (x.flags & non_greedy) == (y.flags & non_greedy) &&
            x.min == y.min &&
            x.max == y.max &&
            equal(
              if x.sub.length() > 0 {
                Some(x.sub[0])
              } else {
                None
              },
              if y.sub.length() > 0 {
                Some(y.sub[0])
              } else {
                None
              },
            )
          OpCapture =>
            x.cap == y.cap &&
            x.name == y.name &&
            equal(
              if x.sub.length() > 0 {
                Some(x.sub[0])
              } else {
                None
              },
              if y.sub.length() > 0 {
                Some(y.sub[0])
              } else {
                None
              },
            )
          _ => true
        }
      }
    _ => false
  }
}

///|
/// MaxCap walks the regexp to find the maximum capture index.
pub fn Regexp::max_cap(self : Regexp) -> Int {
  let mut m = 0
  if self.op == OpCapture {
    m = self.cap
  }
  for sub in self.sub {
    let n = sub.max_cap()
    if m < n {
      m = n
    }
  }
  m
}

///|
/// CapNames walks the regexp to find the names of capturing groups.
pub fn Regexp::cap_names(self : Regexp) -> Array[String] {
  let names = Array::make(self.max_cap() + 1, "")
  self.fill_cap_names(names)
  names
}

///|
/// Helper function to fill capture names
fn Regexp::fill_cap_names(self : Regexp, names : Array[String]) -> Unit {
  if self.op == OpCapture {
    names[self.cap] = self.name
  }
  for sub in self.sub {
    sub.fill_cap_names(names)
  }
}
