/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

/// DWARF debug information entry parser.
/// An entry is a sequence of data items of a given format.
/// The first word in the entry is an index into what DWARF
/// calls the ``abbreviation table.''  An abbreviation is really
/// just a type descriptor: it's an array of attribute tag/value format pairs.

///|
/// a single entry's description: a sequence of attributes
priv struct Abbrev {
  mut tag : Tag
  mut children : Bool
  mut fields : FixedArray[AField]
}

///|
impl Default for Abbrev with default() -> Abbrev {
  Abbrev::{ tag: TagVariable, children: false, fields: [] }
}

///|
/// Get the tag
fn Abbrev::tag(self : Abbrev) -> Tag {
  self.tag
}

///|
/// Check if has children
fn Abbrev::children(self : Abbrev) -> Bool {
  self.children
}

///|
/// Get fields
fn Abbrev::fields(self : Abbrev) -> FixedArray[AField] {
  self.fields
}

///|
priv struct AField {
  mut attr : Attr
  mut fmt : Format
  mut class : Class
  mut val : Int64 // for FormImplicitConst
}

///|
impl Default for AField with default() -> AField {
  AField::{ attr: AttrName, fmt: FormString, class: ClassUnknown, val: 0L }
}

///|
/// Get the attribute
fn AField::attr(self : AField) -> Attr {
  self.attr
}

///|
/// Get the format
fn AField::format(self : AField) -> Format {
  self.fmt
}

///|
/// Get the class
fn AField::class(self : AField) -> Class {
  self.class
}

///|
/// Abbreviation table - maps abbreviation codes to abbreviation entries
typealias Map[UInt, Abbrev] as AbbrevTable

///|
/// parse_abbrev returns the abbreviation table that starts at byte off
/// in the .debug_abbrev section.
fn Data::parse_abbrev(d : Data, off : UInt64, vers : Int) -> AbbrevTable raise {
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
  let b = make_buf(d, UnknownFormat::new(), "abbrev", 0, data)
  let m : AbbrevTable = {}
  while true {
    // Table ends with id == 0
    let id = b.uint().to_uint()
    if id == 0U {
      break
    }

    // Walk over attributes, counting
    let mut n = 0
    let b1 = b // Read from copy of b
    let _ = b1.uint()
    let _ = b1.uint8()
    while true {
      let tag = b1.uint()
      let fmt = b1.uint()
      if tag == 0UL && fmt == 0UL {
        break
      }
      if fmt == FormImplicitConst.to_uint().to_uint64() {
        let _ = b1.int()

      }
      n += 1
    }
    if b1.err is Some(err) {
      raise err
    }

    // Walk over attributes again, this time writing them down.
    let a = Abbrev::default()
    a.tag = match uint_to_tag(b.uint().to_uint()) {
      Some(t) => t
      None => TagVariable // default fallback
    }
    a.children = b.uint8() != 0U
    a.fields = FixedArray::make(n, AField::default())
    for i = 0; i < n; i = i + 1 {
      a.fields[i].attr = Attr::from_uint(b.uint().to_uint())
      a.fields[i].fmt = Format::from_uint(b.uint().to_uint())
      a.fields[i].class = format_to_class(
        a.fields[i].fmt,
        a.fields[i].attr,
        vers,
        b,
      )
      if a.fields[i].fmt == FormImplicitConst {
        a.fields[i].val = b.int()
      }
    }
    ignore(b.uint())
    ignore(b.uint())
    m[id] = a
  }
  if b.err is Some(err) {
    raise err
  }
  d.abbrev_cache[off] = m
  m
}

///|
/// An entry is a sequence of attribute/value pairs.
pub struct Entry {
  offset : Offset // offset of Entry in DWARF info
  tag : Tag // tag (kind of Entry)
  children : Bool // whether Entry is followed by children
  fields : Array[Field]
} derive(Show)

///|
/// Create a new Entry
pub fn Entry::new(offset : Offset, tag : Tag, children : Bool) -> Entry {
  { offset, tag, children, fields: [] }
}

