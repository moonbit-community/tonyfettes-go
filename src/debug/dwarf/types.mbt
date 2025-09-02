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

///|
/// A CommonType holds fields common to multiple types.
/// If a field is not known or not applicable for a given type,
/// the zero value is used.
pub struct CommonType {
  byte_size : Int64 // size of value of this type, in bytes
  name : String // name that can be used to refer to type
} derive(Show)

///|
/// Create a new CommonType
pub fn CommonType::new(byte_size : Int64, name : String) -> CommonType {
  { byte_size, name }
}

///|
/// Get the byte size
pub fn CommonType::byte_size(self : CommonType) -> Int64 {
  self.byte_size
}

///|
/// Get the name
pub fn CommonType::name(self : CommonType) -> String {
  self.name
}

///|
/// Get the size (alias for byte_size)
pub fn CommonType::size(self : CommonType) -> Int64 {
  self.byte_size
}

///|
/// DwarfType represents any DWARF type.
/// This is the main trait that all DWARF types implement.
pub trait DwarfType {
  /// Get the common type information
  common(Self) -> CommonType

  /// Get the size of this type in bytes
  size(Self) -> Int64

  /// Convert to string representation
  to_string(Self) -> String
}

///|
/// A BasicType holds fields common to all basic types.
pub struct BasicType {
  common : CommonType
  bit_size : Int64
  bit_offset : Int64
  data_bit_offset : Int64
} derive(Show)

///|
/// Create a new BasicType
pub fn BasicType::new(
  common : CommonType,
  bit_size : Int64,
  bit_offset : Int64,
  data_bit_offset : Int64,
) -> BasicType {
  { common, bit_size, bit_offset, data_bit_offset }
}

///|
/// Get bit size
pub fn BasicType::bit_size(self : BasicType) -> Int64 {
  self.bit_size
}

///|
/// Get bit offset
pub fn BasicType::bit_offset(self : BasicType) -> Int64 {
  self.bit_offset
}

///|
/// Get data bit offset
pub fn BasicType::data_bit_offset(self : BasicType) -> Int64 {
  self.data_bit_offset
}

///|
impl DwarfType for BasicType with common(self) {
  self.common
}

///|
impl DwarfType for BasicType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for BasicType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    "?"
  }
}

///|
/// A QualType represents a type with DWARF qualifiers like const, volatile, etc.
pub struct QualType {
  common : CommonType
  qual : String
  qual_type : DwarfTypeRef?
} derive(Show)

///|
/// Reference to a DWARF type (to avoid circular dependencies)
pub enum DwarfTypeRef {
  BasicTypeRef(BasicType)
  QualTypeRef(QualType)
  ArrayTypeRef(ArrayType)
  VoidTypeRef(VoidType)
  PtrTypeRef(PtrType)
  StructTypeRef(StructType)
  UnionTypeRef(UnionType)
  EnumTypeRef(EnumType)
  FuncTypeRef(FuncType)
  TypedefTypeRef(TypedefType)
  UnsupportedTypeRef(UnsupportedType)
} derive(Show)

///|
/// Create a new QualType
pub fn QualType::new(
  common : CommonType,
  qual : String,
  qual_type : DwarfTypeRef?,
) -> QualType {
  { common, qual, qual_type }
}

///|
/// Get the qualifier
pub fn QualType::qual(self : QualType) -> String {
  self.qual
}

///|
/// Get the qualified type
pub fn QualType::qual_type(self : QualType) -> DwarfTypeRef? {
  self.qual_type
}

///|
impl DwarfType for QualType with common(self) {
  self.common
}

///|
impl DwarfType for QualType with size(self) {
  match self.qual_type {
    Some(qt) => dwarf_type_ref_size(qt)
    None => self.common.byte_size
  }
}

///|
impl DwarfType for QualType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    match self.qual_type {
      Some(qt) => "\{self.qual} \{dwarf_type_ref_to_string(qt)}"
      None => self.qual
    }
  }
}

///|
/// An ArrayType represents a fixed size array type.
pub struct ArrayType {
  common : CommonType
  array_type : DwarfTypeRef?
  stride_size : Int64
  count : Int64
} derive(Show)

