/// DWARF Reader system for traversing entries
/// Ported from Go's debug/dwarf package

///|
/// A Reader allows reading Entry structures from a DWARF "info" section.
/// The Entry structures are arranged in a tree. The Reader.next function
/// returns successive entries from a pre-order traversal of the tree.
/// If an entry has children, its children field will be true, and the children
/// follow, terminated by an Entry with tag 0.
pub struct Reader {
  mut buf : Buf
  data : Data
  mut err : String?
  mut unit : Int
  mut last_unit : Bool // set if last entry returned by next is TagCompileUnit/TagPartialUnit
  mut last_children : Bool // .children of last entry returned by next
  mut last_sibling : Offset // .val(AttrSibling) of last entry returned by next
  mut cu : Entry? // current compilation unit
  units : Array[SimpleUnit]
} derive(Show)

///|
/// Create a new Reader for Data.
/// The reader is positioned at byte offset 0 in the DWARF "info" section.
pub fn Reader::new(data : Data, units : Array[SimpleUnit]) -> Reader {
  let buf = make_buf(
    Some(data),
    UnknownFormatRef(UnknownFormat::new()),
    "info",
    0L,
    data.get_section(".debug_info"),
  )
  {
    buf,
    data,
    err: None,
    unit: 0,
    last_unit: false,
    last_children: false,
    last_sibling: 0L,
    cu: None,
    units,
  }
}

///|
/// Get address size of current compilation unit
pub fn Reader::address_size(self : Reader) -> Int {
  if self.unit < self.units.length() {
    self.units[self.unit].addrsize()
  } else {
    4 // default
  }
}

///|
/// Get byte order of current compilation unit
pub fn Reader::byte_order(self : Reader) -> ByteOrder {
  self.data.get_byte_order()
}

///|
/// Seek positions the Reader at offset off in the encoded entry stream.
/// Offset 0 can be used to denote the first entry.
pub fn Reader::seek(self : Reader, off : Offset) -> Unit {
  self.err = None
  self.last_children = false
  if off == 0L {
    if self.units.length() == 0 {
      return
    }
    let u = self.units[0]
    self.unit = 0
    self.buf = make_buf(
      Some(self.data),
      UnknownFormatRef(UnknownFormat::new()),
      "info",
      off,
      self.data.get_section(".debug_info"),
    )
    self.cu = None
    return
  }
  let i = self.offset_to_unit(off)
  if i == -1 {
    self.err = Some("offset out of range")
    return
  }
  if i != self.unit {
    self.cu = None
  }
  let u = self.units[i]
  self.unit = i

  // Create buffer from the offset within the unit
  let info_data = self.data.get_section(".debug_info")
  let slice_start = off.to_int()
  let bytes_array : Array[Byte] = []
  for j = slice_start; j < info_data.length(); j = j + 1 {
    bytes_array.push(info_data[j])
  }
  let slice_data = Bytes::from_array(bytes_array)
  self.buf = make_buf(
    Some(self.data),
    UnknownFormatRef(UnknownFormat::new()),
    "info",
    off,
    slice_data,
  )
}

///|
/// Move to next unit if current one is finished
fn Reader::maybe_next_unit(self : Reader) -> Unit {
  while self.buf.length() == 0 && self.unit + 1 < self.units.length() {
    self.next_unit()
  }
}

///|
/// Advance to the next unit
fn Reader::next_unit(self : Reader) -> Unit {
  self.unit = self.unit + 1
  if self.unit >= self.units.length() {
    return
  }
  let u = self.units[self.unit]
  self.buf = make_buf(
    Some(self.data),
    UnknownFormatRef(UnknownFormat::new()),
    "info",
    0L, // Unit's data starts at its offset
    u.data,
  )
  self.cu = None
}

///|
/// Read the next entry from the encoded entry stream.
/// It returns None when it reaches the end of the section.
/// It returns an error via the Reader's error field if the current offset 
/// is invalid or the data cannot be decoded as a valid Entry.
pub fn Reader::next(self : Reader) -> Entry? {
  match self.err {
    Some(_) => return None
    None => () // continue
  }
  self.maybe_next_unit()
  if self.buf.length() == 0 {
    return None
  }
  if self.unit >= self.units.length() {
    self.err = Some("unit index out of range")
    return None
  }
  let u = self.units[self.unit]

  // Get abbreviation table for this unit
  let atable = match parse_abbrev(self.data, 0UL, u.version()) {
    Ok(table) => table
    Err(error) => {
      self.err = Some(error)
      return None
    }
  }
  let entry = parse_entry(self.buf, self.cu, u, atable)
  if self.buf.has_error() {
    match self.buf.get_error() {
      Some(err) => self.err = Some(err.to_string())
      None => self.err = Some("unknown buffer error")
    }
    return None
  }
  self.last_unit = false
  match entry {
    Some(e) => {
      self.last_children = e.children()
      if self.last_children {
        self.last_sibling = match e.val(AttrSibling) {
          Some(VOffset(off)) => off
          _ => 0L
        }
      }
      if e.tag() == TagCompileUnit || e.tag() == TagPartialUnit {
        self.last_unit = true
        self.cu = Some(e)
      }
      Some(e)
    }
    None => {
      self.last_children = false
      None
    }
  }
}

///|
/// Skip over the child entries associated with the last Entry returned by next.
/// If that Entry did not have children or next has not been called, skip_children is a no-op.
pub fn Reader::skip_children(self : Reader) -> Unit {
  match self.err {
    Some(_) => return
    None => () // continue
  }
  if not(self.last_children) {
    return
  }

  // If the last entry had a sibling attribute,
  // that attribute gives the offset of the next
  // sibling, so we can avoid decoding the
  // child subtrees.
  if self.last_sibling >= self.buf.offset() {
    self.seek(self.last_sibling)
    return
  }
  if self.last_unit && self.unit + 1 < self.units.length() {
    self.next_unit()
    return
  }

  // Traverse children manually
  while true {
    match self.next() {
      None => break
      Some(e) => {
        if e.tag() == TagVariable && e.offset() == 0L {
          // This is our null entry marker
          break
        }
        if e.children() {
          self.skip_children()
        }
      }
    }
  }
}

///|
/// Get current error state
pub fn Reader::get_error(self : Reader) -> String? {
  self.err
}

///|
/// Check if reader has error
pub fn Reader::has_error(self : Reader) -> Bool {
  match self.err {
    Some(_) => true
    None => false
  }
}

///|
/// Find unit index containing the given offset
fn Reader::offset_to_unit(self : Reader, off : Offset) -> Int {
  // This is a simplified implementation
  // Real implementation would need proper unit offset tracking
  for i = 0; i < self.units.length(); i = i + 1 {
    let u = self.units[i]
    if u.base <= off && off < u.base + u.data.length().to_int64() {
      return i
    }
  }
  -1
}

///|
/// Get current buffer offset
pub fn Reader::offset(self : Reader) -> Offset {
  self.buf.offset()
}

///|
/// Create a clone of this reader
pub fn Reader::clone(self : Reader) -> Reader {
  Reader::new(self.data, self.units)
}

///|
/// Reset reader to beginning
pub fn Reader::reset(self : Reader) -> Unit {
  self.seek(0L)
}

///|
/// Check if we're at end of data
pub fn Reader::at_end(self : Reader) -> Bool {
  self.buf.length() == 0 && self.unit >= self.units.length() - 1
}