///|
/// A Field is a single attribute/value pair in an [Entry].
///
/// A value can be one of several "attribute classes" defined by DWARF.
/// The Go types corresponding to each class are:
///
///	DWARF class       Go type        Class
///	-----------       -------        -----
///	address           uint64         ClassAddress
///	block             []byte         ClassBlock
///	constant          int64          ClassConstant
///	flag              bool           ClassFlag
///	reference
///	  to info         dwarf.Offset   ClassReference
///	  to type unit    uint64         ClassReferenceSig
///	string            string         ClassString
///	exprloc           []byte         ClassExprLoc
///	lineptr           int64          ClassLinePtr
///	loclistptr        int64          ClassLocListPtr
///	macptr            int64          ClassMacPtr
///	rangelistptr      int64          ClassRangeListPtr
///
/// For unrecognized or vendor-defined attributes, [Class] may be
/// [ClassUnknown].
pub struct Field {
  attr : Attr
  val : FieldValue
  class : Class
} derive(Show)

///|
pub enum FieldValue {
  UInt64(UInt64)
  Bytes(@slice.Slice[Byte])
  Bool(Bool)
  Int64(Int64)
  String(String)
  Offset(Offset)
} derive(Show)

///|
/// Create a new Field
pub fn Field::new(attr : Attr, val : FieldValue, class : Class) -> Field {
  { attr, val, class }
}

///|
/// A Class is the DWARF 4 class of an attribute value.
///
/// In general, a given attribute's value may take on one of several
/// possible classes defined by DWARF, each of which leads to a
/// slightly different interpretation of the attribute.
pub enum Class {
  // ClassUnknown represents values of unknown DWARF class.
  ClassUnknown
  // ClassAddress represents values of type uint64 that are addresses on the target machine.
  ClassAddress
  // ClassBlock represents values of type []byte whose interpretation depends on the attribute.
  ClassBlock
  // ClassConstant represents values of type int64 that are constants.
  ClassConstant
  // ClassExprLoc represents values of type []byte that contain an encoded DWARF expression or location description.
  ClassExprLoc
  // ClassFlag represents values of type bool.
  ClassFlag
  // ClassLinePtr represents values that are an int64 offset into the "line" section.
  ClassLinePtr
  // ClassLocListPtr represents values that are an int64 offset into the "loclist" section.
  ClassLocListPtr
  // ClassMacPtr represents values that are an int64 offset into the "mac" section.
  ClassMacPtr
  // ClassRangeListPtr represents values that are an int64 offset into the "rangelist" section.
  ClassRangeListPtr
  // ClassReference represents values that are an Offset offset of an Entry in the info section.
  ClassReference
  // ClassReferenceSig represents values that are a uint64 type signature referencing a type Entry.
  ClassReferenceSig
  // ClassString represents values that are strings.
  ClassString
  // ClassReferenceAlt represents values of type int64 that are an offset into the DWARF "info" section of an alternate object file.
  ClassReferenceAlt
  // ClassStringAlt represents values of type int64 that are an offset into the DWARF string section of an alternate object file.
  ClassStringAlt
  // ClassAddrPtr represents values that are an int64 offset into the "addr" section.
  ClassAddrPtr
  // ClassLocList represents values that are an int64 offset into the "loclists" section.
  ClassLocList
  // ClassRngList represents values that are a uint64 offset from the base of the "rnglists" section.
  ClassRngList
  // ClassRngListsPtr represents values that are an int64 offset into the "rnglists" section.
  ClassRngListsPtr
  // ClassStrOffsetsPtr represents values that are an int64 offset into the "str_offsets" section.
  ClassStrOffsetsPtr
} derive(Show, Eq)

///|
/// Get the value associated with attribute attr in Entry,
/// or None if there is no such attribute.
pub fn Entry::val(e : Entry, a : Attr) -> FieldValue? {
  match e.attr_field(a) {
    Some(field) => Some(field.val)
    None => None
  }
}

///|
/// Get the Field associated with attribute attr in Entry,
/// or None if there is no such attribute.
pub fn Entry::attr_field(e : Entry, a : Attr) -> Field? {
  for field in e.fields {
    if field.attr == a {
      return Some(field)
    }
  }
  None
}

///|
/// Offset represents an offset within the DWARF info.
pub typealias UInt as Offset

