/// DWARF entry reading and parsing
/// Ported from Go's debug/dwarf package

///|
/// Parse a single DWARF entry from a buffer
fn Buf::entry(b : Buf, cu : Entry?, u : Unit_) -> Entry raise {
  let atab = u.atable
  let ubase = u.base
  let vers = u.vers
  let off = b.off
  let id = b.uint().to_uint()
  if id == 0U {
    // Null entry (end of children)
    return Entry::new(off, TagVariable, false)
  } // Use a dummy tag
  guard atab.get(id) is Some(a) else {
    raise b.error("unknown abbreviation code \{id}")
  }
  let e = Entry::new(off, a.tag(), a.children())

  // Parse all fields according to the abbreviation
  for field_def in a.fields() {
    match parse_field(b, field_def, cu, u) {
      Some(field) => e.add_field(field)
      None =>
        raise b.error(
          "failed to parse field for attribute \{field_def.attr()} with format \{field_def.format()}",
        )
    }
  }
  e
}

///|
/// Parse a single field from a buffer according to its definition
fn parse_field(buf : Buf, field_def : AField, cu : Entry?, u : Unit_) -> Field? {
  let attr = field_def.attr()
  let format = field_def.format()
  let class = field_def.class()

  // Handle indirect format
  let actual_format = if format == FormIndirect {
    match uint_to_format(buf.uint().to_uint()) {
      Some(f) => f
      None => return None // Invalid format
    }
  } else {
    format
  }

  // Parse the value based on the format
  match parse_field_value(buf, actual_format, attr, u) {
    Some(value) => Some(Field::new(attr, value, class))
    None => None
  }
}

///|
/// Parse a field value based on its format
fn parse_field_value(
  b : Buf,
  format : Format,
  attr : Attr,
  u : Unit_,
) -> FieldValue? {
  match format {
    // Address formats
    FormAddr => Some(VUInt64(b.addr()))
    FormAddrx => Some(VUInt64(parse_addrx(b, b.uint())))
    FormAddrx1 => Some(VUInt64(parse_addrx(b, b.uint8().to_uint64())))
    FormAddrx2 => Some(VUInt64(parse_addrx(b, b.uint16().to_uint64())))
    FormAddrx3 => Some(VUInt64(parse_addrx(b, b.uint24().to_uint64())))
    FormAddrx4 => Some(VUInt64(parse_addrx(b, b.uint32().to_uint64())))

    // Block formats
    FormDwarfBlock1 => Some(VBytes(b.bytes(b.uint8().to_int())))
    FormDwarfBlock2 => Some(VBytes(b.bytes(b.uint16().to_int())))
    FormDwarfBlock4 => Some(VBytes(b.bytes(b.uint32().to_int())))
    FormDwarfBlock => Some(VBytes(b.bytes(b.uint().to_int())))

    // Data formats
    FormData1 => Some(VInt64(b.uint8().to_int64()))
    FormData2 => Some(VInt64(b.uint16().to_int64()))
    FormData4 => Some(VInt64(b.uint32().to_int64()))
    FormData8 => Some(VInt64(b.uint64().reinterpret_as_int64()))
    FormData16 => Some(VBytes(b.bytes(16)))
    FormSdata => Some(VInt64(b.int()))
    FormUdata => Some(VInt64(b.uint().reinterpret_as_int64()))
    FormImplicitConst =>
      // Value was stored in abbreviation table, need to get it from field_def
      // For now, return 0 - this would need the field_def passed through
      Some(VInt64(0L))

    // Flag formats
    FormFlag => Some(VBool(b.uint8() == 1U))
    FormFlagPresent => Some(VBool(true)) // Presence implies true

    // Reference formats
    FormRefAddr => {
      let vers = u.version()
      if vers == 2 {
        Some(VOffset(b.addr().reinterpret_as_int64()))
        // DWARF 3+
      } else if u.is_dwarf64() {
        Some(VOffset(b.uint64().reinterpret_as_int64()))
      } else {
        Some(VOffset(b.uint32().to_int64()))
      }
    }
    FormRef1 => Some(VOffset(b.uint8().to_int64()))
    FormRef2 => Some(VOffset(b.uint16().to_int64()))
    FormRef4 => Some(VOffset(b.uint32().to_int64()))
    FormRef8 => Some(VOffset(b.uint64().reinterpret_as_int64()))
    FormRefUdata => Some(VOffset(b.uint().reinterpret_as_int64()))
    FormRefSig8 => Some(VUInt64(b.uint64()))
    FormRefSup4 => Some(VUInt64(b.uint32().to_uint64()))
    FormRefSup8 => Some(VUInt64(b.uint64()))

    // String formats
    FormString => Some(VString(b.string()))
    FormStrp => Some(VString(parse_strp(b)))
    FormLineStrp => Some(VString(parse_line_strp(b)))
    FormStrx => Some(VString(parse_strx(b, b.uint())))
    FormStrx1 => Some(VString(parse_strx(b, b.uint8().to_uint64())))
    FormStrx2 => Some(VString(parse_strx(b, b.uint16().to_uint64())))
    FormStrx3 => Some(VString(parse_strx(b, b.uint24().to_uint64())))
    FormStrx4 => Some(VString(parse_strx(b, b.uint32().to_uint64())))
    FormStrpSup => Some(VUInt64(b.uint64())) // Offset into alternate string section

    // Section offset formats
    FormSecOffset =>
      if u.is_dwarf64() {
        Some(VInt64(b.uint64().reinterpret_as_int64()))
      } else {
        Some(VInt64(b.uint32().to_int64()))
      }

    // Expression location
    FormExprloc => Some(VBytes(b.bytes(b.uint().to_int())))

    // List references
    FormLoclistx => Some(VUInt64(b.uint()))
    FormRnglistx => Some(VUInt64(b.uint()))

    // GNU extensions
    FormGnuRefAlt =>
      if u.is_dwarf64() {
        Some(VInt64(b.uint64().reinterpret_as_int64()))
      } else {
        Some(VInt64(b.uint32().to_int64()))
      }
    FormGnuStrpAlt =>
      if u.is_dwarf64() {
        Some(VUInt64(b.uint64()))
      } else {
        Some(VUInt64(b.uint32().to_uint64()))
      }

    // Unsupported or unknown formats
    _ => None
  }
}

