#include <moonbit.h>

MOONBIT_FFI_EXPORT
void *
moonbit_tonyfettes_go_builtin_uintptr_from_uint64(uint64_t v) {
  return (void *)(uintptr_t)v;
}

MOONBIT_FFI_EXPORT
void *
moonbit_tonyfettes_go_builtin_uintptr_from_uint(uint32_t v) {
  return (void *)(uintptr_t)v;
}

MOONBIT_FFI_EXPORT
uint64_t
moonbit_tonyfettes_go_builtin_uintptr_to_uint64(void *p) {
  return (uint64_t)(uintptr_t)p;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_tonyfettes_go_builtin_uintptr_to_uint(void *p) {
  return (uint32_t)(uintptr_t)p;
}
