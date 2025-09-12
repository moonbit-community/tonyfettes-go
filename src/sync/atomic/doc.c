#include <moonbit.h>
#include <stdatomic.h>
#include <stdint.h>

MOONBIT_FFI_EXPORT
uint32_t
moonbit_tonyfettes_go_sync_atomic_load_uint32(
  _Atomic(uint32_t) *array,
  int32_t index
) {
  return atomic_load(&array[index]);
}

MOONBIT_FFI_EXPORT
void
moonbit_tonyfettes_go_sync_atomic_store_uint32(
  _Atomic(uint32_t) *array,
  int32_t index,
  uint32_t value
) {
  atomic_store(&array[index], value);
}

MOONBIT_FFI_EXPORT
void
moonbit_tonyfettes_go_sync_atomic_make_uint_array(
  int32_t size,
  uint32_t value
) {
  _Atomic(uint32_t) *array =
    (_Atomic(uint32_t) *)moonbit_make_int32_array_raw(size);
  for (int32_t i = 0; i < size; i++) {
    atomic_init(&array[i], 0);
  }
}
