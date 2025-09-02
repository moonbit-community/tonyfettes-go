///|
/// A Type conventionally represents a pointer to any of the
/// specific Type structures ([CharType], [StructType], etc.).
pub(open) trait Type {
  common(Self) -> CommonType
  string(Self) -> String
  size(Self) -> Int64 = _
}

///|
/// A CommonType holds fields common to multiple types.
/// If a field is not known or not applicable for a given type,
/// the zero value is used.
pub(all) struct CommonType {
  byte_size : Int64 // size of value of this type, in bytes
  name : String // name that can be used to refer to type
} derive(Show)

///|
pub impl Type for CommonType with common(c : CommonType) -> CommonType {
  c
}

///|
impl Type with size(self : Self) -> Int64 {
  self.common().byte_size
}

///|
pub impl Type for CommonType with string(c : CommonType) -> String {
  if c.name != "" {
    c.name
  } else {
    "?"
  }
}

///|
/// Get the size (alias for byte_size)
pub impl Type for CommonType with size(c : CommonType) -> Int64 {
  c.byte_size
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
pub impl Type for BasicType with common(b : BasicType) -> CommonType {
  b.common
}

///|
pub impl Type for BasicType with size(b : BasicType) -> Int64 {
  b.common.byte_size
}

///|
pub impl Type for BasicType with string(b : BasicType) -> String {
  if b.common.name != "" {
    b.common.name
  } else {
    "?"
  }
}

///|
pub struct CharType(BasicType)

///|
pub struct UcharType(BasicType)

///|
pub struct IntType(BasicType)

///|
pub struct UintType(BasicType)

///|
pub struct FloatType(BasicType)

///|
pub struct ComplexType(BasicType)

///|
pub struct BoolType(BasicType)

///|
pub struct AddrType(BasicType)

///|
pub struct UnspecifiedType(BasicType)

///|
/// A QualType represents a type with DWARF qualifiers like const, volatile, etc.
pub struct QualType {
  common : CommonType
  qual : String
  type_ : &Type
}

///|
pub impl Type for QualType with common(q : QualType) -> CommonType {
  q.common
}

///|
pub impl Type for QualType with size(t : QualType) -> Int64 {
  t.type_.size()
}

///|
pub impl Type for QualType with string(t : QualType) -> String {
  "\{t.qual} \{t.type_.string()}"
}

///|
/// An ArrayType represents a fixed size array type.
pub(all) struct ArrayType {
  common : CommonType
  type_ : &Type
  stride_size : Int64
  count : Int64
}

///|
pub impl Type for ArrayType with common(self : ArrayType) -> CommonType {
  self.common
}

///|
pub impl Type for ArrayType with size(self : ArrayType) -> Int64 {
  if self.count == -1 {
    return 0
  }
  return self.count * self.type_.size()
}

///|
pub impl Type for ArrayType with string(self : ArrayType) -> String {
  "[\{self.count}]\{self.type_.string()}"
}

///|
/// A VoidType represents the C void type.
pub(all) struct VoidType(CommonType)

///|
pub impl Type for VoidType with common(self : VoidType) -> CommonType {
  self.0
}

///|
pub impl Type for VoidType with string(_ : VoidType) -> String {
  "void"
}

///|
/// A PtrType represents a pointer type.
pub(all) struct PtrType {
  common : CommonType
  type_ : &Type
}

///|
pub impl Type for PtrType with common(self : PtrType) -> CommonType {
  self.common
}

///|
pub impl Type for PtrType with string(self) {
  return "*\{self.type_.string()}"
}

///|
/// A StructType represents a struct, union, or C++ class type.
pub struct StructType {
  common : CommonType
  struct_name : String
  kind : String // "struct", "class", "union"
  fields : Array[StructField]
  incomplete : Bool // if true, struct, union, class is declared but not defined
}

///|
/// A StructField represents a field in a struct, union, or C++ class type.
///
/// # Bit Fields
///
/// The BitSize, BitOffset, and DataBitOffset fields describe the bit
/// size and offset of data members declared as bit fields in C/C++
/// struct/union/class types.
///
/// BitSize is the number of bits in the bit field.
///
/// DataBitOffset, if non-zero, is the number of bits from the start of
/// the enclosing entity (e.g. containing struct/class/union) to the
/// start of the bit field. This corresponds to the DW_AT_data_bit_offset
/// DWARF attribute that was introduced in DWARF 4.
///
/// BitOffset, if non-zero, is the number of bits between the most
/// significant bit of the storage unit holding the bit field to the
/// most significant bit of the bit field. Here "storage unit" is the
/// type name before the bit field (for a field "unsigned x:17", the
/// storage unit is "unsigned"). BitOffset values can vary depending on
/// the endianness of the system. BitOffset corresponds to the
/// DW_AT_bit_offset DWARF attribute that was deprecated in DWARF 4 and
/// removed in DWARF 5.
///
/// At most one of DataBitOffset and BitOffset will be non-zero;
/// DataBitOffset/BitOffset will only be non-zero if BitSize is
/// non-zero. Whether a C compiler uses one or the other
/// will depend on compiler vintage and command line options.
///
/// Here is an example of C/C++ bit field use, along with what to
/// expect in terms of DWARF bit offset info. Consider this code:
///
///	struct S {
///		int q;
///		int j:5;
///		int k:6;
///		int m:5;
///		int n:8;
///	} s;
///
/// For the code above, one would expect to see the following for
/// DW_AT_bit_offset values (using GCC 8):
///
///	       Little   |     Big
///	       Endian   |    Endian
///	                |
///	"j":     27     |     0
///	"k":     21     |     5
///	"m":     16     |     11
///	"n":     8      |     16
///
/// Note that in the above the offsets are purely with respect to the
/// containing storage unit for j/k/m/n -- these values won't vary based
/// on the size of prior data members in the containing struct.
///
/// If the compiler emits DW_AT_data_bit_offset, the expected values
/// would be:
///
///	"j":     32
///	"k":     37
///	"m":     43
///	"n":     48
///
/// Here the value 32 for "j" reflects the fact that the bit field is
/// preceded by other data members (recall that DW_AT_data_bit_offset
/// values are relative to the start of the containing struct). Hence
/// DW_AT_data_bit_offset values can be quite large for structs with
/// many fields.
///
/// DWARF also allow for the possibility of base types that have
/// non-zero bit size and bit offset, so this information is also
/// captured for base types, but it is worth noting that it is not
/// possible to trigger this behavior using mainstream languages.
pub(all) struct StructField {
  name : String
  type_ : &Type
  byte_offset : Int64
  byte_size : Int64
  bit_offset : Int64
  data_bit_offset : Int64
  bit_size : Int64
}

///|
pub impl Type for StructType with common(self : StructType) -> CommonType {
  self.common
}

///|
pub impl Type for StructType with string(self : StructType) -> String {
  if self.struct_name != "" {
    "\{self.kind} \{self.struct_name}"
  } else {
    self.kind
  }
}

///|
fn StructField::bit_offset(self : StructField) -> Int64 {
  if self.bit_offset != 0 {
    return self.bit_offset
  }
  return self.data_bit_offset
}

///|
pub fn StructType::defn(t : StructType) -> String {
  let sb = StringBuilder::new()
  sb.write_string(t.kind)
  if t.struct_name != "" {
    sb.write_string(" ")
    sb.write_string(t.struct_name)
  }
  if t.incomplete {
    sb.write_string(" /*incomplete*/")
    return sb.to_string()
  }
  sb.write_string(" {")
  for i, f in t.fields {
    if i > 0 {
      sb.write_string("; ")
    }
    sb.write_string(f.name)
    sb.write_char(' ')
    sb.write_string(f.type_.string())
    sb.write_char('@')
    sb.write_string(f.byte_offset.to_string())
    if f.bit_size > 0 {
      sb.write_string(" : ")
      sb.write_string(f.bit_size.to_string())
      sb.write_char('@')
      sb.write_string(f.bit_offset().to_string())
    }
  }
  sb.write_string("}")
  sb.to_string()
}

///|
/// An EnumType represents an enumerated type.
pub(all) struct EnumType {
  common : CommonType
  enum_name : String
  val : Array[EnumValue]
} derive(Show)

///|
/// An EnumValue represents a single value in an enumeration.
pub(all) struct EnumValue {
  name : String
  val : Int64
} derive(Show)

///|
pub impl Type for EnumType with common(self) {
  self.common
}

///|
pub impl Type for EnumType with string(self : EnumType) -> String {
  let sb = StringBuilder::new()
  sb.write_string("enum")
  if self.enum_name != "" {
    sb.write_string(" ")
    sb.write_string(self.enum_name)
  }
  sb.write_string(" {")
  for i, v in self.val {
    if i > 0 {
      sb.write_string("; ")
    }
    sb.write_string(v.name)
    sb.write_char('=')
    sb.write_string(v.val.to_string())
  }
  sb.write_char('}')
  sb.to_string()
}

///|
/// A FuncType represents a function type.
pub struct FuncType {
  common : CommonType
  return_type : &Type?
  param_type : Array[&Type]
}

///|
pub impl Type for FuncType with common(self : FuncType) -> CommonType {
  self.common
}

///|
pub impl Type for FuncType with string(t : FuncType) -> String {
  let sb = StringBuilder::new()
  sb.write_string("func(")
  for i, t in t.param_type {
    if i > 0 {
      sb.write_string(", ")
    }
    sb.write_string(t.string())
  }
  sb.write_string(")")
  if t.return_type is Some(return_type) {
    sb.write_char(' ')
    sb.write_string(return_type.string())
  }
  sb.to_string()
}

///|
/// A UnionType represents a union type.
pub struct UnionType {
  common : CommonType
  union_name : String
  fields : Array[StructField]
}

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
impl Type for UnionType with common(self) {
  self.common
}

///|
impl Type for UnionType with size(self) {
  self.common.byte_size
}

///|
impl Type for UnionType with string(self) {
  if self.common.name != "" {
    self.common.name
  } else if self.union_name != "" {
    "union \{self.union_name}"
  } else {
    "union"
  }
}

///|
/// A TypedefType represents a named type.
pub(all) struct TypedefType {
  common : CommonType
  type_ : &Type
}

///|
pub impl Type for TypedefType with common(t : TypedefType) -> CommonType {
  t.common
}

///|
pub impl Type for TypedefType with size(t : TypedefType) -> Int64 {
  t.type_.size()
}

///|
pub impl Type for TypedefType with string(t : TypedefType) -> String {
  t.common.name
}

///|
/// An UnsupportedType is a placeholder returned when we encounter a type that
/// isn't supported.
pub(all) struct UnsupportedType {
  common : CommonType
  tag : Tag
}

///|
pub impl Type for UnsupportedType with common(self : UnsupportedType) -> CommonType {
  self.common
}

///|
pub impl Type for UnsupportedType with string(self) {
  if self.common.name != "" {
    self.common.name
  } else {
    "(unsupported type \{self.tag})"
  }
}

///|
priv trait TypeReader {
  seek(self : Self, off : Offset) -> Unit
  next(self : Self) -> Entry raise
  clone(self : Self) -> Self
  offset(self : Self) -> Offset
  address_size(self : Self) -> Int
}

///|
pub fn Data::type_(d : Data, off : Offset) -> &Type raise {
  ...
}
