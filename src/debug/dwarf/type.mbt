///|
/// A Type conventionally represents a pointer to any of the
/// specific Type structures ([CharType], [StructType], etc.).
pub(all) enum Type {
  CommonType(mut byte_size~ : Int64, mut name~ : String, CommonType)
}

///|
pub fn Type::common_type(common_type : CommonType) -> Type {
  CommonType(byte_size=0, name="", common_type)
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
  QualType(qual~ : String, mut type_~ : Type)
  ArrayType(mut type_~ : Type, mut stride_bit_size~ : Int64, mut count~ : Int64)
  VoidType
  PtrType(mut type_~ : Type)
  StructType(
    struct_name~ : String,
    kind~ : String,
    fields~ : Array[StructField],
    incomplete~ : Bool
  )
  EnumType(enum_name~ : String, val~ : Array[EnumValue])
  FuncType(mut return_type~ : Type?, param_type~ : Array[Type])
  DotDotDotType
  TypedefType(mut type_~ : Type)
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
  mut name : String
  mut type_ : Type
  mut byte_offset : Int64
  mut byte_size : Int64
  mut bit_offset : Int64
  mut data_bit_offset : Int64
  mut bit_size : Int64
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
  clone(self : Self) -> Self raise
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
/// readType reads a type from r at off of name. It adds types to the
/// type cache, appends new typedef types to typedefs, and computes the
/// sizes of types. Callers should pass nil for typedefs; this is used
/// for internal recursion.
fn[TypeReader : TypeReader] Data::read_type(
  d : Data,
  name : String,
  r : TypeReader,
  off : Offset,
  type_cache : Map[Offset, Type],
  fixups : TypeFixer?,
) -> Type raise {
  match type_cache.get(off) {
    Some(t) => return t
    None => ()
  }
  r.seek(off)
  guard r.next() is Some(e) && e.offset != off else {
    raise DecodeError::new(name, off, "no type at offset")
  }
  let address_size = r.address_size()

  // If this is the root of the recursion, prepare to resolve
  // typedef sizes and perform other fixups once the recursion is
  // done. This must be done after the type graph is constructed
  // because it may need to resolve cycles in a different order than
  // readType encounters them.
  let mut fixup = fixups
  if fixup is None {
    let fixer = TypeFixer::{ typedefs: [], arraytypes: [] }
    defer fixer.apply()
    fixup = Some(fixer)
  }

  // Parse type from Entry.
  // Must always set typeCache[off] before calling
  // d.readType recursively, to handle circular types correctly.
  let mut next_depth = 0
  fn next() -> Entry? raise {
    if !e.children {
      return None
    }
    for {
      let kid = r.next()
      guard kid is Some(kid) else {
        raise DecodeError::new(name, off, "no child entry")
      }
      if kid.tag is Tag(0) {
        if next_depth > 0 {
          next_depth -= 1
          continue
        }
        return None
      }
      if kid.children {
        next_depth += 1
      }
      if next_depth > 0 {
        continue
      }
      return Some(kid)
    }
  }

  fn type_of(e : Entry) -> Type raise {
    match e.val(AttrType) {
      Some(Offset(toff)) =>
        d.read_type(name, r.clone(), toff, type_cache, fixup)
      Some(UInt64(toff)) => d.sig_to_type(toff)
      _ => Type::common_type(VoidType)
    }
  }

  let typ = match e.tag {
    TagArrayType => {
      // Multi-dimensional array.  (DWARF v2 §5.4)
      // Attributes:
      //	AttrType:subtype [required]
      //	AttrStrideSize: size in bits of each element of the array
      //	AttrByteSize: size of entire array
      // Children:
      //	TagSubrangeType or TagEnumerationType giving one dimension.
      //	dimensions are in left to right order.
      let t = CommonType(
        byte_size=0,
        name="",
        ArrayType(type_=Type::common_type(VoidType), stride_bit_size=0, count=0),
      )
      type_cache[off] = t
      guard t is CommonType(ArrayType(..) as at, ..)
      at.type_ = type_of(e)
      if e.val(AttrStrideSize) is Some(Int64(stride)) {
        at.stride_bit_size = stride
      }

      // Accumulate dimensions
      let dims : Array[Int64] = []
      let mut kid = next()
      while kid is Some(kid_entry) {
        // TODO(rsc): Can also be TagEnumerationType
        // but haven't seen that in the wild yet.
        match kid_entry.tag {
          TagSubrangeType => {
            let count = match kid_entry.val(AttrCount) {
              Some(Int64(count)) => count
              _ =>
                // Old binaries may have an upper bound instead.
                match kid_entry.val(AttrUpperBound) {
                  Some(Int64(ub)) => ub + 1L // Length is one more than upper bound.
                  _ => if dims.length() == 0 { -1L } else { 0L } // As in x[].
                }
            }
            dims.push(count)
          }
          TagEnumerationType =>
            raise DecodeError::new(
              name,
              kid_entry.offset,
              "cannot handle enumeration type as array bound",
            )
          _ => () // Skip other child types
        }
        kid = next()
      }
      if dims.length() == 0 {
        // LLVM generates this for x[].
        dims.push(-1L)
      }
      at.count = dims[0]
      for i = dims.length() - 1; i >= 1; i = i - 1 {
        at.type_ = CommonType(
          byte_size=0,
          name="",
          ArrayType(type_=at.type_, stride_bit_size=0, count=dims[i]),
        )
      }
      t
    }
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
        Some(String(name_bytes)) => name_bytes
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
        EncComplexFloat => {
          let t = basic_type(ComplexType)
          // clang writes out 'complex' instead of 'complex float' or 'complex double'.
          // clang also writes out a byte size that we can use to distinguish.
          // See issue 8694.
          if type_name == "complex" {
            guard t is (CommonType(BasicType(ComplexType, ..), ..) as ct)
            match e.val(AttrByteSize) {
              Some(Int64(8L)) => ct.name = "complex float"
              Some(Int64(16L)) => ct.name = "complex double"
              _ => ct.name = type_name
            }
          }
          t
        }
        EncFloat => basic_type(FloatType)
        EncSigned => basic_type(IntType)
        EncUnsigned => basic_type(UintType)
        EncSignedChar => basic_type(CharType)
        EncUnsignedChar => basic_type(UcharType)
        _ =>
          raise DecodeError::new(
            name,
            e.offset,
            "unrecognized encoding attribute value",
          )
      }
      guard typ is (CommonType(BasicType(_, ..) as t, ..) as c)
      c.name = type_name
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
    TagClassType | TagStructType | TagUnionType => {
      // Structure, union, or class type.  (DWARF v2 §5.5)
      // Attributes:
      //	AttrName: name of struct, union, or class
      //	AttrByteSize: byte size [required]
      //	AttrDeclaration: if true, struct/union/class is incomplete
      // Children:
      //	TagMember to describe one member.
      //		AttrName: name of member [required]
      //		AttrType: type of member [required]
      //		AttrByteSize: size in bytes
      //		AttrBitOffset: bit offset within bytes for bit fields
      //		AttrDataBitOffset: field bit offset relative to struct start
      //		AttrBitSize: bit size for bit fields
      //		AttrDataMemberLoc: location within struct [required for struct, class]
      // There is much more to handle C++, all ignored for now.
      let kind = match e.tag {
        TagClassType => "class"
        TagStructType => "struct"
        TagUnionType => "union"
        _ => "struct" // fallback
      }
      let struct_name = match e.val(AttrName) {
        Some(String(name)) => name
        _ => ""
      }
      let incomplete = e.val(AttrDeclaration) is Some(_)
      let fields : Array[StructField] = []
      let t = CommonType(
        byte_size=0,
        name="",
        StructType(struct_name~, kind~, fields~, incomplete~),
      )
      type_cache[off] = t
      let mut last_field_type : Type? = None
      let mut last_field_bit_size = 0L
      let mut last_field_byte_offset = 0L
      let mut kid = next()
      while kid is Some(kid_entry) {
        if kid_entry.tag != TagMember {
          kid = next()
          continue
        }
        let f = StructField::{
          name: "",
          type_: Type::common_type(VoidType),
          byte_offset: 0L,
          byte_size: 0L,
          bit_offset: 0L,
          data_bit_offset: 0L,
          bit_size: 0L,
        }
        f.type_ = type_of(kid_entry)
        match kid_entry.val(AttrDataMemberLoc) {
          Some(Bytes(loc)) => {
            // TODO: Should have original compilation
            // unit here, not unknownFormat.
            let b = make_buf(d, UnknownFormat::new(), "location", 0, loc)
            if b.uint8() != OpPlusUconst {
              raise DecodeError::new(
                name,
                kid_entry.offset,
                "unexpected opcode",
              )
            }
            f.byte_offset = b.uint().reinterpret_as_int64()
            match b.err {
              Some(err) => raise err
              None => ()
            }
          }
          Some(Int64(loc)) => f.byte_offset = loc
          _ => () // no location
        }
        f.name = match kid_entry.val(AttrName) {
          Some(String(n)) => n
          _ => ""
        }
        f.byte_size = match kid_entry.val(AttrByteSize) {
          Some(Int64(size)) => size
          _ => 0
        }
        let mut have_bit_offset = false
        let mut have_data_bit_offset = false
        if kid_entry.val(AttrBitOffset) is Some(Int64(bit_offset)) {
          have_bit_offset = true
          f.bit_offset = bit_offset
        }
        if kid_entry.val(AttrDataBitOffset) is Some(Int64(data_bit_offset)) {
          have_data_bit_offset = true
          f.data_bit_offset = data_bit_offset
        }
        if have_bit_offset && have_data_bit_offset {
          raise DecodeError::new(
            name,
            e.offset,
            "duplicate bit offset attributes",
          )
        }
        f.bit_size = match kid_entry.val(AttrBitSize) {
          Some(Int64(size)) => size
          _ => 0L
        }
        fields.push(f)
        if last_field_bit_size == 0L &&
          last_field_byte_offset == f.byte_offset &&
          kind != "union" {
          // Last field was zero width. Fix array length.
          // (DWARF writes out 0-length arrays as if they were 1-length arrays.)
          guard fixup is Some(fixup)
          fixup.record_array_type(last_field_type)
        }
        last_field_type = Some(f.type_)
        last_field_byte_offset = f.byte_offset
        last_field_bit_size = f.bit_size
        kid = next()
      }
      if kind != "union" {
        match e.val(AttrByteSize) {
          Some(Int64(b)) =>
            if b == last_field_byte_offset {
              // Final field must be zero width. Fix array length.
              guard fixup is Some(fixup)
              fixup.record_array_type(last_field_type)
            }
          _ => ()
        }
      }
      t
    }
    TagConstType | TagVolatileType | TagRestrictType => {
      // Type modifier (DWARF v2 §5.2)
      // Attributes:
      //	AttrType: subtype
      let qual = match e.tag {
        TagConstType => "const"
        TagRestrictType => "restrict"
        TagVolatileType => "volatile"
        _ => "" // fallback
      }
      let t = Type::common_type(QualType(qual~, type_=type_of(e)))
      type_cache[off] = t
      t
    }
    TagEnumerationType => {
      // Enumeration type (DWARF v2 §5.6)
      // Attributes:
      //	AttrName: enum name if any
      //	AttrByteSize: bytes required to represent largest value
      // Children:
      //	TagEnumerator:
      //		AttrName: name of constant
      //		AttrConstValue: value of constant
      let enum_name = match e.val(AttrName) {
        Some(String(name)) => name
        _ => ""
      }
      let val : Array[EnumValue] = []
      let t = CommonType(byte_size=0, name="", EnumType(enum_name~, val~))
      type_cache[off] = t
      let mut kid = next()
      while kid is Some(kid_entry) {
        if kid_entry.tag == TagEnumerator {
          let f = EnumValue::{
            name: match kid_entry.val(AttrName) {
              Some(String(n)) => n
              _ => ""
            },
            val: match kid_entry.val(AttrConstValue) {
              Some(Int64(v)) => v
              _ => 0L
            },
          }
          val.push(f)
        }
        kid = next()
      }
      t
    }
    TagPointerType => {
      // Type modifier (DWARF v2 §5.2)
      // Attributes:
      //	AttrType: subtype [not required!  void* has no AttrType]
      //	AttrAddrClass: address class [ignored]
      let t = CommonType(
        byte_size=0,
        name="",
        PtrType(type_=Type::common_type(VoidType)),
      )
      type_cache[off] = t
      type_cache[off] = t
      let new_type = if e.val(AttrType) is None {
        Type::common_type(VoidType)
      } else {
        type_of(e)
      }
      guard t is (CommonType(PtrType(..), ..) as ct)
      let updated_t = CommonType(
        byte_size=ct.byte_size,
        name=ct.name,
        PtrType(type_=new_type),
      )
      type_cache[off] = updated_t
      updated_t
    }
    TagSubroutineType => {
      // Subroutine type.  (DWARF v2 §5.7)
      // Attributes:
      //	AttrType: type of return value if any
      //	AttrName: possible name of type [ignored]
      //	AttrPrototyped: whether used ANSI C prototype [ignored]
      // Children:
      //	TagFormalParameter: typed parameter
      //		AttrType: type of parameter
      //	TagUnspecifiedParameter: final ...
      let param_type : Array[Type] = []
      let t = CommonType(
        byte_size=0,
        name="",
        FuncType(return_type=None, param_type~),
      )
      type_cache[off] = t
      guard t is (CommonType(FuncType(return_type=_, param_type~), ..) as ct)
      let new_return_type = Some(type_of(e))
      let updated_t = CommonType(
        byte_size=ct.byte_size,
        name=ct.name,
        FuncType(return_type=new_return_type, param_type~),
      )
      type_cache[off] = updated_t
      let mut kid = next()
      while kid is Some(kid_entry) {
        match kid_entry.tag {
          TagFormalParameter => {
            let tkid = type_of(kid_entry)
            param_type.push(tkid)
          }
          TagUnspecifiedParameters => {
            let tkid = CommonType(byte_size=0, name="", DotDotDotType)
            param_type.push(tkid)
          }
          _ => () // Skip other children
        }
        kid = next()
      }
      t
    }
    TagTypedef => {
      // Typedef (DWARF v2 §5.3)
      // Attributes:
      //	AttrName: name [required]
      //	AttrType: type definition [required]
      let t = CommonType(
        byte_size=0,
        name="",
        TypedefType(type_=Type::common_type(VoidType)),
      )
      type_cache[off] = t
      guard t is (CommonType(TypedefType(..), ..) as ct)
      let new_name = match e.val(AttrName) {
        Some(String(n)) => n
        _ => ""
      }
      let new_type = type_of(e)
      let updated_t = CommonType(
        byte_size=ct.byte_size,
        name=new_name,
        TypedefType(type_=new_type),
      )
      type_cache[off] = updated_t
      updated_t
    }
    TagUnspecifiedType => {
      // Unspecified type (DWARF v3 §5.2)
      // Attributes:
      //	AttrName: name
      let t = CommonType(
        byte_size=0,
        name="",
        BasicType(bit_size=0, bit_offset=0, data_bit_offset=0, UnspecifiedType),
      )
      type_cache[off] = t
      guard t is (CommonType(BasicType(UnspecifiedType, ..), ..) as ct)
      ct.name = match e.val(AttrName) {
        Some(String(n)) => n
        _ => ""
      }
      t
    }
    _ => {
      // This is some other type DIE that we're currently not
      // equipped to handle. Return an abstract "unsupported type"
      // object in such cases.
      let t = CommonType(byte_size=0, name="", UnsupportedType(tag=e.tag))
      type_cache[off] = t
      guard t is (CommonType(UnsupportedType(tag=_), ..) as ct)
      ct.name = match e.val(AttrName) {
        Some(String(n)) => n
        _ => ""
      }
      t
    }
  }

  // Set the byte size
  let b = match e.val(AttrByteSize) {
    Some(Int64(size)) => size
    _ => {
      let mut b = -1L
      match typ {
        CommonType(TypedefType(..), ..) => {
          // Record that we need to resolve this
          // type's size once the type graph is
          // constructed.
          guard fixup is Some(fixup)
          fixup.typedefs.push(typ)
        }
        CommonType(PtrType(..), ..) => b = address_size.to_int64()
        _ => ()
      }
      b
    }
  }
  guard typ is (CommonType(_, ..) as ct)
  ct.byte_size = b
  typ
}
