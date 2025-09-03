// Copyright 2012 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Parse the type units stored in a DWARF4 .debug_types section. Each
// type unit defines a single primary type and an 8-byte signature.
// Other sections may then use formRefSig8 to refer to the type.

///|
/// The typeUnit format is a single type with a signature. It holds
/// the same data as a compilation unit.
priv struct TypeUnit {
  unit : Unit
  toff : Offset
  name : String
  mut cache : Type?
}

///|
impl Default for TypeUnit with default() -> TypeUnit {
  TypeUnit::{ unit: Unit::default(), toff: 0, name: "", cache: None }
}

///|
impl DataFormat for TypeUnit with version(self) {
  self.unit.version()
}

///|
impl DataFormat for TypeUnit with dwarf64(self) {
  self.unit.dwarf64()
}

///|
impl DataFormat for TypeUnit with addrsize(self) {
  self.unit.asize
}

///|
fn TypeUnit::data(tu : TypeUnit) -> @slice.Slice[Byte] {
  tu.unit.data
}

///|
fn Data::parse_types(
  d : Data,
  name : String,
  types : @slice.Slice[Byte],
) -> @unit.T raise {
  ...
}

///|
priv suberror NoTypeUnitWithSignature UInt64

///|
fn Data::sig_to_type(d : Data, sig : UInt64) -> Type raise {
  let tu = d.type_sigs.get(sig)
  guard tu is Some(tu) else { raise NoTypeUnitWithSignature(sig) }
  if tu.cache is Some(cache) {
    return cache
  }
  let b = make_buf(d, tu, tu.name, tu.toff, tu.data())
  let r = TypeUnitReader::{ d, tu, b, err: None }
  let t = d.read_type(tu.name, r, tu.toff, {}, None)
  tu.cache = Some(t)
  t
}

///|
priv struct TypeUnitReader {
  d : Data
  tu : TypeUnit
  mut b : Buf
  mut err : Error?
}

///|
impl TypeReader for TypeUnitReader with seek(tur : TypeUnitReader, off : Offset) {
  tur.err = None
  let doff = off - tur.tu.toff
  if doff < 0 || doff >= tur.tu.data().length().reinterpret_as_uint() {
    let err = Failure(
      "\{tur.tu.name}: offset \{doff} out of range; max \{tur.tu.data().length()}",
    )
    tur.err = Some(err)
    return
  }
  tur.b = make_buf(
    tur.d,
    tur.tu,
    tur.tu.name,
    off,
    tur.tu.data()[doff.reinterpret_as_int():],
  )
}

///|
impl TypeReader for TypeUnitReader with address_size(tur : TypeUnitReader) -> Int {
  tur.tu.unit.asize
}

///|
impl TypeReader for TypeUnitReader with next(tur : TypeUnitReader) -> Entry? {
  if tur.err is Some(err) {
    raise err
  }
  if tur.tu.data().length() == 0 {
    return None
  }
  let e = tur.b.entry(None, tur.tu.unit)
  if tur.b.err is Some(err) {
    tur.err = Some(err)
    raise err
  }
  return e
}

///|
impl TypeReader for TypeUnitReader with clone(tur : TypeUnitReader) -> TypeUnitReader {
  TypeUnitReader::{
    d: tur.d,
    tu: tur.tu,
    b: make_buf(tur.d, tur.tu, tur.tu.name, tur.b.off, tur.b.data),
    err: None,
  }
}

///|
impl TypeReader for TypeUnitReader with offset(tur : TypeUnitReader) -> Offset {
  return tur.tu.toff
}
