///|
/// This encoding algorithm, which prioritizes speed over output size, is
/// based on Snappy's LZ77-style encoder: github.com/golang/snappy

///|
/// Constants for fast deflate algorithm
/// Bits used in the table.
const TableBits : Int = 14

///|
/// Size of the table.
const TableSize : Int = 1 << TableBits

///|
/// Mask for table indices. Redundant, but can eliminate bounds checks.
const TableMask : Int = TableSize - 1

///|
/// Right-shift to get the tableBits most significant bits of a uint32.
const TableShift : Int = 32 - TableBits

///|
/// Reset the buffer offset when reaching this.
/// Offsets are stored between blocks as int32 values.
/// Since the offset we are checking against is at the beginning
/// of the buffer, we need to subtract the current and input
/// buffer to not risk overflowing the int32.
const BufferReset : Int = 2147483647 - MaxStoreBlockSize * 2 // math.MaxInt32 - maxStoreBlockSize*2

///|
/// Load 32 bits from byte array at given position
fn load32(b : ArrayView[Byte], i : Int) -> UInt {
  // Help the compiler eliminate bounds checks on the next line.
  let slice = Array::new()
  for idx = i; idx < i + 4 && idx < b.length(); idx = idx + 1 {
    slice.push(b[idx])
  }
  slice[0].to_uint() |
  (slice[1].to_uint() << 8) |
  (slice[2].to_uint() << 16) |
  (slice[3].to_uint() << 24)
}

///|
/// Load 64 bits from byte array at given position
fn load64(b : ArrayView[Byte], i : Int) -> UInt64 {
  // Help the compiler eliminate bounds checks on the next line.
  let slice = Array::new()
  for idx = i; idx < i + 8 && idx < b.length(); idx = idx + 1 {
    slice.push(b[idx])
  }
  slice[0].to_uint().to_uint64() |
  (slice[1].to_uint().to_uint64() << 8) |
  (slice[2].to_uint().to_uint64() << 16) |
  (slice[3].to_uint().to_uint64() << 24) |
  (slice[4].to_uint().to_uint64() << 32) |
  (slice[5].to_uint().to_uint64() << 40) |
  (slice[6].to_uint().to_uint64() << 48) |
  (slice[7].to_uint().to_uint64() << 56)
}

///|
/// Hash function for fast deflate
fn hash(u : UInt) -> UInt {
  (u * 0x1e35a7bd) >> TableShift
}

///|
/// These constants are defined by the Snappy implementation so that its
/// assembly implementation can fast-path some 16-bytes-at-a-time copies. They
/// aren't necessary in the pure Go implementation, as we don't use those same
/// optimizations, but using the same thresholds doesn't really hurt.
const InputMargin : Int = 16 - 1

///|
const MinNonLiteralBlockSize : Int = 1 + 1 + InputMargin

///|
/// Table entry for hash table
priv struct TableEntry {
  val : UInt // Value at destination
  offset : Int // Offset position
} derive(Show)

///|
/// deflateFast maintains the table for matches,
/// and the previous byte block for cross block matching.
priv struct DeflateFast {
  table : Array[TableEntry] // [tableSize]tableEntry
  mut prev : ArrayView[Byte] // Previous block, zero length if unknown.
  mut cur : Int // Current match offset.
} derive(Show)

///|
/// Create a new DeflateFast encoder
fn DeflateFast::new() -> DeflateFast {
  DeflateFast::{
    table: Array::make(TableSize, TableEntry::{ val: 0, offset: 0 }),
    prev: Array::make(MaxStoreBlockSize, (0 : Byte)),
    cur: MaxStoreBlockSize,
  }
}

