#include <moonbit.h>

MOONBIT_FFI_EXPORT
void *
moonbit_tonyfettes_go_builtin_uintptr_from_uint64(uint64_t v) {
  return (void *)(uintptr_t)v;
}

MOONBIT_FFI_EXPORT
void *
moonbit_tonyfettes_go_builtin_uintptr_from_int(int32_t v) {
  return (void *)(uintptr_t)v;
}

MOONBIT_FFI_EXPORT
uint64_t
moonbit_tonyfettes_go_builtin_uintptr_to_uint64(void *p) {
  return (uint64_t)(uintptr_t)p;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_builtin_uintptr_to_int(void *p) {
  return (int32_t)(uintptr_t)p;
}
