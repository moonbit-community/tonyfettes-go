/// Copyright 2016 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

///|
/// COFF symbol table entry size in bytes
pub const COFF_SYMBOL_SIZE : UInt = 18

///|
/// COFFSymbol represents single COFF symbol table record.
pub(all) struct COFFSymbol {
  name : FixedArray[Byte] // [8]uint8
  value : UInt
  section_number : Int16
  type_ : UInt16
  storage_class : Byte
  number_of_aux_symbols : Byte
  aux_symbols : Array[COFFSymbolAuxFormat5]
} derive(Show, Eq, ToJson, Default)

///|
pub impl @binary.Readable for COFFSymbol with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> COFFSymbol raise {
  let name : FixedArray[Byte] = @binary.read_n(r, order, 8)
  let value : UInt = @binary.read(r, order)
  let section_number : Int16 = @binary.read(r, order)
  let type_ : UInt16 = @binary.read(r, order)
  let storage_class : Byte = @binary.read(r, order)
  let number_of_aux_symbols : Byte = @binary.read(r, order)
  let aux_symbols : Array[COFFSymbolAuxFormat5] = @binary.read_n(
    r,
    order,
    int(number_of_aux_symbols),
  )
  COFFSymbol::{
    name,
    value,
    section_number,
    type_,
    storage_class,
    number_of_aux_symbols,
    aux_symbols,
  }
}

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
fn read_coff_symbols(
  fh : FileHeader,
  r : &@io.ReadSeeker,
) -> Array[COFFSymbol] raise {
  if fh.pointer_to_symbol_table == 0 {
    return []
  }
  if fh.number_of_symbols <= 0 {
    return []
  }
  let _ = r.seek(int64(fh.pointer_to_symbol_table), @io.SeekStart) catch {
    err => fail("failed to seek to symbol table: \{err}")
  }
  let syms = []
  for k in 0U..<fh.number_of_symbols {
    let sym : COFFSymbol = @binary.read(r, @binary.little_endian) catch {
      err => fail("failed to read symbol table: \{err}")
    }
    syms.push(sym)
  }
  syms
}

///|
/// isSymNameOffset checks symbol name if it is encoded as offset into string table.
fn is_sym_name_offset(name : FixedArray[Byte]) -> (Bool, Int64) {
  if name[0] == (0 : Byte) &&
    name[1] == (0 : Byte) &&
    name[2] == (0 : Byte) &&
    name[3] == (0 : Byte) {
    // Extract 32-bit offset from last 4 bytes in little endian
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
pub fn COFFSymbol::full_name(
  self : COFFSymbol,
  st : StringTable,
) -> String raise {
  let (ok, offset) = is_sym_name_offset(self.name)
  if ok {
    string_table_string(st, offset)
  } else {
    cstring(@slice.fixedarray(self.name))
  }
}

///|
fn remove_aux_symbols(
  allsyms : Array[COFFSymbol],
  st : StringTable,
) -> Array[Symbol] raise {
  if allsyms.length() == 0 {
    []
  } else {
    let syms : Array[Symbol] = []
    let mut aux : Byte = 0
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
        type_: int16(sym.type_),
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
  value : UInt
  section_number : Int16
  type_ : Int16
  storage_class : Byte
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
  size : UInt
  num_relocs : UInt16
  num_line_numbers : UInt16
  checksum : UInt
  sec_num : UInt16
  selection : Byte
} derive(Show, Eq, ToJson, Default)

///|
pub impl @binary.Readable for COFFSymbolAuxFormat5 with read(
  r : &@io.Reader,
  order : &@binary.ByteOrder,
) -> COFFSymbolAuxFormat5 raise {
  let size : UInt = @binary.read(r, order)
  let num_relocs : UInt16 = @binary.read(r, order)
  let num_line_numbers : UInt16 = @binary.read(r, order)
  let checksum : UInt = @binary.read(r, order)
  let sec_num : UInt16 = @binary.read(r, order)
  let selection : Byte = @binary.read(r, order)
  COFFSymbolAuxFormat5::{
    size,
    num_relocs,
    num_line_numbers,
    checksum,
    sec_num,
    selection,
  }
}

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

///|
/// COFFSymbolReadSectionDefAux returns a blob of auxiliary information
/// (including COMDAT info) for a section definition symbol. Here 'idx'
/// is the index of a section symbol in the main [COFFSymbol] array for
/// the File. Return value is a pointer to the appropriate aux symbol
/// struct. For more info, see:
///
/// auxiliary symbols: https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-symbol-records
/// COMDAT sections: https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#comdat-sections-object-only
/// auxiliary info for section definitions: https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-format-5-section-definitions
pub fn File::coff_symbol_read_section_def_aux(
  self : File,
  idx : Int,
) -> COFFSymbolAuxFormat5 raise {
  if idx < 0 || idx >= self.coff_symbols.length() {
    raise Failure("invalid symbol index")
  }
  let pesym = self.coff_symbols[idx]
  let image_sym_class_static : Byte = 3
  if pesym.storage_class != image_sym_class_static {
    raise Failure("incorrect symbol storage class")
  }
  if pesym.number_of_aux_symbols == 0 || idx + 1 >= self.coff_symbols.length() {
    raise Failure("aux symbol unavailable")
  }
  // Locate and return the successor aux symbol as COFFSymbolAuxFormat5.
  let pesymn = self.coff_symbols[idx + 1]

  // Convert the aux symbol data to COFFSymbolAuxFormat5
  // The aux symbol is stored as a COFFSymbol but with different interpretation
  let size = pesymn.value
  let num_relocs = pesymn.section_number
  let num_line_numbers = pesymn.type_
  let checksum = pesymn.name[0].to_uint() |
    (pesymn.name[1].to_uint() << 8) |
    (pesymn.name[2].to_uint() << 16) |
    (pesymn.name[3].to_uint() << 24)
  let sec_num = pesymn.name[4].to_uint16() | (pesymn.name[5].to_uint16() << 8)
  let selection = pesymn.storage_class
  COFFSymbolAuxFormat5::{
    size,
    num_relocs: uint16(num_relocs),
    num_line_numbers,
    checksum,
    sec_num,
    selection,
  }
}