///|
/// encode encodes a block given in src and appends tokens
/// to dst and returns the result.
fn DeflateFast::encode(
  self : DeflateFast,
  dst : Array[Token],
  src : ArrayView[Byte],
) -> Unit {
  // Ensure that e.cur doesn't wrap.
  if self.cur >= BufferReset {
    self.shift_offsets()
  }

  // This check isn't in the Snappy implementation, but there, the caller
  // instead of the callee handles this case.
  if src.length() < MinNonLiteralBlockSize {
    self.cur += MaxStoreBlockSize
    self.prev = self.prev[:0]
    return emit_literal(dst, src)
  }

  // sLimit is when to stop looking for offset/length copies. The inputMargin
  // lets us use a fast path for emitLiteral in the main loop, while we are
  // looking for copies.
  let s_limit = src.length() - InputMargin

  // next_emit is where in src the next emitLiteral should start from.
  let mut next_emit = 0
  let mut s = 0
  let mut cv = load32(src, s)
  let mut next_hash = hash(cv).reinterpret_as_int()
  while s <= s_limit {
    // Copied from the C++ snappy implementation:
    //
    // Heuristic match skipping: If 32 bytes are scanned with no matches
    // found, start looking only at every other byte. If 32 more bytes are
    // scanned (or skipped), look at every third byte, etc.. When a match
    // is found, immediately go back to looking at every byte. This is a
    // small loss (~5% performance, ~0.1% density) for compressible data
    // due to more bookkeeping, but for non-compressible data (such as
    // JPEG) it's a huge win since the compressor quickly "realizes" the
    // data is incompressible and doesn't bother looking for matches
    // everywhere.
    //
    // The "skip" variable keeps track of how many bytes there are since
    // the last match; dividing it by 32 (ie. right-shifting by five) gives
    // the number of bytes to move ahead for each iteration.
    let mut skip = 32
    let mut next_s = s
    let mut candidate = TableEntry::{ val: 0, offset: 0 }

    // Inner loop for finding matches
    let mut found_match = false
    while next_s <= s_limit && not(found_match) {
      s = next_s
      let bytesBetweenHashLookups = skip >> 5
      next_s = s + bytesBetweenHashLookups
      skip += bytesBetweenHashLookups
      if next_s > s_limit {
        break
      }
      candidate = self.table[next_hash & TableMask]
      let now = load32(src, next_s)
      self.table[next_hash & TableMask] = TableEntry::{
        offset: s + self.cur,
        val: cv,
      }
      next_hash = hash(now).reinterpret_as_int()
      let offset = s - (candidate.offset - self.cur)
      if offset <= MaxMatchOffset && cv == candidate.val {
        // Found a match
        found_match = true
      } else {
        // Out of range or not matched.
        cv = now
      }
    }
    if not(found_match) {
      // Exit to emit remainder
      if next_emit < src.length() {
        emit_literal(dst, src[next_emit:])
      }
      self.cur += src.length()
      self.prev = self.prev[:src.length()]
      ignore(copy(self.prev, src))
      return
    }

    // A 4-byte match has been found. We'll later see if more than 4 bytes
    // match. But, prior to the match, src[nextEmit:s] are unmatched. Emit
    // them as literal bytes.
    emit_literal(dst, src[next_emit:s])

    // Call emitCopy, and then see if another emitCopy could be our next
    // move. Repeat until we find no match for the input immediately after
    // what was consumed by the last emitCopy call.
    //
    // If we exit this loop normally then we need to call emitLiteral next,
    // though we don't yet know how big the literal will be. We handle that
    // by proceeding to the next iteration of the main loop. We also can
    // exit this loop via goto if we get close to exhausting the input.
    while true {
      // Invariant: we have a 4-byte match at s, and no need to emit any
      // literal bytes prior to s.

      // Extend the 4-byte match as long as possible.
      //
      s += 4
      let t = candidate.offset - self.cur + 4
      let l = self.match_len(s, t, src)

      // matchToken is flate's equivalent of Snappy's emitCopy. (length,offset)
      dst.push(
        match_token(
          (l + 4 - BaseMatchLength).reinterpret_as_uint(),
          (s - t - BaseMatchOffset).reinterpret_as_uint(),
        ),
      )
      s += l
      next_emit = s
      if s >= s_limit {
        // Exit to emit remainder
        if next_emit < src.length() {
          emit_literal(dst, src[next_emit:])
        }
        self.cur += src.length()
        self.prev = self.prev[:src.length()]
        ignore(copy(self.prev, src))
        return
      }

      // We could immediately start working at s now, but to improve
      // compression we first update the hash table at s-1 and at s. If
      // another emitCopy is not our next move, also calculate nextHash
      // at s+1. At least on GOARCH=amd64, these three hash calculations
      // are faster as one load64 call (with some shifts) instead of
      // three load32 calls.
      let x = load64(src, s - 1)
      let prevHash = hash(x.to_uint()).reinterpret_as_int()
      self.table[prevHash & TableMask] = TableEntry::{
        offset: self.cur + s - 1,
        val: x.to_uint(),
      }
      let x_shifted = x >> 8
      let currHash = hash(x_shifted.to_uint()).reinterpret_as_int()
      candidate = self.table[currHash & TableMask]
      self.table[currHash & TableMask] = TableEntry::{
        offset: self.cur + s,
        val: x_shifted.to_uint(),
      }
      let offset = s - (candidate.offset - self.cur)
      if offset > MaxMatchOffset || x_shifted.to_uint() != candidate.val {
        cv = (x_shifted >> 8).to_uint()
        next_hash = hash(cv).reinterpret_as_int()
        s += 1
        break
      }
    }
  }
  if next_emit < src.length() {
    emit_literal(dst, src[next_emit:])
  }
  self.cur += src.length()
  self.prev = self.prev[:src.length()]
  ignore(copy(self.prev, src))
}

