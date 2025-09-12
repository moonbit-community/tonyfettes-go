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

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_libc_fcntl(int32_t fd, int32_t cmd, int32_t arg) {
  int32_t r = fcntl(fd, cmd, arg);
  if (r == -1) {
    return -errno;
  }
  return r;
}
