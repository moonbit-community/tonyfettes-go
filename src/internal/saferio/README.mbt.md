# Internal SafeIO Package

Package saferio provides I/O functions that avoid allocating large amounts of
memory unnecessarily. This is intended for packages that read data from an
`io.Reader` where the size is part of the input data but the input may be
corrupt, or may be provided by an untrustworthy attacker.

## Functions

### read_data

`read_data` reads n bytes from the input stream, but avoids allocating all n
bytes if n is large. This avoids crashing the program by allocating all n bytes
in cases where n is incorrect.

```moonbit
test "read_data documentation example" {
  // This is a conceptual example - actual implementation would need a Reader
  let chunk_size = @saferio.Chunk
  @json.inspect(chunk_size, content=10485760)
}
```

### read_data_at

`read_data_at` reads n bytes from the input stream at a given offset, but avoids
allocating all n bytes if n is large.

```moonbit
test "read_data_at documentation example" {
  // This is a conceptual example - actual implementation would need a ReaderAt
  let chunk_size = @saferio.Chunk
  @json.inspect(chunk_size, content=10485760)
}
```

### slice_cap_with_size

`slice_cap_with_size` returns the capacity to use when allocating a slice. After
the slice is allocated with the capacity, it should be built using append. This
will avoid allocating too much memory if the capacity is large and incorrect.

```moonbit
test "slice_cap_with_size documentation example" {
  let cap = @saferio.slice_cap_with_size(1UL, 100UL)
  @json.inspect(cap, content=100)

  // Large allocations are limited to chunk size
  let large_cap = @saferio.slice_cap_with_size(1UL, 50000000UL)
  @json.inspect(large_cap, content=10485760)

  // Invalid sizes return -1
  let invalid_cap = @saferio.slice_cap_with_size(1UL, (1UL << 63))
  @json.inspect(invalid_cap, content=-1)
}
```

### slice_cap

`slice_cap` is like `slice_cap_with_size` but uses generics. Due to MoonBit
limitations with reflection, the size parameter must be passed explicitly.

```moonbit
test "slice_cap documentation example" {
  let cap = @saferio.slice_cap(100UL, 1UL)  // 100 elements of 1 byte each
  @json.inspect(cap, content=100)

  // Test with 8-byte elements (like Int64)
  let cap64 = @saferio.slice_cap(1000000UL, 8UL)
  @json.inspect(cap64, content=1000000)
}
```

## Constants

### Chunk

`Chunk` is an arbitrary limit on how much memory the functions are willing to
allocate without concern (10MB).

```moonbit
test "chunk constant example" {
  let chunk = @saferio.Chunk
  @json.inspect(chunk, content=10485760)  // 10 * 1024 * 1024
}
```