///|
/// Parse address index (DWARF 5)
fn parse_addrx(buf : Buf, index : UInt64) -> UInt64 {
  // For now, just return the index as an address
  // Full implementation would look up in .debug_addr section
  index
}

///|
/// Parse string pointer from .debug_str section
fn parse_strp(buf : Buf) -> String {
  ...
}

///|
/// Parse string pointer from .debug_line_str section
fn parse_line_strp(buf : Buf) -> String {
  ...
}

///|
/// Parse string index (DWARF 5)
fn parse_strx(buf : Buf, index : UInt64) -> String {
  ...
}

/// uint_to_format is defined in abbrev.mbt

///|
/// Check if buffer has data remaining
fn Buf::has_data(self : Buf) -> Bool {
  self.length() > 0
}

///|
/// Peek at next entry ID without consuming it
fn Buf::peek_entry_id(self : Buf) -> UInt? {
  if self.length() < 1 {
    return None
  }

  // This is a simplified peek - real implementation would need
  // to handle variable-length integers properly
  Some(self.data[0].to_uint())
}
/// DWARF abbreviation table parsing
/// Ported from Go's debug/dwarf package

///|
/// Abbreviation table entry - describes how to parse a DWARF entry
pub struct Abbrev {
  tag : Tag
  children : Bool
  fields : Array[AField]
} derive(Show)

///|
/// Create a new Abbrev
pub fn Abbrev::new(tag : Tag, children : Bool) -> Abbrev {
  { tag, children, fields: [] }
}

///|
/// Add a field to the abbreviation
pub fn Abbrev::add_field(self : Abbrev, field : AField) -> Unit {
  self.fields.push(field)
}

///|
/// Get the tag
pub fn Abbrev::tag(self : Abbrev) -> Tag {
  self.tag
}

///|
/// Check if has children
pub fn Abbrev::children(self : Abbrev) -> Bool {
  self.children
}

///|
/// Get fields
pub fn Abbrev::fields(self : Abbrev) -> Array[AField] {
  self.fields
}

