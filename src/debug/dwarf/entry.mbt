/// DWARF entry reading and parsing
/// Ported from Go's debug/dwarf package

///|
/// Parse a single DWARF entry from a buffer
pub fn parse_entry(
  buf : Buffer,
  cu : Entry?,
  unit : SimpleUnit,
  atable : AbbrevTable,
) -> Entry? {
  let off = buf.offset()
  let id = buf.uint().to_uint()
  if id == 0U {
    // Null entry (end of children)
    return Some(Entry::new(off, TagVariable, false)) // Use a dummy tag
  }
  match atable.get(id) {
    None =>
      // Unknown abbreviation - this is an error but we'll return None
      return None
    Some(abbrev) => {
      let entry = Entry::new(off, abbrev.tag(), abbrev.children())

      // Parse all fields according to the abbreviation
      for field_def in abbrev.fields() {
        match parse_field(buf, field_def, cu, unit) {
          Some(field) => {
            entry.add_field(field)
            ()
          }
          None => return None // Error parsing field
        }
      }
      Some(entry)
    }
  }
}

///|
/// Parse a single field from a buffer according to its definition
fn parse_field(
  buf : Buffer,
  field_def : AField,
  cu : Entry?,
  unit : SimpleUnit,
) -> Field? {
  let attr = field_def.attr()
  let format = field_def.format()
  let class = field_def.class()

  // Handle indirect format
  let actual_format = if format == FormIndirect {
    match uint_to_format(buf.uint().to_uint()) {
      Some(f) => f
      None => return None // Invalid format
    }
  } else {
    format
  }

  // Parse the value based on the format
  match parse_field_value(buf, actual_format, attr, unit) {
    Some(value) => Some(Field::new(attr, value, class))
    None => None
  }
}

///|
/// Parse a field value based on its format
fn parse_field_value(
  buf : Buffer,
  format : Format,
  attr : Attr,
  unit : SimpleUnit,
) -> FieldValue? {
  match format {
    // Address formats
    FormAddr => Some(VUInt64(buf.addr()))
    FormAddrx => Some(VUInt64(parse_addrx(buf, buf.uint(), unit)))
    FormAddrx1 => Some(VUInt64(parse_addrx(buf, buf.uint8().to_uint64(), unit)))
    FormAddrx2 =>
      Some(VUInt64(parse_addrx(buf, buf.uint16().to_uint64(), unit)))
    FormAddrx3 =>
      Some(VUInt64(parse_addrx(buf, buf.uint24().to_uint64(), unit)))
    FormAddrx4 =>
      Some(VUInt64(parse_addrx(buf, buf.uint32().to_uint64(), unit)))

    // Block formats
    FormDwarfBlock1 => Some(VBytes(buf.bytes(buf.uint8().to_int())))
    FormDwarfBlock2 => Some(VBytes(buf.bytes(buf.uint16().to_int())))
    FormDwarfBlock4 => Some(VBytes(buf.bytes(buf.uint32().to_int())))
    FormDwarfBlock => Some(VBytes(buf.bytes(buf.uint().to_int())))

    // Data formats
    FormData1 => Some(VInt64(buf.uint8().to_int64()))
    FormData2 => Some(VInt64(buf.uint16().to_int64()))
    FormData4 => Some(VInt64(buf.uint32().to_int64()))
    FormData8 => Some(VInt64(buf.uint64().reinterpret_as_int64()))
    FormData16 => Some(VBytes(buf.bytes(16)))
    FormSdata => Some(VInt64(buf.int()))
    FormUdata => Some(VInt64(buf.uint().reinterpret_as_int64()))
    FormImplicitConst =>
      // Value was stored in abbreviation table, need to get it from field_def
      // For now, return 0 - this would need the field_def passed through
      Some(VInt64(0L))

    // Flag formats
    FormFlag => Some(VBool(buf.uint8() == 1U))
    FormFlagPresent => Some(VBool(true)) // Presence implies true

    // Reference formats
    FormRefAddr => {
      let vers = unit.version()
      if vers == 2 {
        Some(VOffset(buf.addr().reinterpret_as_int64()))
        // DWARF 3+
      } else if unit.is_dwarf64() {
        Some(VOffset(buf.uint64().reinterpret_as_int64()))
      } else {
        Some(VOffset(buf.uint32().to_int64()))
      }
    }
    FormRef1 => Some(VOffset(buf.uint8().to_int64()))
    FormRef2 => Some(VOffset(buf.uint16().to_int64()))
    FormRef4 => Some(VOffset(buf.uint32().to_int64()))
    FormRef8 => Some(VOffset(buf.uint64().reinterpret_as_int64()))
    FormRefUdata => Some(VOffset(buf.uint().reinterpret_as_int64()))
    FormRefSig8 => Some(VUInt64(buf.uint64()))
    FormRefSup4 => Some(VUInt64(buf.uint32().to_uint64()))
    FormRefSup8 => Some(VUInt64(buf.uint64()))

    // String formats
    FormString => Some(VString(buf.string()))
    FormStrp => Some(VString(parse_strp(buf, unit)))
    FormLineStrp => Some(VString(parse_line_strp(buf, unit)))
    FormStrx => Some(VString(parse_strx(buf, buf.uint(), unit)))
    FormStrx1 => Some(VString(parse_strx(buf, buf.uint8().to_uint64(), unit)))
    FormStrx2 => Some(VString(parse_strx(buf, buf.uint16().to_uint64(), unit)))
    FormStrx3 => Some(VString(parse_strx(buf, buf.uint24().to_uint64(), unit)))
    FormStrx4 => Some(VString(parse_strx(buf, buf.uint32().to_uint64(), unit)))
    FormStrpSup => Some(VUInt64(buf.uint64())) // Offset into alternate string section

    // Section offset formats
    FormSecOffset =>
      if unit.is_dwarf64() {
        Some(VInt64(buf.uint64().reinterpret_as_int64()))
      } else {
        Some(VInt64(buf.uint32().to_int64()))
      }

    // Expression location
    FormExprloc => Some(VBytes(buf.bytes(buf.uint().to_int())))

    // List references
    FormLoclistx => Some(VUInt64(buf.uint()))
    FormRnglistx => Some(VUInt64(buf.uint()))

    // GNU extensions
    FormGnuRefAlt =>
      if unit.is_dwarf64() {
        Some(VInt64(buf.uint64().reinterpret_as_int64()))
      } else {
        Some(VInt64(buf.uint32().to_int64()))
      }
    FormGnuStrpAlt =>
      if unit.is_dwarf64() {
        Some(VUInt64(buf.uint64()))
      } else {
        Some(VUInt64(buf.uint32().to_uint64()))
      }

    // Unsupported or unknown formats
    _ => None
  }
}

