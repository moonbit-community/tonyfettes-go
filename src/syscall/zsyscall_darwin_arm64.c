#include <errno.h>
#include <fcntl.h>
#include <moonbit.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_libc_open(
  moonbit_bytes_t path,
  int32_t mode,
  uint32_t perm
) {
  int32_t fd = open((const char *)path, mode, perm);
  if (fd == -1) {
    return -errno;
  }
  return fd;
}
