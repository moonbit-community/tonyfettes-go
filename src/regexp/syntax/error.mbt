///|
/// Error handling types for regexp parsing

///|
/// An ErrorCode describes a failure to parse a regular expression.
pub enum ErrorCode {
  // Unexpected error
  ErrInternalError

  // Parse errors
  ErrInvalidCharClass
  ErrInvalidCharRange
  ErrInvalidEscape
  ErrInvalidNamedCapture
  ErrInvalidPerlOp
  ErrInvalidRepeatOp
  ErrInvalidRepeatSize
  ErrInvalidUTF8
  ErrMissingBracket
  ErrMissingParen
  ErrMissingRepeatArgument
  ErrTrailingBackslash
  ErrUnexpectedParen
  ErrNestingDepth
  ErrLarge
} derive(Eq, Show, ToJson)

///|
/// Convert ErrorCode to string
pub fn ErrorCode::to_string(self : ErrorCode) -> String {
  match self {
    ErrInternalError => "regexp/syntax: internal error"
    ErrInvalidCharClass => "invalid character class"
    ErrInvalidCharRange => "invalid character class range"
    ErrInvalidEscape => "invalid escape sequence"
    ErrInvalidNamedCapture => "invalid named capture"
    ErrInvalidPerlOp => "invalid or unsupported Perl syntax"
    ErrInvalidRepeatOp => "invalid nested repetition operator"
    ErrInvalidRepeatSize => "invalid repeat count"
    ErrInvalidUTF8 => "invalid UTF-8"
    ErrMissingBracket => "missing closing ]"
    ErrMissingParen => "missing closing )"
    ErrMissingRepeatArgument => "missing argument to repetition operator"
    ErrTrailingBackslash => "trailing backslash at end of expression"
    ErrUnexpectedParen => "unexpected )"
    ErrNestingDepth => "expression nests too deeply"
    ErrLarge => "expression too large"
  }
}
