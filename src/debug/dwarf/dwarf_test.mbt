/// Test for the DWARF package functionality
/// Basic smoke tests to ensure the package compiles and basic functionality works

///|
test "new" {
  let data = new(
    abbrev=@slice.new(),
    aranges=@slice.new(),
    frame=@slice.new(),
    info=@slice.bytes([0x04, 0x00, 0x00, 0x00, 0x02, 0x00]),
    line=@slice.new(),
    pubnames=@slice.new(),
    ranges=@slice.new(),
    str=@slice.new(),
  )
  @json.inspect(data.is_big_endian(), content=false)
}
