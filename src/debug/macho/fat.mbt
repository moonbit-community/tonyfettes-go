// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

///|
/// A `FatFile` is a Mach-O universal binary that contains at least one architecture.
pub struct FatFile {
  magic : UInt
  arches : Array[FatArch]
  mut closer : &@io.Closer?
}

///|
/// A FatArchHeader represents a fat header for a specific image architecture.
pub struct FatArchHeader {
  cpu : Cpu
  sub_cpu : UInt
  offset : UInt
  size : UInt
  align : UInt
}

///|
pub impl @binary.Readable for FatArchHeader with read(
  r : &@io.Reader,
  order : @binary.ByteOrder,
) -> FatArchHeader {
  FatArchHeader::{
    cpu: Cpu::from_uint(@binary.read(r, order)),
    sub_cpu: @binary.read(r, order),
    offset: @binary.read(r, order),
    size: @binary.read(r, order),
    align: @binary.read(r, order),
  }
}

///|
/// A `FatArch` is a Mach-O File inside a FatFile.
pub struct FatArch {
  header : FatArchHeader
  file : File
}

///|
const FatArchHeaderSize : Int = 5 * 4

///|
pub let not_fat : FormatError = FormatError(0, "not a fat Mach-O file", None)

///|
/// `new_fat_file` creates a new [FatFile] for accessing all the Mach-O images in a
/// universal binary. The Mach-O binary is expected to start at position 0 in
/// the ReaderAt.
pub fn new_fat_file(r : &@io.ReaderAt) -> FatFile raise {
  let sr = @io.new_section_reader(r, 0, (1 << 63) - 1)
  let magic : UInt = @binary.read(sr, @binary.BigEndian) catch {
    _ => raise FormatError(0, "error reading magic number", None)
  }
  if magic != MagicFat {
    // See if this is a Mach-O file via its magic number. The magic
    // must be converted to little endian first though.
    let buf = @slice.make(4)
    @binary.BigEndian.put_uint32(buf, magic)
    let le_magic = @binary.LittleEndian.uint32(buf)
    if le_magic == Magic32 || le_magic == Magic64 {
      raise not_fat
    } else {
      raise FormatError(0, "invalid magic number", None)
    }
  }
  let mut offset = int64(4)

  // Read the number of FatArchHeaders that come after the fat_header.
  let narch : UInt = @binary.read(sr, BigEndian) catch {
    _ => raise FormatError(offset, "invalid fat_header", None)
  }
  offset += 4
  if narch < 1 {
    raise FormatError(offset, "file contains no images", None)
  }
  // Combine the Cpu and SubCpu (both uint32) into a uint64 to make sure
  // there are not duplicate architectures.
  let seen_arches : Set[UInt64] = Set::new()
  // Make sure that all images are for the same MH_ type.
  let mut macho_type = None
  let arches = []
  for i in 0U..<narch {
    let fah : FatArchHeader = @binary.read(sr, @binary.BigEndian) catch {
      _ => raise FormatError(offset, "invalid fat_arch header", None)
    }
    offset += int64(FatArchHeaderSize)
    let fr = @io.new_section_reader(r, int64(fah.offset), int64(fah.size))
    let faf : File = new_file(fr)

    // Make sure the architecture for this image is not duplicate.
    let seen_arch = uint64(fah.cpu) << 32
    if seen_arches.contains(seen_arch) {
      raise FormatError(
        offset,
        "duplicated architecture cpu=\{fah.cpu}, subcpu=\{fah.sub_cpu.to_string(radix=16)}",
        None,
      )
    }
    seen_arches.add(seen_arch)

    // Make sure the Mach-O type matches that of the first image.
    if macho_type is Some(macho_type) {
      if faf.header.type_ != macho_type {
        raise FormatError(
          offset,
          "Mach-O type for architecture #\{i} (type=\{faf.header.type_}) does not match first (type=\{macho_type})",
          None,
        )
      }
    } else {
      macho_type = Some(faf.header.type_)
    }
    arches.push(FatArch::{ header: fah, file: faf })
  }
  FatFile::{ magic, arches, closer: None }
}

///|
pub fn open_fat(name : String) -> FatFile raise {
  let f = @os.open(name)
  let ff = new_fat_file(f) catch {
    err => {
      f.close()
      raise err
    }
  }
  ff.closer = Some(f)
  return ff
}

///|
pub impl @io.Closer for FatFile with close(self : FatFile) -> Unit raise {
  if self.closer is Some(closer) {
    closer.close()
    self.closer = None
  }
}
