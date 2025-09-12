#include <moonbit.h>
#include <stdatomic.h>
#include <stdint.h>

MOONBIT_FFI_EXPORT
uint64_t
moonbit_tonyfettes_go_sync_atomic_load_uint64(
  _Atomic(uint64_t) *array,
  int32_t index
) {
  return atomic_load(&array[index]);
}

MOONBIT_FFI_EXPORT
void
moonbit_tonyfettes_go_sync_atomic_make_uint64_array(
  int32_t size,
  uint64_t value
) {
  _Atomic(uint64_t) *array =
    (_Atomic(uint64_t) *)moonbit_make_int64_array_raw(size);
  for (int32_t i = 0; i < size; i++) {
    atomic_init(&array[i], 0);
  }
}