///|
fn copy(dst : ArrayView[Byte], src : ArrayView[Byte]) -> Int {
  let len = @cmp.minimum(dst.length(), src.length())
  for i = 0; i < len; i = i + 1 {
    dst[i] = src[i]
  }
  len
}

///|
/// Emit literal tokens for the given byte slice
fn emit_literal(dst : Array[Token], lit : ArrayView[Byte]) -> Unit {
  for i = 0; i < lit.length(); i = i + 1 {
    dst.push(literal_token(lit[i].to_uint()))
  }
}

///|
/// matchLen returns the match length between src[s:] and src[t:].
/// t can be negative to indicate the match is starting in e.prev.
/// We assume that src[s-4:s] and src[t-4:t] already match.
fn DeflateFast::match_len(
  self : DeflateFast,
  s : Int,
  t : Int,
  src : ArrayView[Byte],
) -> Int {
  let mut s1 = s + MaxMatchLength - 4
  if s1 > src.length() {
    s1 = src.length()
  }

  // If we are inside the current block
  if t >= 0 {
    let b = Array::new() // src[t:]
    for i = t; i < src.length(); i = i + 1 {
      b.push(src[i])
    }
    let a = Array::new() // src[s:s1]
    for i = s; i < s1; i = i + 1 {
      a.push(src[i])
    }

    // Truncate b to length of a
    let min_len = if a.length() < b.length() { a.length() } else { b.length() }

    // Extend the match to be as long as possible.
    for i = 0; i < min_len; i = i + 1 {
      if a[i] != b[i] {
        return i
      }
    }
    return min_len
  }

  // We found a match in the previous block.
  let tp = self.prev.length() + t
  if tp < 0 {
    return 0
  }

  // Extend the match to be as long as possible.
  let mut a = src[s:s1]
  let mut b = self.prev[tp:]
  if b.length() > a.length() {
    b = b[:a.length()]
  }
  a = a[:b.length()]
  for i = 0; i < b.length(); i = i + 1 {
    if a[i] != b[i] {
      return i
    }
  }

  // If we reached our limit, we matched everything we are
  // allowed to in the previous block and we return.
  let n = b.length()
  if s + n == s1 {
    return n
  }

  // Continue looking for more matches in the current block.
  let a = src[s + n:s1]
  let b = src[:a.length()]
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return i + n
    }
  }
  return a.length() + n
}

///|
/// Reset resets the encoding history.
/// This ensures that no matches are made to the previous block.
fn DeflateFast::reset(self : DeflateFast) -> Unit {
  self.prev = self.prev[:0]
  // Bump the offset, so all matches will fail distance check.
  // Nothing should be >= e.cur in the table.
  self.cur += MaxMatchOffset

  // Protect against e.cur wraparound.
  if self.cur >= BufferReset {
    self.shift_offsets()
  }
}

///|
/// shiftOffsets will shift down all match offset.
/// This is only called in rare situations to prevent integer overflow.
///
/// See https://golang.org/issue/18636 and https://github.com/golang/go/issues/34121.
fn DeflateFast::shift_offsets(self : DeflateFast) -> Unit {
  if self.prev.length() == 0 {
    // We have no history; just clear the table.
    for i = 0; i < self.table.length(); i = i + 1 {
      self.table[i] = TableEntry::{ val: 0, offset: 0 }
    }
    self.cur = MaxMatchOffset + 1
    return
  }

  // Shift down everything in the table that isn't already too far away.
  for i = 0; i < self.table.length(); i = i + 1 {
    let v = self.table[i].offset - self.cur + MaxMatchOffset + 1
    let new_offset = if v < 0 {
      // We want to reset e.cur to maxMatchOffset + 1, so we need to shift
      // all table entries down by (e.cur - (maxMatchOffset + 1)).
      // Because we ignore matches > maxMatchOffset, we can cap
      // any negative offsets at 0.
      0
    } else {
      v
    }
    self.table[i] = TableEntry::{ val: self.table[i].val, offset: new_offset }
  }
  self.cur = MaxMatchOffset + 1
}
