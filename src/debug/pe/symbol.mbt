/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// COFFSymbol represents single COFF symbol table record.
pub(all) struct COFFSymbol {
  name : FixedArray[Byte] // [8]uint8
  value : Int64 // uint32 in Go
  section_number : Int // int16 in Go
  type_ : Int // uint16 in Go
  storage_class : Int // uint8 in Go
  number_of_aux_symbols : Int // uint8 in Go
} derive(Show, Eq, ToJson)

///|
/// readCOFFSymbols reads in the symbol table for a PE file, returning
/// a slice of COFFSymbol objects. The PE format includes both primary
/// symbols (whose fields are described by COFFSymbol above) and
/// auxiliary symbols; all symbols are 18 bytes in size. The auxiliary
/// symbols for a given primary symbol are placed following it in the
/// array, e.g.
///
///	...
///	k+0:  regular sym k
///	k+1:    1st aux symbol for k
///	k+2:    2nd aux symbol for k
///	k+3:  regular sym k+3
///	k+4:    1st aux symbol for k+3
///	k+5:  regular sym k+5
///	k+6:  regular sym k+6
///
/// The PE format allows for several possible aux symbol formats. For
/// more info see:
///
///	https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-symbol-records
///
/// At the moment this package only provides APIs for looking at
/// aux symbols of format 5 (associated with section definition symbols).
fn read_coff_symbols(fh : FileHeader, r : &@io.ReadSeeker) -> Array[COFFSymbol] {
  // FIXME: Implement proper COFF symbol reading
  // For now, return empty array as placeholder
  ignore(fh)
  ignore(r)
  []
}

///|
/// isSymNameOffset checks symbol name if it is encoded as offset into string table.
fn is_sym_name_offset(name : FixedArray[Byte]) -> (Bool, Int64) {
  if name[0] == (0 : Byte) &&
    name[1] == (0 : Byte) &&
    name[2] == (0 : Byte) &&
    name[3] == (0 : Byte) {
    // Extract 32-bit offset from last 4 bytes
    let offset = name[4].to_int().to_int64() |
      (name[5].to_int().to_int64() << 8) |
      (name[6].to_int().to_int64() << 16) |
      (name[7].to_int().to_int64() << 24)
    (true, offset)
  } else {
    (false, 0)
  }
}

///|
/// FullName finds real name of symbol sym. Normally name is stored
/// in sym.Name, but if it is longer then 8 characters, it is stored
/// in COFF string table st instead.
pub fn COFFSymbol::full_name(self : COFFSymbol, st : StringTable) -> String {
  let (ok, offset) = is_sym_name_offset(self.name)
  if ok {
    string_table_string(st, offset)
  } else {
    cstring(@slice.array(self.name))
  }
}

///|
fn remove_aux_symbols(
  allsyms : Array[COFFSymbol],
  st : StringTable,
) -> Array[Symbol] {
  if allsyms.length() == 0 {
    []
  } else {
    let syms : Array[Symbol] = []
    let mut aux = 0
    for sym in allsyms {
      if aux > 0 {
        aux = aux - 1
        continue
      }
      let name = sym.full_name(st)
      aux = sym.number_of_aux_symbols
      let s = Symbol::{
        name,
        value: sym.value,
        section_number: sym.section_number,
        type_: sym.type_,
        storage_class: sym.storage_class,
      }
      syms.push(s)
    }
    syms
  }
}

///|
/// Symbol is similar to [COFFSymbol] with Name field replaced
/// by Go string. Symbol also does not have NumberOfAuxSymbols.
pub(all) struct Symbol {
  name : String
  value : Int64 // uint32 in Go
  section_number : Int // int16 in Go
  type_ : Int // uint16 in Go
  storage_class : Int // uint8 in Go
} derive(Show, Eq, ToJson)

///|
/// COFFSymbolAuxFormat5 describes the expected form of an aux symbol
/// attached to a section definition symbol. The PE format defines a
/// number of different aux symbol formats: format 1 for function
/// definitions, format 2 for .be and .ef symbols, and so on. Format 5
/// holds extra info associated with a section definition, including
/// number of relocations + line numbers, as well as COMDAT info. See
/// https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-format-5-section-definitions
/// for more on what's going on here.
pub struct COFFSymbolAuxFormat5 {
  size : Int64 // uint32 in Go
  num_relocs : Int // uint16 in Go
  num_line_numbers : Int // uint16 in Go
  checksum : Int64 // uint32 in Go
  sec_num : Int // uint16 in Go
  selection : Int // uint8 in Go
} derive(Show, Eq, ToJson)

///|
/// These constants make up the possible values for the 'Selection'
/// field in an AuxFormat5.
pub const IMAGE_COMDAT_SELECT_NODUPLICATES : Int = 1

///|
pub const IMAGE_COMDAT_SELECT_ANY : Int = 2

///|
pub const IMAGE_COMDAT_SELECT_SAME_SIZE : Int = 3

///|
pub const IMAGE_COMDAT_SELECT_EXACT_MATCH : Int = 4

///|
pub const IMAGE_COMDAT_SELECT_ASSOCIATIVE : Int = 5

///|
pub const IMAGE_COMDAT_SELECT_LARGEST : Int = 6
