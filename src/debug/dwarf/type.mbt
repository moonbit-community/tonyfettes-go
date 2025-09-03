///|
/// A Type conventionally represents a pointer to any of the
/// specific Type structures ([CharType], [StructType], etc.).
pub(all) enum Type {
  CommonType(mut byte_size~ : Int64, mut name~ : String, CommonType)
}

///|
pub fn Type::size(self : Type) -> Int64 {
  match self {
    CommonType(QualType(type_~, ..), ..) => type_.size()
    CommonType(ArrayType(..) as t, ..) => {
      if t.count == -1 {
        return 0
      }
      return t.count * t.type_.size()
    }
    CommonType(TypedefType(type_~), ..) => type_.size()
    CommonType(byte_size~, _, ..) => byte_size
  }
}

///|
pub impl Show for Type with output(self : Type, sb : &Logger) -> @unit.T {
  match self {
    CommonType(BasicType(_, ..), ..) as t => {
      if t.name != "" {
        sb.write_string(t.name)
        return
      }
      sb.write_char('?')
    }
    CommonType(QualType(qual~, type_~), ..) => {
      sb.write_string(qual)
      sb.write_char(' ')
      type_.output(sb)
    }
    CommonType(ArrayType(..) as t, ..) => {
      sb.write_char('[')
      t.count.output(sb)
      sb.write_char(']')
      t.type_.output(sb)
    }
    CommonType(VoidType, ..) => sb.write_string("void")
    CommonType(PtrType(type_~), ..) => {
      sb.write_char('*')
      type_.output(sb)
    }
    CommonType(StructType(struct_name~, kind~, fields~, incomplete~), ..) => {
      sb.write_string(kind)
      if struct_name != "" {
        sb.write_string(" ")
        sb.write_string(struct_name)
      }
      if incomplete {
        sb.write_string(" /*incomplete*/")
        return
      }
      sb.write_string(" {")
      for i, f in fields {
        if i > 0 {
          sb.write_string("; ")
        }
        sb.write_string(f.name)
        sb.write_char(' ')
        f.type_.output(sb)
        sb.write_char('@')
        f.byte_offset.output(sb)
        if f.bit_size > 0 {
          sb.write_string(" : ")
          f.bit_size.output(sb)
          sb.write_char('@')
          f.bit_offset().output(sb)
        }
      }
      sb.write_string("}")
    }
    CommonType(EnumType(enum_name~, val~), ..) => {
      sb.write_string("enum")
      if enum_name != "" {
        sb.write_string(" ")
        sb.write_string(enum_name)
      }
      sb.write_string(" {")
      for i, v in val {
        if i > 0 {
          sb.write_string("; ")
        }
        sb.write_string(v.name)
        sb.write_char('=')
        sb.write_string(v.val.to_string())
      }
      sb.write_char('}')
    }
    CommonType(FuncType(return_type~, param_type~), ..) => {
      sb.write_string("func(")
      for i, t in param_type {
        if i > 0 {
          sb.write_string(", ")
        }
        t.output(sb)
      }
      sb.write_string(")")
      if return_type is Some(return_type) {
        sb.write_char(' ')
        return_type.output(sb)
      }
    }
    CommonType(DotDotDotType, ..) => sb.write_string("...")
    CommonType(TypedefType(..), ..) as t => sb.write_string(t.name)
    CommonType(UnsupportedType(tag~), ..) =>
      sb.write_string("(unsupported type \{tag})")
  }
}