///|
/// Abbreviation field - describes a single attribute in an entry
pub struct AField {
  attr : Attr
  format : Format
  class : Class
  val : Int64 // for FormImplicitConst
} derive(Show)

///|
/// Create a new AField
pub fn AField::new(
  attr : Attr,
  format : Format,
  class : Class,
  val : Int64,
) -> AField {
  { attr, format, class, val }
}

///|
/// Get the attribute
pub fn AField::attr(self : AField) -> Attr {
  self.attr
}

///|
/// Get the format
pub fn AField::format(self : AField) -> Format {
  self.format
}

///|
/// Get the class
pub fn AField::class(self : AField) -> Class {
  self.class
}

///|
/// Get the implicit const value
pub fn AField::val(self : AField) -> Int64 {
  self.val
}

///|
/// Abbreviation table - maps abbreviation codes to abbreviation entries
pub typealias Map[UInt, Abbrev] as AbbrevTable

///|
/// Parse abbreviation table from the .debug_abbrev section
fn parse_abbrev(d : Data, off : UInt64, vers : Int) -> AbbrevTable raise {
  // Check cache first
  if d.abbrev_cache.get(off) is Some(m) {
    return m
  }
  let data = d.abbrev
  let data = if off > data.length().to_uint64() {
    @slice.new()
  } else {
    data[off.to_int():]
  }
  let b = make_buf(Some(d), UnknownFormat::new(), "abbrev", 0, data)
  let table : AbbrevTable = {}
  while true {
    // Table ends with id == 0
    let id = b.uint().to_uint()
    if id == 0U {
      break
    }

    // Count attributes first to pre-allocate
    let mut n = 0
    let b1 = b // Copy for counting
    let _tag = b1.uint() // skip tag
    let _children = b1.uint8() // skip children
    while true {
      let tag = b1.uint()
      let fmt = b1.uint()
      if tag == 0UL && fmt == 0UL {
        break
      }
      if fmt == format_to_uint(FormImplicitConst) {
        let _val = b1.int()
        // skip implicit const value
      }
      n = n + 1
    }
    if b1.has_error() {
      match b1.get_error() {
        Some(err) => return Err(err.to_string())
        None => return Err("error counting abbreviation fields")
      }
    }

    // Read the abbreviation
    let tag_val = b.uint()
    let tag = match uint_to_tag(tag_val.to_uint()) {
      Some(t) => t
      None => TagVariable // default fallback
    }
    let children = b.uint8() != 0U
    let abbrev = Abbrev::new(tag, children)
    for _i = 0; _i < n; _i = _i + 1 {
      let attr_val = b.uint()
      let fmt_val = b.uint()
      let attr = match uint_to_attr(attr_val.to_uint()) {
        Some(a) => a
        None => AttrName // default fallback
      }
      let format = match uint_to_format(fmt_val.to_uint()) {
        Some(f) => f
        None => FormString // default fallback
      }
      let class = format_to_class(format, attr, vers)
      let val = if format == FormImplicitConst { b.int() } else { 0L }
      let _ = abbrev.add_field(AField::new(attr, format, class, val))

    }

    // Skip terminating zeros
    let _end1 = b.uint()
    let _end2 = b.uint()
    table.set(id, abbrev)
  }
  if b.has_error() {
    match b.get_error() {
      Some(err) => return Err(err.to_string())
      None => return Err("error parsing abbreviation table")
    }
  }

  // Cache the result
  let _ = d.set_abbrev_cache(off, table)
  Ok(table)
}

