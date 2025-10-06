///|
// `rot13` returns the rot13 encoding or decoding of its input.
pub fn rot13(data : @slice.Slice[Byte]) -> @slice.Slice[Byte] {
  let out : FixedArray[Byte] = FixedArray::make(data.length(), 0)
  for i, c in data {
    if c is ('A'..='M' | 'a'..='m') {
      out[i] = c + 13
    } else if c is ('N'..='Z' | 'n'..='z') {
      out[i] = c - 13
    } else {
      out[i] = c
    }
  }
  @slice.fixedarray(out)
}

///|
pub fn decode_to_temp_file(name : String) -> String raise {
  let f = @os.open(name)
  try {
    let tmp = @os.create_temp("", "obscuretestdata-decoded-")
    ""
  } catch {
    err => {
      f.close()
      raise err
    }
  } noraise {
    value => {
      f.close() catch {
        _ => ()
      }
      value
    }
  }
}

///|
pub fn read_file(name : String) -> @slice.Slice[Byte] raise {
  let f = @os.open(name)
  try @io.read_all(@base64.new_decoder(@base64.std_encoding, f)) catch {
    err => {
      f.close()
      raise err
    }
  } noraise {
    value => {
      f.close() catch {
        _ => ()
      }
      value
    }
  }
}