///|
/// A CommonType holds fields common to multiple types.
/// If a field is not known or not applicable for a given type,
/// the zero value is used.
pub(all) enum CommonType {
  BasicType(
    mut bit_size~ : Int64,
    mut bit_offset~ : Int64,
    mut data_bit_offset~ : Int64,
    BasicType
  )
  QualType(qual~ : String, type_~ : Type)
  ArrayType(type_~ : Type, stride_bit_size~ : Int64, count~ : Int64)
  VoidType
  PtrType(type_~ : Type)
  StructType(
    struct_name~ : String,
    kind~ : String,
    fields~ : Array[StructField],
    incomplete~ : Bool
  )
  EnumType(enum_name~ : String, val~ : Array[EnumValue])
  FuncType(return_type~ : Type?, param_type~ : Array[Type])
  DotDotDotType
  TypedefType(type_~ : Type)
  UnsupportedType(tag~ : Tag)
}

///|
pub(all) enum BasicType {
  CharType
  UcharType
  IntType
  UintType
  FloatType
  ComplexType
  BoolType
  AddrType
  UnspecifiedType
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
  type_ : Type
  byte_offset : Int64
  byte_size : Int64
  bit_offset : Int64
  data_bit_offset : Int64
  bit_size : Int64
}

///|
fn StructField::bit_offset(self : StructField) -> Int64 {
  if self.bit_offset != 0 {
    return self.bit_offset
  }
  return self.data_bit_offset
}

///|
/// An EnumType represents an enumerated type.
pub(all) struct EnumType {
  common : CommonType
  enum_name : String
  val : Array[EnumValue]
}

///|
/// An EnumValue represents a single value in an enumeration.
pub(all) struct EnumValue {
  name : String
  val : Int64
}

///|
/// typeReader is used to read from either the info section or the
/// types section.
priv trait TypeReader {
  seek(self : Self, off : Offset) -> @unit.T
  next(self : Self) -> Entry? raise
  clone(self : Self) -> Reader raise
  offset(self : Self) -> Offset
  /// AddressSize returns the size in bytes of addresses in the current
  /// compilation unit.
  address_size(self : Self) -> Int
}

///|
/// Type reads the type at off in the DWARF "info" section.
pub fn Data::type_(d : Data, off : Offset) -> Type raise {
  d.read_type("info", d.reader(), off, d.type_cache, None)
}

///|
priv struct TypeFixer {
  typedefs : Array[Type]
  arraytypes : Array[Type]
}

///|
fn TypeFixer::record_array_type(self : TypeFixer, t : Type?) -> @unit.T {
  guard t is Some(t) else { return }
  self.arraytypes.push(t)
}

///|
fn TypeFixer::apply(self : TypeFixer) -> @unit.T {
  for t in self.typedefs {
    guard t is (CommonType(TypedefType(type_~), ..) as t)
    t.byte_size = type_.size()
  }
  for i, t in self.arraytypes {
    guard t is (CommonType(ArrayType(..) as t, ..) as c)
    // Zero out array if element size is 0
    if t.type_.size() == 0L {
      continue
    }
    let tt = CommonType(
      byte_size=c.byte_size,
      name=c.name,
      ArrayType(type_=t.type_, stride_bit_size=t.stride_bit_size, count=0),
    )
    self.arraytypes[i] = tt
  }
}

///|
/// Helper function to convert byte slice to string safely
fn slice_to_string(bytes : @slice.Slice[Byte]) -> String {
  let sb = StringBuilder::new()
  for i = 0; i < bytes.length(); i = i + 1 {
    sb.write_char(bytes[i].to_char())
  }
  sb.to_string()
}