///|
/// Convert Format to Class based on attribute and DWARF version
fn format_to_class(format : Format, attr : Attr, vers : Int) -> Class {
  match format {
    FormAddr | FormAddrx | FormAddrx1 | FormAddrx2 | FormAddrx3 | FormAddrx4 =>
      ClassAddress
    FormDwarfBlock1 | FormDwarfBlock2 | FormDwarfBlock4 | FormDwarfBlock =>
      // Check if this should be ClassExprLoc based on attribute
      if is_exprloc_attr(attr) {
        ClassExprLoc
      } else {
        ClassBlock
      }
    FormData1
    | FormData2
    | FormData4
    | FormData8
    | FormSdata
    | FormUdata
    | FormData16
    | FormImplicitConst =>
      // Check if this should be a pointer class for older DWARF versions
      if vers < 4 {
        match get_ptr_class(attr) {
          Some(class) => class
          None => ClassConstant
        }
      } else {
        ClassConstant
      }
    FormFlag | FormFlagPresent => ClassFlag
    FormRefAddr
    | FormRef1
    | FormRef2
    | FormRef4
    | FormRef8
    | FormRefUdata
    | FormRefSup4
    | FormRefSup8 => ClassReference
    FormRefSig8 => ClassReferenceSig
    FormString
    | FormStrp
    | FormStrx
    | FormStrpSup
    | FormLineStrp
    | FormStrx1
    | FormStrx2
    | FormStrx3
    | FormStrx4 => ClassString
    FormSecOffset =>
      match get_ptr_class(attr) {
        Some(class) => class
        None => ClassUnknown
      }
    FormExprloc => ClassExprLoc
    FormGnuRefAlt => ClassReference
    FormGnuStrpAlt => ClassString
    FormLoclistx => ClassLocListPtr
    FormRnglistx => ClassRangeListPtr
    _ => ClassUnknown
  }
}

///|
/// Check if an attribute allows expression location values
fn is_exprloc_attr(attr : Attr) -> Bool {
  match attr {
    AttrLocation
    | AttrByteSize
    | AttrBitOffset
    | AttrBitSize
    | AttrStringLength
    | AttrLowerBound
    | AttrReturnAddr
    | AttrStrideSize
    | AttrUpperBound
    | AttrCount
    | AttrDataMemberLoc
    | AttrFrameBase
    | AttrSegment
    | AttrStaticLink
    | AttrUseLocation
    | AttrVtableElemLoc
    | AttrAllocated
    | AttrAssociated
    | AttrDataLocation
    | AttrStride => true
    _ => false
  }
}

///|
/// Get pointer class for specific attributes
fn get_ptr_class(attr : Attr) -> Class? {
  match attr {
    AttrLocation => Some(ClassLocListPtr)
    AttrStmtList => Some(ClassLinePtr)
    AttrStringLength => Some(ClassLocListPtr)
    AttrReturnAddr => Some(ClassLocListPtr)
    AttrStartScope => Some(ClassRangeListPtr)
    AttrDataMemberLoc => Some(ClassLocListPtr)
    AttrFrameBase => Some(ClassLocListPtr)
    AttrMacroInfo => Some(ClassMacPtr)
    AttrSegment => Some(ClassLocListPtr)
    AttrStaticLink => Some(ClassLocListPtr)
    AttrUseLocation => Some(ClassLocListPtr)
    AttrVtableElemLoc => Some(ClassLocListPtr)
    AttrRanges => Some(ClassRangeListPtr)
    AttrStrOffsetsBase => Some(ClassConstant)
    AttrAddrBase => Some(ClassConstant)
    AttrRnglistsBase => Some(ClassConstant)
    AttrLoclistsBase => Some(ClassLocListPtr)
    _ => None
  }
}

///|
/// Convert UInt to Attr
fn uint_to_attr(val : UInt) -> Attr? {
  Attr::from_uint(val)
}

///|
/// Convert UInt to Tag
fn uint_to_tag(val : UInt) -> Tag? {
  Tag::from_uint(val)
}

///|
/// Convert UInt to Format
fn uint_to_format(val : UInt) -> Format? {
  Format::from_uint(val)
}

