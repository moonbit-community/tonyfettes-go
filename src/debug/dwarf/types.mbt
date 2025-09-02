/// DWARF types and data structures
/// Ported from Go's debug/dwarf package

///|
/// Offset represents an offset within the DWARF info.
pub typealias Int64 as Offset

///|
/// A Class is the DWARF 4 class of an attribute value.
///
/// In general, a given attribute's value may take on one of several
/// possible classes defined by DWARF, each of which leads to a
/// slightly different interpretation of the attribute.
pub enum Class {
  ClassAddress
  ClassBlock
  ClassConstant
  ClassFlag
  ClassReference
  ClassReferenceSig
  ClassString
  ClassExprLoc
  ClassLinePtr
  ClassLocListPtr
  ClassMacPtr
  ClassRangeListPtr
  ClassUnknown
} derive(Show, Eq)

///|
/// A Field is a single attribute/value pair in an Entry.
pub struct Field {
  attr : Attr
  val : FieldValue
  class : Class
} derive(Show)

///|
/// FieldValue represents the possible values that can be stored in a DWARF field
pub enum FieldValue {
  VUInt64(UInt64) // address, constant values
  VBytes(Bytes) // block data, expression location
  VBool(Bool) // flag values
  VInt64(Int64) // signed constants, pointers
  VString(String) // string values
  VOffset(Offset) // references
} derive(Show)

///|
/// Create a new Field
pub fn Field::new(attr : Attr, val : FieldValue, class : Class) -> Field {
  { attr, val, class }
}

///|
/// Get the attribute
pub fn Field::attr(self : Field) -> Attr {
  self.attr
}

///|
/// Get the value
pub fn Field::val(self : Field) -> FieldValue {
  self.val
}

///|
/// Get the class
pub fn Field::class(self : Field) -> Class {
  self.class
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
/// Get the offset
pub fn Entry::offset(self : Entry) -> Offset {
  self.offset
}

///|
/// Get the tag
pub fn Entry::tag(self : Entry) -> Tag {
  self.tag
}

///|
/// Get whether this entry has children
pub fn Entry::children(self : Entry) -> Bool {
  self.children
}

///|
/// Get all fields
pub fn Entry::fields(self : Entry) -> Array[Field] {
  self.fields
}

///|
/// Add a field to the entry
pub fn Entry::add_field(self : Entry, field : Field) -> Unit {
  self.fields.push(field)
}

///|
/// Get the value associated with attribute attr in Entry,
/// or None if there is no such attribute.
pub fn Entry::val(self : Entry, attr : Attr) -> FieldValue? {
  match self.attr_field(attr) {
    Some(field) => Some(field.val)
    None => None
  }
}

///|
/// Get the Field associated with attribute attr in Entry,
/// or None if there is no such attribute.
pub fn Entry::attr_field(self : Entry, attr : Attr) -> Field? {
  for field in self.fields {
    if field.attr == attr {
      return Some(field)
    }
  }
  None
}