///|
/// readType reads a type from r at off of name. It adds types to the
/// type cache, appends new typedef types to typedefs, and computes the
/// sizes of types. Callers should pass nil for typedefs; this is used
/// for internal recursion.
fn Data::read_type(
  d : Data,
  name : String,
  r : Reader,
  off : Offset,
  type_cache : Map[Offset, Type],
  fixups : TypeFixer?,
) -> Type raise {
  match type_cache.get(off) {
    Some(t) => return t
    None => ()
  }
  r.seek(off)
  match r.next() {
    Some(e) => {
      let address_size = r.address_size()
      if e.offset != off {
        raise DecodeError::new(name, off, "no type at offset")
      }

      // If this is the root of the recursion, prepare to resolve
      // typedef sizes and perform other fixups once the recursion is
      // done. This must be done after the type graph is constructed
      // because it may need to resolve cycles in a different order than
      // readType encounters them.
      let mut actual_fixups = fixups
      if actual_fixups is None {
        actual_fixups = Some(TypeFixer::{ typedefs: [], arraytypes: [] })
      }

      // Parse type from Entry.
      // Must always set typeCache[off] before calling
      // d.readType recursively, to handle circular types correctly.
      let typ = d.parse_type_from_entry(
        e,
        r,
        name,
        type_cache,
        actual_fixups.unwrap(),
        address_size,
      )
      match fixups {
        None =>
          match actual_fixups {
            Some(fixer) => fixer.apply()
            None => ()
          }
        Some(_) => ()
      }
      typ
    }
    None => raise DecodeError::new(name, off, "no entry at offset")
  }
}

///|
/// Parse a specific type from a DWARF entry
fn Data::parse_type_from_entry(
  d : Data,
  e : Entry,
  r : Reader,
  name : String,
  type_cache : Map[Offset, Type],
  fixups : TypeFixer,
  address_size : Int,
) -> Type raise {
  // This is a simplified implementation focusing on the most common types
  // A full implementation would handle all DWARF type tags

  match e.tag {
    TagBaseType => {
      // Basic type.  (DWARF v2 §5.1)
      // Attributes:
      //	AttrName: name of base type in programming language of the compilation unit [required]
      //	AttrEncoding: encoding value for type (encFloat etc) [required]
      //	AttrByteSize: size of type in bytes [required]
      //	AttrBitOffset: bit offset of value within containing storage unit
      //	AttrDataBitOffset: bit offset of value within containing storage unit
      //	AttrBitSize: size in bits
      //
      // For most languages BitOffset/DataBitOffset/BitSize will not be present
      // for base types.
      let type_name = match e.val(AttrName) {
        Some(String(name_bytes)) => slice_to_string(name_bytes)
        _ => ""
      }
      guard e.val(AttrEncoding) is Some(Int64(enc)) else {
        raise DecodeError::new(
          name,
          e.offset,
          "missing encoding attribute for \{type_name}",
        )
      }
      fn basic_type(t : BasicType) -> Type {
        CommonType(
          byte_size=0,
          name="",
          BasicType(bit_size=0, bit_offset=0, data_bit_offset=0, t),
        )
      }

      let typ = match enc {
        EncAddress => basic_type(AddrType)
        EncBoolean => basic_type(BoolType)
        EncComplexFloat => basic_type(ComplexType)
        EncFloat => basic_type(FloatType)
        EncSigned => basic_type(IntType)
        EncUnsigned => basic_type(CharType)
        EncSignedChar => basic_type(UintType)
        EncUnsignedChar => basic_type(UcharType)
        _ =>
          raise DecodeError::new(
            name,
            e.offset,
            "unsupported base type encoding \{enc} for \{type_name}",
          )
      }
      guard typ is (CommonType(BasicType(_, ..) as t, ..) as c)
      c.name = name
      if e.val(AttrBitSize) is Some(Int64(bit_size)) {
        t.bit_size = bit_size
      }
      let mut have_bit_offset = false
      let mut have_data_bit_offset = false
      if e.val(AttrBitOffset) is Some(Int64(bit_offset)) {
        have_bit_offset = true
        t.bit_offset = bit_offset
      }
      if e.val(AttrDataBitOffset) is Some(Int64(data_bit_offset)) {
        have_data_bit_offset = true
        t.data_bit_offset = data_bit_offset
      }
      type_cache[e.offset] = typ
      if have_bit_offset && have_data_bit_offset {
        raise DecodeError::new(
          name,
          e.offset,
          "duplicate bit offset attributes",
        )
      }
      typ
    }
  }
}