///|
/// Parse a single DWARF entry from a buffer
fn Buf::entry(b : Buf, cu : Entry?, u : Unit) -> Entry? raise {
  let atab = u.atable
  let ubase = u.base
  let vers = u.vers
  let off = b.off
  let id = b.uint().to_uint()
  if id == 0U {
    // Null entry (end of children)
    return Some(Entry::{ offset: 0, tag: Tag(0), children: false, fields: [] })
  } // Use a dummy tag
  guard atab.get(id) is Some(a) else {
    raise b.error("unknown abbreviation code \{id}")
  }
  let e = Entry::{
    offset: off,
    tag: a.tag(),
    children: a.children(),
    fields: [],
  }
  for a_field in a.fields {
    match parse_field(b, a_field, vers, u) {
      Some(field) => e.fields.push(field)
      None =>
        raise b.error(
          "failed to parse field for attribute \{a_field.attr()} with format \{a_field.format()}",
        )
    }
  }
  Some(e)
}

///|
/// Parse a single field from a buffer according to its definition
fn parse_field(b : Buf, a_field : AField, vers : Int, u : Unit) -> Field? raise {
  let attr = a_field.attr
  let fmt = a_field.fmt
  let mut class = a_field.class
  let fmt = if fmt == FormIndirect {
    let fmt = Format::from_uint(b.uint().to_uint())
    class = format_to_class(fmt, attr, vers, b)
    fmt
  } else {
    fmt
  }

  // Parse the value based on the format
  match parse_field_value(b, fmt, u) {
    Some(value) => Some(Field::new(attr, value, class))
    None => None
  }
}