///|
/// Create a new ArrayType
pub fn ArrayType::new(
  common : CommonType,
  array_type : DwarfTypeRef?,
  stride_size : Int64,
  count : Int64,
) -> ArrayType {
  { common, array_type, stride_size, count }
}

///|
/// Get the array element type
pub fn ArrayType::array_type(self : ArrayType) -> DwarfTypeRef? {
  self.array_type
}

///|
/// Get the stride size
pub fn ArrayType::stride_size(self : ArrayType) -> Int64 {
  self.stride_size
}

///|
/// Get the count
pub fn ArrayType::count(self : ArrayType) -> Int64 {
  self.count
}

///|
impl DwarfType for ArrayType with common(self) {
  self.common
}

///|
impl DwarfType for ArrayType with size(self) {
  if self.common.byte_size != 0L {
    self.common.byte_size
  } else {
    match self.array_type {
      Some(at) => dwarf_type_ref_size(at) * self.count
      None => 0L
    }
  }
}

///|
impl DwarfType for ArrayType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    match self.array_type {
      Some(at) => "[\{self.count}]\{dwarf_type_ref_to_string(at)}"
      None => "[]"
    }
  }
}

///|
/// A VoidType represents the C void type.
pub struct VoidType {
  common : CommonType
} derive(Show)

///|
/// Create a new VoidType
pub fn VoidType::new(common : CommonType) -> VoidType {
  { common, }
}

///|
impl DwarfType for VoidType with common(self) {
  self.common
}

///|
impl DwarfType for VoidType with size(_self) {
  0L
}

///|
impl DwarfType for VoidType with to_string(_self) {
  "void"
}

///|
/// A PtrType represents a pointer type.
pub struct PtrType {
  common : CommonType
  ptr_type : DwarfTypeRef?
} derive(Show)

///|
/// Create a new PtrType
pub fn PtrType::new(common : CommonType, ptr_type : DwarfTypeRef?) -> PtrType {
  { common, ptr_type }
}

///|
/// Get the pointed-to type
pub fn PtrType::ptr_type(self : PtrType) -> DwarfTypeRef? {
  self.ptr_type
}

///|
impl DwarfType for PtrType with common(self) {
  self.common
}

///|
impl DwarfType for PtrType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for PtrType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    match self.ptr_type {
      Some(pt) => "*\{dwarf_type_ref_to_string(pt)}"
      None => "*void"
    }
  }
}

///|
/// A StructField represents a field in a struct type.
pub struct StructField {
  name : String
  struct_type : DwarfTypeRef?
  byte_offset : Int64
  byte_size : Int64
  bit_offset : Int64
  data_bit_offset : Int64
  bit_size : Int64
} derive(Show)

///|
/// Create a new StructField
pub fn StructField::new(
  name : String,
  struct_type : DwarfTypeRef?,
  byte_offset : Int64,
) -> StructField {
  {
    name,
    struct_type,
    byte_offset,
    byte_size: 0L,
    bit_offset: 0L,
    data_bit_offset: 0L,
    bit_size: 0L,
  }
}

///|
/// Get the field name
pub fn StructField::name(self : StructField) -> String {
  self.name
}

///|
/// Get the field type
pub fn StructField::struct_type(self : StructField) -> DwarfTypeRef? {
  self.struct_type
}

///|
/// Get the byte offset
pub fn StructField::byte_offset(self : StructField) -> Int64 {
  self.byte_offset
}

///|
/// A StructType represents a struct, union, or C++ class type.
pub struct StructType {
  common : CommonType
  struct_name : String
  kind : String // "struct", "class", "union"
  fields : Array[StructField]
  incomplete : Bool
} derive(Show)

///|
/// Create a new StructType
pub fn StructType::new(
  common : CommonType,
  struct_name : String,
  kind : String,
  incomplete : Bool,
) -> StructType {
  { common, struct_name, kind, fields: [], incomplete }
}

///|
/// Get the struct name
pub fn StructType::struct_name(self : StructType) -> String {
  self.struct_name
}

///|
/// Get the kind (struct, class, union)
pub fn StructType::kind(self : StructType) -> String {
  self.kind
}

///|
/// Get the fields
pub fn StructType::fields(self : StructType) -> Array[StructField] {
  self.fields
}

///|
/// Check if incomplete
pub fn StructType::incomplete(self : StructType) -> Bool {
  self.incomplete
}

