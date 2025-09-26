///|
/// Tests for the regexp package

///|
test "basic compilation" {
  let result = @regexp.compile("hello")
  match result {
    Ok(re) => {
      inspect(re.to_string(), content="hello")
      inspect(re.num_subexp(), content="0")
    }
    Err(e) => {
      @builtin.panic("Failed to compile simple regexp: " + e.to_string())
    }
  }
}

///|
test "compile empty string" {
  let result = @regexp.compile("")
  match result {
    Ok(re) => {
      inspect(re.to_string(), content="")
    }
    Err(e) => {
      @builtin.panic("Failed to compile empty regexp: " + e.to_string())
    }
  }
}

///|
test "must compile success" {
  let re = @regexp.must_compile("test")
  inspect(re.to_string(), content="test")
}

///|
test "literal prefix" {
  let re = @regexp.must_compile("hello")
  let (prefix, complete) = re.literal_prefix()
  inspect(prefix, content="hello")
  inspect(complete, content="true")
}

///|
test "basic string matching" {
  let re = @regexp.must_compile("hello")
  inspect(re.match_string("hello"), content="true")
  inspect(re.match_string("world"), content="false")
  inspect(re.match_string("hello world"), content="true")
}

///|
test "package level match string" {
  let result1 = @regexp.match_string("hello", "hello world")
  let result2 = @regexp.match_string("xyz", "hello world")
  
  match result1 {
    Ok(matched) => inspect(matched, content="true")
    Err(e) => @builtin.panic("Unexpected error: " + e.to_string())
  }
  
  match result2 {
    Ok(matched) => inspect(matched, content="false")
    Err(e) => @builtin.panic("Unexpected error: " + e.to_string())
  }
}

///|
test "posix compilation" {
  let result = @regexp.compile_posix("hello")
  match result {
    Ok(re) => {
      inspect(re.to_string(), content="hello")
    }
    Err(e) => {
      @builtin.panic("Failed to compile POSIX regexp: " + e.to_string())
    }
  }
}

///|
test "regexp equality" {
  let re1 = @regexp/syntax.Regexp::new(@regexp/syntax.OpLiteral)
  let re2 = @regexp/syntax.Regexp::new(@regexp/syntax.OpLiteral)
  let re3 = @regexp/syntax.Regexp::new(@regexp/syntax.OpAnyChar)
  
  inspect(@regexp/syntax.equal(Some(re1), Some(re2)), content="true")
  inspect(@regexp/syntax.equal(Some(re1), Some(re3)), content="false")
  inspect(@regexp/syntax.equal(None, None), content="true")
  inspect(@regexp/syntax.equal(Some(re1), None), content="false")
}

///|
test "error handling" {
  let err = @regexp/syntax.Error::new(@regexp/syntax.ErrInvalidCharClass, "test")
  inspect(err.to_string(), content="error parsing regexp: invalid character class: `test`")
}