///|
/// Parse a field value based on its format
fn parse_field_value(b : Buf, fmt : Format, u : Unit) -> FieldValue? raise {
  match fmt {
    // Address formats
    FormAddr => Some(UInt64(b.addr()))
    FormAddrx => Some(UInt64(parse_addrx(b, b.uint())))
    FormAddrx1 => Some(UInt64(parse_addrx(b, b.uint8().to_uint64())))
    FormAddrx2 => Some(UInt64(parse_addrx(b, b.uint16().to_uint64())))
    FormAddrx3 => Some(UInt64(parse_addrx(b, b.uint24().to_uint64())))
    FormAddrx4 => Some(UInt64(parse_addrx(b, b.uint32().to_uint64())))

    // Block formats
    FormDwarfBlock1 => Some(Bytes(b.bytes(b.uint8().reinterpret_as_int())))
    FormDwarfBlock2 => Some(Bytes(b.bytes(b.uint16().reinterpret_as_int())))
    FormDwarfBlock4 => Some(Bytes(b.bytes(b.uint32().reinterpret_as_int())))
    FormDwarfBlock => Some(Bytes(b.bytes(b.uint().to_int())))

    // Data formats
    FormData1 => Some(Int64(b.uint8().to_int64()))
    FormData2 => Some(Int64(b.uint16().to_int64()))
    FormData4 => Some(Int64(b.uint32().to_int64()))
    FormData8 => Some(Int64(b.uint64().reinterpret_as_int64()))
    FormData16 => Some(Bytes(b.bytes(16)))
    FormSdata => Some(Int64(b.int()))
    FormUdata => Some(Int64(b.uint().reinterpret_as_int64()))
    FormImplicitConst =>
      // Value was stored in abbreviation table, need to get it from field_def
      // For now, return 0 - this would need the field_def passed through
      Some(Int64(0L))

    // Flag formats
    FormFlag => Some(Bool(b.uint8() == 1U))
    FormFlagPresent => Some(Bool(true)) // Presence implies true

    // Reference formats
    FormRefAddr => {
      let vers = u.version()
      if vers == 2 {
        Some(Offset(b.addr().to_uint()))
        // DWARF 3+
      } else if u.is64 {
        Some(Offset(b.uint64().to_uint()))
      } else {
        Some(Offset(b.uint32()))
      }
    }
    FormRef1 => Some(Offset(b.uint8()))
    FormRef2 => Some(Offset(b.uint16()))
    FormRef4 => Some(Offset(b.uint32()))
    FormRef8 => Some(Offset(b.uint64().to_uint()))
    FormRefUdata => Some(Offset(b.uint().to_uint()))
    FormRefSig8 => Some(UInt64(b.uint64()))
    FormRefSup4 => Some(UInt64(b.uint32().to_uint64()))
    FormRefSup8 => Some(UInt64(b.uint64()))

    // String formats
    FormString => Some(String(b.string()))
    FormStrp => Some(String(parse_strp(b)))
    FormLineStrp => Some(String(parse_line_strp(b)))
    FormStrx => Some(String(parse_strx(b, b.uint(), u)))
    FormStrx1 => Some(String(parse_strx(b, b.uint8().to_uint64(), u)))
    FormStrx2 => Some(String(parse_strx(b, b.uint16().to_uint64(), u)))
    FormStrx3 => Some(String(parse_strx(b, b.uint24().to_uint64(), u)))
    FormStrx4 => Some(String(parse_strx(b, b.uint32().to_uint64(), u)))
    FormStrpSup => Some(UInt64(b.uint64())) // Offset into alternate string section

    // Section offset formats
    FormSecOffset =>
      if u.is64 {
        Some(Int64(b.uint64().reinterpret_as_int64()))
      } else {
        Some(Int64(b.uint32().to_int64()))
      }

    // Expression location
    FormExprloc => Some(Bytes(b.bytes(b.uint().to_int())))

    // List references
    FormLoclistx => Some(UInt64(b.uint()))
    FormRnglistx => Some(UInt64(b.uint()))

    // GNU extensions
    FormGnuRefAlt =>
      if u.is64 {
        Some(Int64(b.uint64().reinterpret_as_int64()))
      } else {
        Some(Int64(b.uint32().to_int64()))
      }
    FormGnuStrpAlt =>
      if u.is64 {
        Some(UInt64(b.uint64()))
      } else {
        Some(UInt64(b.uint32().to_uint64()))
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
fn parse_strp(b : Buf) -> String raise {
  let mut off : UInt64 = 0UL // offset into .debug_str
  let (is64, known) = b.format.dwarf64()
  if not(known) {
    raise b.error("unknown size for DW_FORM_strp")
  } else if is64 {
    off = b.uint64()
  } else {
    off = b.uint32().to_uint64()
  }
  if off.to_int().to_uint64() != off {
    raise b.error("DW_FORM_strp offset out of range")
  }
  if b.err is Some(err) {
    raise err
  }
  let b1 = make_buf(b.dwarf, b.format, "str", 0, b.dwarf.str)
  b1.skip(off.to_int())
  let val = b1.string()
  if b1.err is Some(err) {
    raise err
  }
  val
}

///|
/// Parse string pointer from .debug_line_str section
fn parse_line_strp(b : Buf) -> String raise {
  let mut off : UInt64 = 0UL // offset into .debug_line_str
  let (is64, known) = b.format.dwarf64()
  if not(known) {
    raise b.error("unknown size for DW_FORM_line_strp")
  } else if is64 {
    off = b.uint64()
  } else {
    off = b.uint32().to_uint64()
  }
  if off.to_int() < 0 {
    raise b.error("DW_FORM_line_strp offset out of range")
  }
  let d = b.dwarf
  if d.line_str.length() == 0 {
    raise b.error("DW_FORM_line_strp with no .debug_line_str section")
  }
  let b1 = make_buf(d, b.format, "line_str", 0, d.line_str)
  b1.skip(off.to_int())
  let val = b1.string()
  if b1.err is Some(err) {
    raise err
  }
  val
}

///|
/// Parse string index (DWARF 5)
fn parse_strx(b : Buf, index : UInt64, u : Unit) -> String raise {
  if b.dwarf.str_offsets.length() == 0 {
    raise b.error("DW_FORM_strx with no .debug_str_offsets section")
  }
  let (is64, known) = b.format.dwarf64()
  if !known {
    raise b.error("unknown offset size for DW_FORM_strx")
  }
  let mut off = index
  if is64 {
    off = off * 8UL
  } else {
    off = off * 4UL
  }

  // Add base offset if available (DWARF 5)
  let str_base = u.str_offsets_base()
  off = off + str_base
  let b1 = make_buf(b.dwarf, b.format, "str_offsets", 0, b.dwarf.str_offsets)
  b1.skip(off.to_int())
  let str_off = if is64 { b1.uint64() } else { b1.uint32().to_uint64() }
  if b1.err is Some(err) {
    raise err
  }
  if str_off.to_int() < 0 {
    raise b.error("DW_FORM_strx indirect offset out of range")
  }
  let b2 = make_buf(b.dwarf, b.format, "str", 0, b.dwarf.str)
  b2.skip(str_off.to_int())
  let val = b2.string()
  if b2.err is Some(err) {
    raise err
  }
  val
}

///|
/// attrIsExprloc indicates attributes that allow exprloc values that
/// are encoded as block values in DWARF 2 and 3. See DWARF 4, Figure
/// 20.
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
fn attr_ptr_class(attr : Attr) -> Class? {
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
/// Convert Format to Class based on attribute and DWARF version
fn format_to_class(format : Format, attr : Attr, vers : Int, b : Buf) -> Class {
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
        match attr_ptr_class(attr) {
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
      match attr_ptr_class(attr) {
        Some(class) => class
        None => ClassUnknown
      }
    FormExprloc => ClassExprLoc
    FormGnuRefAlt => ClassReference
    FormGnuStrpAlt => ClassString
    FormLoclistx => ClassLocListPtr
    FormRnglistx => ClassRangeListPtr
    FormIndirect => ClassUnknown
    Format(_) => {
      ignore(b.error("cannot determine class of unknown attribute form"))
      ClassUnknown
    }
  }
}

///|
/// Convert UInt to Tag
fn uint_to_tag(val : UInt) -> Tag? {
  Tag::from_uint(val)
}

///|
/// Convert Format to UInt
fn Format::to_uint(format : Format) -> UInt {
  match format {
    FormAddr => 0x01
    FormDwarfBlock2 => 0x03
    FormDwarfBlock4 => 0x04
    FormData2 => 0x05
    FormData4 => 0x06
    FormData8 => 0x07
    FormString => 0x08
    FormDwarfBlock => 0x09
    FormDwarfBlock1 => 0x0A
    FormData1 => 0x0B
    FormFlag => 0x0C
    FormSdata => 0x0D
    FormStrp => 0x0E
    FormUdata => 0x0F
    FormRefAddr => 0x10
    FormRef1 => 0x11
    FormRef2 => 0x12
    FormRef4 => 0x13
    FormRef8 => 0x14
    FormRefUdata => 0x15
    FormIndirect => 0x16
    FormSecOffset => 0x17
    FormExprloc => 0x18
    FormFlagPresent => 0x19
    FormRefSig8 => 0x20
    FormStrx => 0x1A
    FormAddrx => 0x1B
    FormRefSup4 => 0x1C
    FormStrpSup => 0x1D
    FormData16 => 0x1E
    FormLineStrp => 0x1F
    FormImplicitConst => 0x21
    FormLoclistx => 0x22
    FormRnglistx => 0x23
    FormRefSup8 => 0x24
    FormStrx1 => 0x25
    FormStrx2 => 0x26
    FormStrx3 => 0x27
    FormStrx4 => 0x28
    FormAddrx1 => 0x29
    FormAddrx2 => 0x2A
    FormAddrx3 => 0x2B
    FormAddrx4 => 0x2C
    FormGnuRefAlt => 0x1F20
    FormGnuStrpAlt => 0x1F21
    Format(format) => format
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
  mut err : Error?
  mut unit : Int
  mut last_unit : Bool // set if last entry returned by next is TagCompileUnit/TagPartialUnit
  mut last_children : Bool // .children of last entry returned by next
  mut last_sibling : Offset // .val(AttrSibling) of last entry returned by next
  mut cu : Entry? // current compilation unit
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
priv suberror OffsetOutOfRange

///|
/// Seek positions the Reader at offset off in the encoded entry stream.
/// Offset 0 can be used to denote the first entry.
pub fn Reader::seek(r : Reader, off : Offset) -> @unit.T raise {
  let d = r.d
  r.err = None
  r.last_children = false
  if off == 0 {
    if r.d.unit.length() == 0 {
      return
    }
    let u = r.d.unit[0]
    r.unit = 0
    r.b = make_buf(r.d, u, "info", off, u.data)
    r.cu = None
    return
  }
  let i = r.offset_to_unit(off)
  if i == -1 {
    r.err = Some(OffsetOutOfRange)
    return
  }
  if i != r.unit {
    r.cu = None
  }
  let u = d.unit[i]
  r.unit = i
  r.b = make_buf(
    r.d,
    u,
    "info",
    off,
    u.data[off.reinterpret_as_int() - u.off.reinterpret_as_int():],
  )
  r.collect_dwarf5_base_offsets(u)
}

///|
/// Move to next unit if current one is finished
fn Reader::maybe_next_unit(self : Reader) -> @unit.T {
  while self.b.length() == 0 && self.unit + 1 < self.d.unit.length() {
    self.next_unit()
  }
}

///|
/// Advance to the next unit
fn Reader::next_unit(self : Reader) -> @unit.T {
  self.unit = self.unit + 1
  if self.unit >= self.d.unit.length() {
    return
  }
  let u = self.d.unit[self.unit]
  self.b = make_buf(
    self.d,
    UnknownFormat::new(),
    "info",
    0, // Unit's data starts at its offset
    u.data,
  )
  self.cu = None
}

///|
fn Reader::collect_dwarf5_base_offsets(r : Reader, u : Unit) -> @unit.T raise {
  if u.vers < 5 || u.unit5 is Some(_) {
    return
  }
  u.unit5 = Some(Unit5::default())
  r.d.collect_dwarf5_base_offsets(u)
}

///|
/// Read the next entry from the encoded entry stream.
/// It returns None when it reaches the end of the section.
/// It returns an error via the Reader's error field if the current offset
/// is invalid or the data cannot be decoded as a valid Entry.
pub fn Reader::next(r : Reader) -> Entry? raise {
  if r.err is Some(err) {
    raise err
  }
  r.maybe_next_unit()
  if r.b.length() == 0 {
    return None
  }
  let u = r.d.unit[r.unit]
  let e = r.b.entry(r.cu, u)
  r.last_unit = false
  if e is Some(e) {
    r.last_children = e.children
    if r.last_children {
      r.last_sibling = match e.val(AttrSibling) {
        Some(Offset(off)) => off
        _ => 0
      }
    }
    if e.tag == TagCompileUnit || e.tag == TagPartialUnit {
      r.last_unit = true
      r.cu = Some(e)
    }
  } else {
    r.last_children = false
  }
  e
}

///|
/// Skip over the child entries associated with the last Entry returned by next.
/// If that Entry did not have children or next has not been called, skip_children is a no-op.
pub fn Reader::skip_children(self : Reader) -> @unit.T raise {
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
        if e.tag == TagVariable && e.offset == 0 {
          // This is our null entry marker
          break
        }
        if e.children {
          self.skip_children()
        }
      }
    }
  }
}

///|
/// Find unit index containing the given offset
fn Reader::offset_to_unit(self : Reader, off : Offset) -> Int {
  // This is a simplified implementation
  // Real implementation would need proper unit offset tracking
  for i = 0; i < self.d.unit.length(); i = i + 1 {
    let u = self.d.unit[i]
    if u.base <= off && off < u.base + u.data.length().reinterpret_as_uint() {
      return i
    }
  }
  -1
}

///|
/// Create a clone of this reader
fn Reader::clone(r : Reader) -> Reader raise {
  r.d.reader()
}

///|
/// Get current buffer offset
pub fn Reader::offset(r : Reader) -> Offset {
  r.b.offset()
}

///|
/// Implement TypeReader for Reader
impl TypeReader for Reader with seek(r : Reader, off : Offset) -> @unit.T {
  r.seek(off) catch {
    err => r.err = Some(err)
  }
}

///|
impl TypeReader for Reader with next(r : Reader) -> Entry? raise {
  r.next()
}

///|
impl TypeReader for Reader with clone(r : Reader) -> Reader raise {
  r.d.reader()
}

///|
impl TypeReader for Reader with offset(r : Reader) -> Offset {
  r.offset()
}

///|
impl TypeReader for Reader with address_size(r : Reader) -> Int {
  r.address_size()
}

///|
/// SeekPC returns the Entry for the compilation unit that includes pc,
/// and positions the reader to read the children of that unit. If pc
/// is not covered by any unit, SeekPC returns ErrUnknownPC and the
/// position of the reader is undefined.
///
/// Because compilation units can describe multiple regions of the
/// executable, in the worst case SeekPC must search through all the
/// ranges in all the compilation units. Each call to SeekPC starts the
/// search at the compilation unit of the last call, so in general
/// looking up a series of PCs will be faster if they are sorted. If
/// the caller wishes to do repeated fast PC lookups, it should build
/// an appropriate index using the Ranges method.
pub fn Reader::seek_pc(r : Reader, pc : UInt64) -> Entry? raise {
  let mut unit = r.unit
  for i = 0; i < r.d.unit.length(); i = i + 1 {
    if unit >= r.d.unit.length() {
      unit = 0
    }
    r.err = None
    r.last_children = false
    r.unit = unit
    r.cu = None
    let u = r.d.unit[unit]
    r.b = make_buf(r.d, u, "info", u.off, u.data)
    r.collect_dwarf5_base_offsets(u)
    guard r.next() is Some(e) else { raise UnknownPCError }
    if e.tag == Tag(0) {
      raise UnknownPCError
    }
    let ranges = r.d.ranges(e)
    for pcs in ranges {
      if pcs.0 <= pc && pc < pcs.1 {
        return Some(e)
      }
    }
    unit += 1
  }
  raise UnknownPCError
}

///|
/// Ranges returns the PC ranges covered by e, a slice of [low,high) pairs.
/// Only some entry types, such as TagCompileUnit or TagSubprogram, have PC
/// ranges; for others, this will return nil with no error.
pub fn Data::ranges(d : Data, e : Entry) -> Array[(UInt64, UInt64)] raise {
  let ret : Array[(UInt64, UInt64)] = []
  let low_ok = match e.val(AttrLowpc) {
    Some(UInt64(low)) => Some(low)
    _ => None
  }
  let mut high_ok : UInt64? = None
  match e.attr_field(AttrHighpc) {
    Some(high_field) =>
      match high_field.class {
        ClassAddress =>
          match high_field.val {
            UInt64(high) => high_ok = Some(high)
            _ => ()
          }
        ClassConstant =>
          match (low_ok, high_field.val) {
            (Some(low), Int64(off)) =>
              if off >= 0L {
                high_ok = Some(low + off.reinterpret_as_uint64())
              }
            _ => ()
          }
        _ => ()
      }
    None => ()
  }
  match (low_ok, high_ok) {
    (Some(low), Some(high)) => ret.push((low, high))
    _ => ()
  }
  let mut u : Unit? = None
  let uidx = d.offset_to_unit(e.offset)
  if uidx >= 0 && uidx < d.unit.length() {
    u = Some(d.unit[uidx])
  }
  match u {
    Some(unit) =>
      if unit.vers >= 5 && d.rng_lists.length() > 0 {
        // DWARF version 5 and later
        match e.attr_field(AttrRanges) {
          Some(field) =>
            match field.class {
              ClassRangeListPtr =>
                match field.val {
                  Int64(ranges) => {
                    let (cu, base) = d.base_address_for_entry(e)
                    let dwarf5_ranges = d.dwarf5_ranges(unit, cu, base, ranges)
                    for range in dwarf5_ranges {
                      ret.push(range)
                    }
                  }
                  _ => ()
                }
              ClassRngList =>
                match field.val {
                  UInt64(rnglist) => {
                    let (cu, base) = d.base_address_for_entry(e)
                    let dwarf5_ranges = d.dwarf5_ranges(
                      unit,
                      cu,
                      base,
                      rnglist.reinterpret_as_int64(),
                    )
                    for range in dwarf5_ranges {
                      ret.push(range)
                    }
                  }
                  _ => ()
                }
              _ => ()
            }
          None => ()
        }
      } else {
        // DWARF version 2 through 4
        match e.val(AttrRanges) {
          Some(Int64(ranges)) =>
            if d.ranges.length() > 0 {
              let (_, base) = d.base_address_for_entry(e)
              let dwarf2_ranges = d.dwarf2_ranges(unit, base, ranges)
              for range in dwarf2_ranges {
                ret.push(range)
              }
            }
          _ => ()
        }
      }
    None => ()
  }
  ret
}

///|
/// baseAddressForEntry returns the initial base address to be used when
/// looking up the range list of entry e.
/// DWARF specifies that this should be the lowpc attribute of the enclosing
/// compilation unit, however comments in gdb/dwarf2read.c say that some
/// versions of GCC use the entrypc attribute, so we check that too.
fn Data::base_address_for_entry(d : Data, e : Entry) -> (Entry?, UInt64) raise {
  let mut cu : Entry? = None
  if e.tag == TagCompileUnit {
    cu = Some(e)
  } else {
    let i = d.offset_to_unit(e.offset)
    if i == -1 {
      raise DecodeError::new("ranges", e.offset, "no unit for entry")
    }
    let u = d.unit[i]
    let b = make_buf(d, u, "info", u.off, u.data)
    match b.entry(None, u) {
      Some(entry) => cu = Some(entry)
      None =>
        match b.err {
          Some(err) => raise err
          None =>
            raise DecodeError::new("ranges", e.offset, "failed to parse CU")
        }
    }
  }
  match cu {
    Some(cu_entry) =>
      match cu_entry.val(AttrEntrypc) {
        Some(UInt64(entry_pc)) => (Some(cu_entry), entry_pc)
        _ =>
          match cu_entry.val(AttrLowpc) {
            Some(UInt64(low_pc)) => (Some(cu_entry), low_pc)
            _ => (Some(cu_entry), 0UL)
          }
      }
    None => (None, 0UL)
  }
}

///|
/// DWARF 2-4 ranges parsing
fn Data::dwarf2_ranges(
  d : Data,
  u : Unit,
  base : UInt64,
  ranges : Int64,
) -> Array[(UInt64, UInt64)] raise {
  if ranges < 0L || ranges.to_int() > d.ranges.length() {
    raise DecodeError::new(
      "ranges",
      ranges.to_int().reinterpret_as_uint(),
      "invalid range offset \{ranges} (max \{d.ranges.length()})",
    )
  }
  let buf = make_buf(
    d,
    u,
    "ranges",
    ranges.to_int().reinterpret_as_uint(),
    d.ranges[ranges.to_int():],
  )
  let ret : Array[(UInt64, UInt64)] = []
  let mut current_base = base
  while buf.length() > 0 {
    let low = buf.addr()
    let high = buf.addr()
    if low == 0UL && high == 0UL {
      break
    }

    // Check for base address selection entry
    let mask = (1UL << (u.asize * 8)) - 1UL
    if low == mask {
      current_base = high
    } else {
      ret.push((current_base + low, current_base + high))
    }
  }
  ret
}

///|
/// DWARF 5 ranges parsing
fn Data::dwarf5_ranges(
  d : Data,
  u : Unit,
  cu : Entry?,
  base : UInt64,
  ranges : Int64,
) -> Array[(UInt64, UInt64)] raise {
  if ranges < 0L || ranges.to_int() > d.rng_lists.length() {
    raise DecodeError::new(
      "rnglists",
      ranges.to_int().reinterpret_as_uint(),
      "invalid rnglist offset \{ranges} (max \{d.rng_lists.length()})",
    )
  }
  let mut addr_base : Int64 = 0L
  match cu {
    Some(cu_entry) =>
      match cu_entry.val(AttrAddrBase) {
        Some(Int64(ab)) => addr_base = ab
        _ => ()
      }
    None => ()
  }
  let buf = make_buf(d, u, "rnglists", 0, d.rng_lists)
  buf.skip(ranges.to_int())
  let ret : Array[(UInt64, UInt64)] = []
  let mut current_base = base
  while true {
    let opcode = buf.uint8()
    match opcode {
      RleEndOfList => break
      RleBaseAddressx => {
        let base_idx = buf.uint()
        current_base = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          base_idx,
        )
      }
      RleStartxEndx => {
        let start_idx = buf.uint()
        let end_idx = buf.uint()
        let start = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          start_idx,
        )
        let end = d.debug_addr(u, addr_base.reinterpret_as_uint64(), end_idx)
        ret.push((start, end))
      }
      RleStartxLength => {
        let start_idx = buf.uint()
        let len = buf.uint()
        let start = d.debug_addr(
          u,
          addr_base.reinterpret_as_uint64(),
          start_idx,
        )
        ret.push((start, start + len))
      }
      RleOffsetPair => {
        let off1 = buf.uint()
        let off2 = buf.uint()
        ret.push((current_base + off1, current_base + off2))
      }
      RleBaseAddress => current_base = buf.addr()
      RleStartEnd => {
        let start = buf.addr()
        let end = buf.addr()
        ret.push((start, end))
      }
      RleStartLength => {
        let start = buf.addr()
        let len = buf.uint()
        ret.push((start, start + len))
      }
      _ => break // Unknown opcode
    }
  }
  ret
}

///|
/// debugAddr returns the address at idx in debug_addr
fn Data::debug_addr(
  d : Data,
  format : Unit,
  addr_base : UInt64,
  idx : UInt64,
) -> UInt64 raise {
  let off = idx * format.asize.to_uint64() + addr_base
  if off.to_int() < 0 {
    raise DecodeError::new("addr", 0, "offset out of range")
  }
  let b = make_buf(d, format, "addr", 0, d.addr)
  b.skip(off.to_int())
  let val = b.addr()
  match b.err {
    Some(err) => raise err
    None => val
  }
}