///|
/// Convert Format to UInt
fn format_to_uint(format : Format) -> UInt64 {
  match format {
    FormAddr => 0x01UL
    FormDwarfBlock2 => 0x03UL
    FormDwarfBlock4 => 0x04UL
    FormData2 => 0x05UL
    FormData4 => 0x06UL
    FormData8 => 0x07UL
    FormString => 0x08UL
    FormDwarfBlock => 0x09UL
    FormDwarfBlock1 => 0x0AUL
    FormData1 => 0x0BUL
    FormFlag => 0x0CUL
    FormSdata => 0x0DUL
    FormStrp => 0x0EUL
    FormUdata => 0x0FUL
    FormRefAddr => 0x10UL
    FormRef1 => 0x11UL
    FormRef2 => 0x12UL
    FormRef4 => 0x13UL
    FormRef8 => 0x14UL
    FormRefUdata => 0x15UL
    FormIndirect => 0x16UL
    FormSecOffset => 0x17UL
    FormExprloc => 0x18UL
    FormFlagPresent => 0x19UL
    FormRefSig8 => 0x20UL
    FormStrx => 0x1AUL
    FormAddrx => 0x1BUL
    FormRefSup4 => 0x1CUL
    FormStrpSup => 0x1DUL
    FormData16 => 0x1EUL
    FormLineStrp => 0x1FUL
    FormImplicitConst => 0x21UL
    FormLoclistx => 0x22UL
    FormRnglistx => 0x23UL
    FormRefSup8 => 0x24UL
    FormStrx1 => 0x25UL
    FormStrx2 => 0x26UL
    FormStrx3 => 0x27UL
    FormStrx4 => 0x28UL
    FormAddrx1 => 0x29UL
    FormAddrx2 => 0x2AUL
    FormAddrx3 => 0x2BUL
    FormAddrx4 => 0x2CUL
    FormGnuRefAlt => 0x1F20UL
    FormGnuStrpAlt => 0x1F21UL
  }
}

///|
/// A Reader allows reading Entry structures from a DWARF "info" section.
/// The Entry structures are arranged in a tree. The Reader.next function
/// returns successive entries from a pre-order traversal of the tree.
/// If an entry has children, its children field will be true, and the children
/// follow, terminated by an Entry with tag 0.
struct Reader {
  mut b : Buf
  d : Data
  mut err : String?
  mut unit : Int
  mut last_unit : Bool // set if last entry returned by next is TagCompileUnit/TagPartialUnit
  mut last_children : Bool // .children of last entry returned by next
  mut last_sibling : Offset // .val(AttrSibling) of last entry returned by next
  mut cu : Entry? // current compilation unit
}

///|
/// Create a new Reader for this Data.
/// The reader is positioned at byte offset 0 in the DWARF "info" section.
pub fn Data::reader(self : Data) -> Reader {
  ...
}

///|
/// Get address size of current compilation unit
pub fn Reader::address_size(self : Reader) -> Int {
  self.d.unit[self.unit].asize
}

///|
/// Get byte order of current compilation unit
pub fn Reader::byte_order(self : Reader) -> ByteOrder {
  self.d.order
}

///|
/// Seek positions the Reader at offset off in the encoded entry stream.
/// Offset 0 can be used to denote the first entry.
pub fn Reader::seek(self : Reader, off : Offset) -> Unit {
  let d = self.d
  self.err = None
  self.last_children = false
  if off == 0L {
    if self.d.unit.length() == 0 {
      return
    }
    let u = self.d.unit[0]
    self.unit = 0
    self.b = make_buf(Some(self.d), u, "info", off, u.data)
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
  let u = d.unit[i]
  self.unit = i
  self.b = make_buf(Some(self.d), u, "info", off, u.data[off - u.off:])
}

///|
/// Move to next unit if current one is finished
fn Reader::maybe_next_unit(self : Reader) -> Unit {
  while self.b.length() == 0 && self.unit + 1 < self.units.length() {
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
  self.b = make_buf(
    Some(self.d),
    UnknownFormat::new(),
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
  if self.b.length() == 0 {
    return None
  }
  if self.unit >= self.units.length() {
    self.err = Some("unit index out of range")
    return None
  }
  let u = self.units[self.unit]

  // Get abbreviation table for this unit
  let atable = match parse_abbrev(self.d, 0UL, u.version()) {
    Ok(table) => table
    Err(error) => {
      self.err = Some(error)
      return None
    }
  }
  let entry = parse_entry(self.b, self.cu, u, atable)
  if self.b.has_error() {
    match self.b.get_error() {
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
  if self.last_sibling >= self.b.offset() {
    self.seek(self.last_sibling)
    return
  }
  if self.last_unit && self.unit + 1 < self.d.unit.length() {
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
/// Create a clone of this reader
fn Reader::clone(r : Reader) -> Reader {
  r.d.reader()
}

///|
/// Get current buffer offset
pub fn Reader::offset(r : Reader) -> Offset {
  r.b.offset()
}