///|
/// Add a field
pub fn StructType::add_field(self : StructType, field : StructField) -> Unit {
  self.fields.push(field)
}

///|
impl DwarfType for StructType with common(self) {
  self.common
}

///|
impl DwarfType for StructType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for StructType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else if self.struct_name != "" {
    "\{self.kind} \{self.struct_name}"
  } else {
    self.kind
  }
}

///|
/// A UnionType represents a union type.
pub struct UnionType {
  common : CommonType
  union_name : String
  fields : Array[StructField]
} derive(Show)

///|
/// Create a new UnionType
pub fn UnionType::new(common : CommonType, union_name : String) -> UnionType {
  { common, union_name, fields: [] }
}

///|
/// Get the union name
pub fn UnionType::union_name(self : UnionType) -> String {
  self.union_name
}

///|
/// Get the fields
pub fn UnionType::fields(self : UnionType) -> Array[StructField] {
  self.fields
}

///|
/// Add a field
pub fn UnionType::add_field(self : UnionType, field : StructField) -> Unit {
  self.fields.push(field)
}

///|
impl DwarfType for UnionType with common(self) {
  self.common
}

///|
impl DwarfType for UnionType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for UnionType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else if self.union_name != "" {
    "union \{self.union_name}"
  } else {
    "union"
  }
}

///|
/// An EnumValue represents a single value in an enumeration.
pub struct EnumValue {
  name : String
  val : Int64
} derive(Show)

///|
/// Create a new EnumValue
pub fn EnumValue::new(name : String, val : Int64) -> EnumValue {
  { name, val }
}

///|
/// Get the name
pub fn EnumValue::name(self : EnumValue) -> String {
  self.name
}

///|
/// Get the value
pub fn EnumValue::val(self : EnumValue) -> Int64 {
  self.val
}

///|
/// An EnumType represents an enumerated type.
pub struct EnumType {
  common : CommonType
  enum_name : String
  vals : Array[EnumValue]
} derive(Show)

///|
/// Create a new EnumType
pub fn EnumType::new(common : CommonType, enum_name : String) -> EnumType {
  { common, enum_name, vals: [] }
}

///|
/// Get the enum name
pub fn EnumType::enum_name(self : EnumType) -> String {
  self.enum_name
}

///|
/// Get the values
pub fn EnumType::vals(self : EnumType) -> Array[EnumValue] {
  self.vals
}

///|
/// Add a value
pub fn EnumType::add_val(self : EnumType, val : EnumValue) -> Unit {
  self.vals.push(val)
}

///|
impl DwarfType for EnumType with common(self) {
  self.common
}

///|
impl DwarfType for EnumType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for EnumType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else if self.enum_name != "" {
    "enum \{self.enum_name}"
  } else {
    "enum"
  }
}

///|
/// A FuncType represents a function type.
pub struct FuncType {
  common : CommonType
  return_type : DwarfTypeRef?
  param_types : Array[DwarfTypeRef]
} derive(Show)

///|
/// Create a new FuncType
pub fn FuncType::new(
  common : CommonType,
  return_type : DwarfTypeRef?,
) -> FuncType {
  { common, return_type, param_types: [] }
}

///|
/// Get the return type
pub fn FuncType::return_type(self : FuncType) -> DwarfTypeRef? {
  self.return_type
}

///|
/// Get the parameter types
pub fn FuncType::param_types(self : FuncType) -> Array[DwarfTypeRef] {
  self.param_types
}

///|
/// Add a parameter type
pub fn FuncType::add_param_type(
  self : FuncType,
  param_type : DwarfTypeRef,
) -> Unit {
  self.param_types.push(param_type)
}

///|
impl DwarfType for FuncType with common(self) {
  self.common
}

///|
impl DwarfType for FuncType with size(_self) {
  0L
}

///|
impl DwarfType for FuncType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    let ret_str = match self.return_type {
      Some(rt) => dwarf_type_ref_to_string(rt)
      None => "void"
    }
    let param_strs : Array[String] = []
    for param_type in self.param_types {
      param_strs.push(dwarf_type_ref_to_string(param_type))
    }
    let param_str = param_strs.join(", ")
    "func(\{param_str}) \{ret_str}"
  }
}

