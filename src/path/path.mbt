///|
pub fn clean(path : @string.View) -> @string.View {
  if path is "" {
    return "."
  }
  let mut rooted = false
  let r = match path {
    ['/', .. r] => {
      rooted = true
      r
    }
    [.. r] => r
  }
  let out = []
  let mut dotdot = 0
  if rooted {
    out.push('/')
    dotdot = 1
  }
  loop r {
    ['/', .. r] => continue r
    ['.'] => continue []
    [.. "./", .. r] => continue r
    [.. "..", .. r] => {
      if out.length() > dotdot {
        out.pop() |> ignore()
        while out.length() > dotdot && out.last() != Some('/') {
          out.pop() |> ignore()
        }
      } else if !rooted {
        if out.length() > 0 {
          out.push('/')
        }
        out.push('.')
        out.push('.')
        dotdot = out.length()
      }
      continue r
    }
    r => {
      if (rooted && out.length() != 1) || (!rooted && out.length() > 0) {
        out.push('/')
      }
      continue loop r {
          [] => []
          ['/', .. r] => r
          [c, .. r] => {
            out.push(c)
            continue r
          }
        }
    }
  }
  if out.length() == 0 {
    return "."
  }
  return String::from_array(out)
}

///|
pub fn split(path : @string.View) -> (@string.View, @string.View) raise {
  let file = path
  loop path {
    [] => ("", file)
    [.. r, '/'] as p => (r, file[p.start_offset():])
    [.. p, _] => continue p
  }
}

///|
pub fn join(elem : Array[@string.View]) -> @string.View {
  let mut size = 0
  for e in elem {
    size += e.length()
  }
  if size == 0 {
    return ""
  }
  let buf = StringBuilder::new()
  for e in elem {
    if !buf.is_empty() || e != "" {
      if !buf.is_empty() {
        buf.write_char('/')
      }
      buf.write_substring(e.data(), e.start_offset(), e.length())
    }
  }
  return clean(buf.to_string())
}

///|
pub fn ext(path : @string.View) -> @string.View raise {
  let ext = path
  loop path[:] {
    [] => ""
    [.., '/'] => return ""
    [.., '.'] as p => return ext[p.start_offset():]
    [.. r, _] => continue r
  }
}

///|
pub fn base(path : @string.View) -> @string.View raise {
  if path == "" {
    return "."
  }
  let path = match path {
    [.. path, '/'] => path
    path => path
  }
  let last = path
  let path = loop path {
    [] => last
    [.., '/'] as p => last[p.start_offset():]
    [.. path, _] => continue path
  }
  if path == "" {
    return "/"
  }
  path
}

///|
pub fn is_abs(path : @string.View) -> Bool {
  path.length() > 0 && path is ['/', ..]
}

///|
pub fn dir(path : @string.View) -> @string.View raise {
  let (dir, _) = split(path)
  return clean(dir)
}
