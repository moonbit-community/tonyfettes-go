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
pub fn parse_abbrev(
  data : Data,
  off : UInt64,
  vers : Int,
) -> Result[AbbrevTable, String] {
  // Check cache first
  match data.get_abbrev_cache(off) {
    Some(table) => return Ok(table)
    None => () // continue
  }
  let abbrev_data = data.get_section(".debug_abbrev")
  let data_slice = if off > abbrev_data.length().to_uint64() {
    b""
  } else {
    let bytes_array : Array[Byte] = []
    for i = off.to_int(); i < abbrev_data.length(); i = i + 1 {
      bytes_array.push(abbrev_data[i])
    }
    Bytes::from_array(bytes_array)
  }
  let b = make_buf(
    Some(data),
    UnknownFormatRef(UnknownFormat::new()),
    "abbrev",
    0L,
    data_slice,
  )
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
  let _ = data.set_abbrev_cache(off, table)
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