///|
/// A TypedefType represents a named type.
pub struct TypedefType {
  common : CommonType
  typedef_type : DwarfTypeRef?
} derive(Show)

///|
/// Create a new TypedefType
pub fn TypedefType::new(
  common : CommonType,
  typedef_type : DwarfTypeRef?,
) -> TypedefType {
  { common, typedef_type }
}

///|
/// Get the typedef type
pub fn TypedefType::typedef_type(self : TypedefType) -> DwarfTypeRef? {
  self.typedef_type
}

///|
impl DwarfType for TypedefType with common(self) {
  self.common
}

///|
impl DwarfType for TypedefType with size(self) {
  match self.typedef_type {
    Some(tt) => dwarf_type_ref_size(tt)
    None => self.common.byte_size
  }
}

///|
impl DwarfType for TypedefType with to_string(self) {
  self.common.name
}

///|
/// An UnsupportedType is a placeholder returned when we encounter a type that
/// isn't supported.
pub struct UnsupportedType {
  common : CommonType
  tag : Tag
} derive(Show)

///|
/// Create a new UnsupportedType
pub fn UnsupportedType::new(common : CommonType, tag : Tag) -> UnsupportedType {
  { common, tag }
}

///|
/// Get the tag
pub fn UnsupportedType::tag(self : UnsupportedType) -> Tag {
  self.tag
}

///|
impl DwarfType for UnsupportedType with common(self) {
  self.common
}

///|
impl DwarfType for UnsupportedType with size(self) {
  self.common.byte_size
}

///|
impl DwarfType for UnsupportedType with to_string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    "unsupported type (tag \{self.tag})"
  }
}

// Helper functions for DwarfTypeRef

///|
/// Get the size of a DwarfTypeRef
pub fn dwarf_type_ref_size(type_ref : DwarfTypeRef) -> Int64 {
  match type_ref {
    BasicTypeRef(t) => DwarfType::size(t)
    QualTypeRef(t) => DwarfType::size(t)
    ArrayTypeRef(t) => DwarfType::size(t)
    VoidTypeRef(t) => DwarfType::size(t)
    PtrTypeRef(t) => DwarfType::size(t)
    StructTypeRef(t) => DwarfType::size(t)
    UnionTypeRef(t) => DwarfType::size(t)
    EnumTypeRef(t) => DwarfType::size(t)
    FuncTypeRef(t) => DwarfType::size(t)
    TypedefTypeRef(t) => DwarfType::size(t)
    UnsupportedTypeRef(t) => DwarfType::size(t)
  }
}

///|
/// Convert a DwarfTypeRef to string
pub fn dwarf_type_ref_to_string(type_ref : DwarfTypeRef) -> String {
  match type_ref {
    BasicTypeRef(t) => DwarfType::to_string(t)
    QualTypeRef(t) => DwarfType::to_string(t)
    ArrayTypeRef(t) => DwarfType::to_string(t)
    VoidTypeRef(t) => DwarfType::to_string(t)
    PtrTypeRef(t) => DwarfType::to_string(t)
    StructTypeRef(t) => DwarfType::to_string(t)
    UnionTypeRef(t) => DwarfType::to_string(t)
    EnumTypeRef(t) => DwarfType::to_string(t)
    FuncTypeRef(t) => DwarfType::to_string(t)
    TypedefTypeRef(t) => DwarfType::to_string(t)
    UnsupportedTypeRef(t) => DwarfType::to_string(t)
  }
}

///|
/// Get the common type of a DwarfTypeRef
pub fn dwarf_type_ref_common(type_ref : DwarfTypeRef) -> CommonType {
  match type_ref {
    BasicTypeRef(t) => DwarfType::common(t)
    QualTypeRef(t) => DwarfType::common(t)
    ArrayTypeRef(t) => DwarfType::common(t)
    VoidTypeRef(t) => DwarfType::common(t)
    PtrTypeRef(t) => DwarfType::common(t)
    StructTypeRef(t) => DwarfType::common(t)
    UnionTypeRef(t) => DwarfType::common(t)
    EnumTypeRef(t) => DwarfType::common(t)
    FuncTypeRef(t) => DwarfType::common(t)
    TypedefTypeRef(t) => DwarfType::common(t)
    UnsupportedTypeRef(t) => DwarfType::common(t)
  }
}
