/// Test for the DWARF package functionality
/// Basic smoke tests to ensure the package compiles and basic functionality works

///|
test "Data creation and basic operations" {
  // Test creating an empty Data structure
  let empty_slice : @slice.Slice[Byte] = @slice.new()

  // This should work even with empty data, testing the New function
  try {
    let data = new(
      empty_slice, // abbrev
      empty_slice, // aranges
      empty_slice, // frame
      [0x04U, 0x00U, 0x00U, 0x00U, 0x02U, 0x00U].as_bytes(), // info - minimal DWARF header
      empty_slice, // line
      empty_slice, // pubnames
      empty_slice, // ranges
      empty_slice, // str
    )
    @json.inspect(data.is_big_endian(), content=false)
    @json.inspect(data.order, content=LittleEndian)
  } catch {
    DecodeError(_, _, msg) => @json.inspect(msg, content="too short")
    _ => @json.inspect("unexpected error", content="too short")
  }
}

///|
test "Error types basic functionality" {
  try {
    raise ErrUnknownPC
  } catch {
    ErrUnknownPC =>
      @json.inspect(
        "caught ErrUnknownPC correctly",
        content="caught ErrUnknownPC correctly",
      )
    _ =>
      @json.inspect(
        "failed to catch ErrUnknownPC",
        content="caught ErrUnknownPC correctly",
      )
  }
}

///|
test "Basic type structures" {
  let common = CommonType::{ byte_size: 4L, name: "int" }
  let basic = BasicType::{
    common,
    bit_size: 32L,
    bit_offset: 0L,
    data_bit_offset: 0L,
  }
  let int_type = IntType(basic)
  @json.inspect(int_type.size(), content=4)
  @json.inspect(int_type.string(), content="int")
}

///|
test "Attribute and tag conversion" {
  let attr = AttrName
  let uint_val = attr.to_uint()
  @json.inspect(uint_val, content=3)
  match Attr::from_uint(3U) {
    Some(converted_attr) =>
      @json.inspect(converted_attr == AttrName, content=true)
    None => @json.inspect(false, content=true)
  }
}

///|
test "Entry and Field creation" {
  let entry = Entry::new(100U, TagBaseType, false)
  let field = Field::new(AttrName, String("test".as_bytes()), ClassString)
  @json.inspect(entry.tag, content=TagBaseType)
  @json.inspect(entry.children, content=false)
  @json.inspect(field.attr, content=AttrName)
  @json.inspect(field.class, content=ClassString)
}
