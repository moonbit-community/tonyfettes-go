///|
/// Tests for the regexp syntax package

///|
test "op equality" {
  inspect(OpLiteral == OpLiteral, content="true")
  inspect(OpLiteral == OpAnyChar, content="false")
}

///|
test "flags operations" {
  let flags = fold_case | dot_nl
  inspect((flags & fold_case) != 0, content="true")
  inspect((flags & class_nl) != 0, content="false")
  inspect((flags & dot_nl) != 0, content="true")
}

///|
test "regexp creation" {
  let re = Regexp::new(OpLiteral)
  inspect(re.op, content="OpLiteral")
  inspect(re.flags, content="0")
  inspect(re.sub.length(), content="0")
  inspect(re.rune.length(), content="0")
}

///|
test "max cap calculation" {
  let mut re = Regexp::new(OpCapture)
  re.cap = 2
  
  let mut sub1 = Regexp::new(OpCapture)
  sub1.cap = 1
  
  let mut sub2 = Regexp::new(OpCapture)
  sub2.cap = 3
  
  re.sub = [sub1, sub2]
  
  inspect(re.max_cap(), content="3")
}

///|
test "cap names" {
  let mut re = Regexp::new(OpCapture)
  re.cap = 1
  re.name = "group1"
  
  let mut sub = Regexp::new(OpCapture)
  sub.cap = 2
  sub.name = "group2"
  
  re.sub = [sub]
  
  let names = re.cap_names()
  inspect(names.length(), content="4") // indices 0, 1, 2, 3
  inspect(names[1], content="group1")
  inspect(names[2], content="group2")
  inspect(names[0], content="")
  inspect(names[3], content="")
}

///|
test "error code to string" {
  inspect(ErrInvalidCharClass.to_string(), content="invalid character class")
  inspect(ErrMissingParen.to_string(), content="missing closing )")
  inspect(ErrInternalError.to_string(), content="regexp/syntax: internal error")
}

///|
test "error creation and formatting" {
  let err = Error::new(ErrInvalidEscape, "\\x")
  inspect(err.code, content="ErrInvalidEscape")
  inspect(err.expr, content="\\x")
  inspect(err.to_string(), content="error parsing regexp: invalid escape sequence: `\\x`")
}

///|
test "parse literal" {
  let result = parse("hello", literal)
  match result {
    Ok(re) => {
      inspect(re.op, content="OpLiteral")
      inspect(re.rune.length(), content="5")
    }
    Err(e) => @builtin.panic("Failed to parse literal: " + e.to_string())
  }
}

///|
test "parse empty" {
  let result = parse("", 0)
  match result {
    Ok(re) => {
      inspect(re.op, content="OpEmptyMatch")
    }
    Err(e) => @builtin.panic("Failed to parse empty: " + e.to_string())
  }
}

///|
test "parse dot" {
  let result = parse(".", 0)
  match result {
    Ok(re) => {
      inspect(re.op, content="OpAnyCharNotNL")
    }
    Err(e) => @builtin.panic("Failed to parse dot: " + e.to_string())
  }
}

///|
test "is word char" {
  inspect(is_word_char('a'), content="true")
  inspect(is_word_char('Z'), content="true")
  inspect(is_word_char('5'), content="true")
  inspect(is_word_char('_'), content="true")
  inspect(is_word_char(' '), content="false")
  inspect(is_word_char('!'), content="false")
  inspect(is_word_char('\n'), content="false")
}