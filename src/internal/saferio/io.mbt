///| Package saferio provides I/O functions that avoid allocating large
/// amounts of memory unnecessarily. This is intended for packages that
/// read data from an [@io.Reader] where the size is part of the input
/// data but the input may be corrupt, or may be provided by an
/// untrustworthy attacker.

///|
/// chunk is an arbitrary limit on how much memory we are willing
/// to allocate without concern.
pub const Chunk : Int = 10 * 1024 * 1024 // 10M

///|
/// read_data reads n bytes from the input stream, but avoids allocating
/// all n bytes if n is large. This avoids crashing the program by
/// allocating all n bytes in cases where n is incorrect.
///
/// The error is [@io.EOF] only if no bytes were read.
/// If an [@io.EOF] happens after reading some but not all the bytes,
/// read_data returns [@io.UnexpectedEof].
pub fn read_data(r : &@io.Reader, n : UInt64) -> Bytes raise {
  if n.reinterpret_as_int64() < 0L || n != n.to_int().to_uint64() {
    // n is too large to fit in int, so we can't allocate
    // a buffer large enough. Treat this as a read failure.
    raise @io.UnexpectedEof
  }

  if n.to_int() < Chunk {
    let buf : @slice.Slice[Byte] = @slice.make(n.to_int())
    @io.read_full(r, buf) |> ignore
    return buf.bytesview().to_bytes()
  }

  let buf : Array[Byte] = []
  let buf1 : @slice.Slice[Byte] = @slice.make(Chunk)
  let mut n = n
  while n > 0UL {
    let next = if n > Chunk.to_uint64() { Chunk } else { n.to_int() }
    @io.read_full(r, buf1[0:next]) |> ignore
    for i in 0..<next {
      buf.push(buf1[i])
    }
    n -= next.to_uint64()
  }
  // Convert Array[Byte] to Bytes
  Bytes::from_array(buf)
}

///|
/// read_data_at reads n bytes from the input stream at off, but avoids
/// allocating all n bytes if n is large. This avoids crashing the program
/// by allocating all n bytes in cases where n is incorrect.
pub fn read_data_at(r : &@io.ReaderAt, n : UInt64, off : Int64) -> Bytes raise {
  if n.reinterpret_as_int64() < 0L || n != n.to_int().to_uint64() {
    // n is too large to fit in int, so we can't allocate
    // a buffer large enough. Treat this as a read failure.
    raise @io.UnexpectedEof
  }

  if n.to_int() < Chunk {
    let buf : @slice.Slice[Byte] = @slice.make(n.to_int())
    r.read_at(buf, off) |> ignore
    // [@io.SectionReader] can return [@io.EOF] for n == 0,
    // but for our purposes that is a success.
    return buf.bytesview().to_bytes()
  }

  let buf : Array[Byte] = []
  let buf1 : @slice.Slice[Byte] = @slice.make(Chunk)
  let mut n = n
  let mut off = off
  while n > 0UL {
    let next = if n > Chunk.to_uint64() { Chunk } else { n.to_int() }
    r.read_at(buf1[0:next], off) |> ignore
    for i in 0..<next {
      buf.push(buf1[i])
    }
    n -= next.to_uint64()
    off += next.to_int64()
  }
  // Convert Array[Byte] to Bytes
  Bytes::from_array(buf)
}

///|
/// slice_cap_with_size returns the capacity to use when allocating a slice.
/// After the slice is allocated with the capacity, it should be
/// built using append. This will avoid allocating too much memory
/// if the capacity is large and incorrect.
///
/// A negative result means that the value is always too big.
pub fn slice_cap_with_size(size : UInt64, c : UInt64) -> Int {
  if c.reinterpret_as_int64() < 0L || c != c.to_int().to_uint64() {
    return -1
  }
  if size > 0UL && c > (18446744073709551615UL / size) {
    return -1
  }
  let mut c = c
  if c * size > Chunk.to_uint64() {
    c = Chunk.to_uint64() / size
    if c == 0UL {
      c = 1UL
    }
  }
  c.to_int()
}

///|
/// slice_cap is like slice_cap_with_size but using generics.
/// FIXME: MoonBit doesn't have reflection/unsafe.Sizeof equivalent.
/// For now, we use a size parameter that must be passed explicitly.
pub fn slice_cap(c : UInt64, size : UInt64) -> Int {
  slice_cap_with_size(size, c)
}
