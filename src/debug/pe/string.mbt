/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// cstring converts ASCII byte sequence b to string.
/// It stops once it finds 0 or reaches end of b.
fn cstring(b : @slice.Slice[Byte]) -> String {
  let mut i = 0
  for j = 0; j < b.length(); j = j + 1 {
    if b[j] == (0 : Byte) {
      i = j
      break
    }
  } else {
    i = b.length()
  }
  let sb = StringBuilder::new()
  for k = 0; k < i; k = k + 1 {
    sb.write_char(Char::from_int(b[k].to_int()))
  }
  sb.to_string()
}

///|
/// StringTable is a COFF string table.
pub typealias StringTable = @slice.Slice[Byte]

///|
/// COFF symbol table entry size in bytes
pub const COFF_SYMBOL_SIZE : Int64 = 18

///|
fn read_string_table(fh : FileHeader, r : &@io.ReadSeeker) -> StringTable {
  // FIXME: Implement proper binary reading using the available packages
  // For now, return empty slice as placeholder
  ignore(fh)
  ignore(r)
  @slice.new()
}

///|
/// String extracts string from COFF string table st at offset start.
pub fn string_table_string(st : StringTable, start : Int64) -> String {
  // start includes 4 bytes of string table length
  if start < 4 {
    abort("offset \{start} is before the start of string table")
  }
  let start_adj = start - 4
  if start_adj.to_int() > st.length() {
    abort("offset \{start} is beyond the end of string table")
  }
  cstring(st[start_adj.to_int():])
}