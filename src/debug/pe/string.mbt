/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// cstring converts ASCII byte sequence b to string.
/// It stops once it finds 0 or reaches end of b.
fn cstring(b : @slice.Slice[Byte]) -> String raise {
  @encoding/utf8.decode(b.bytesview())
}

///|
/// StringTable is a COFF string table.
pub struct StringTable(@slice.Slice[Byte]) derive(Show, Eq, ToJson)

///|
pub impl @builtin.Len for StringTable with len(self : StringTable) -> Int {
  len(self.0)
}

///|
fn read_string_table(fh : FileHeader, r : &@io.ReadSeeker) -> StringTable raise {
  if fh.pointer_to_symbol_table <= 0 {
    return StringTable(@slice.make(0))
  }
  let offset = fh.pointer_to_symbol_table +
    COFF_SYMBOL_SIZE * fh.number_of_symbols
  let _ = r.seek(int64(offset), @io.SeekStart)
  let l : UInt = @binary.read(r, @binary.little_endian)
  if l <= 4 {
    return StringTable(@slice.make(0))
  }
  let l = l - 4
  let buf = @saferio.read_data(r, uint64(l))
  StringTable(buf)
}

///|
/// TODO(brainman): decide if start parameter should be int instead of uint32

///|
/// String extracts string from COFF string table st at offset start.
pub fn string_table_string(st : StringTable, start : Int64) -> String raise {
  // start includes 4 bytes of string table length
  if start < 4 {
    raise Failure("offset \{start} is before the start of string table")
  }
  let start = start - 4
  if start.to_int() > len(st) {
    raise Failure("offset \{start} is beyond the end of string table")
  }
  cstring(st.0[int(start):])
}