///|
/// Parse address index (DWARF 5)
fn parse_addrx(buf : Buffer, index : UInt64, unit : SimpleUnit) -> UInt64 {
  // For now, just return the index as an address
  // Full implementation would look up in .debug_addr section
  index
}

///|
/// Parse string pointer from .debug_str section
fn parse_strp(buf : Buffer, unit : SimpleUnit) -> String {
  let offset = if unit.is_dwarf64() {
    buf.uint64()
  } else {
    buf.uint32().to_uint64()
  }

  // For now, return a placeholder
  // Full implementation would read from .debug_str at offset
  "strp_offset_\{offset}"
}

///|
/// Parse string pointer from .debug_line_str section
fn parse_line_strp(buf : Buffer, unit : SimpleUnit) -> String {
  let offset = if unit.is_dwarf64() {
    buf.uint64()
  } else {
    buf.uint32().to_uint64()
  }

  // For now, return a placeholder
  // Full implementation would read from .debug_line_str at offset
  "line_strp_offset_\{offset}"
}

///|
/// Parse string index (DWARF 5)
fn parse_strx(buf : Buffer, index : UInt64, unit : SimpleUnit) -> String {
  // For now, return a placeholder
  // Full implementation would resolve through .debug_str_offsets
  "strx_index_\{index}"
}

// uint_to_format is defined in abbrev.mbt

///|
/// Check if buffer has data remaining
pub fn Buffer::has_data(self : Buffer) -> Bool {
  self.length() > 0
}

///|
/// Peek at next entry ID without consuming it
pub fn Buffer::peek_entry_id(self : Buffer) -> UInt? {
  if self.length() < 1 {
    return None
  }

  // This is a simplified peek - real implementation would need
  // to handle variable-length integers properly
  Some(self.data[0].to_uint())
}
