#include <errno.h>
#include <fcntl.h>
#include <moonbit.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_syscall_libc_open(
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
moonbit_tonyfettes_go_syscall_libc_fcntl(int32_t fd, int32_t cmd, int32_t arg) {
  int32_t r = fcntl(fd, cmd, arg);
  if (r == -1) {
    return -errno;
  }
  return r;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_syscall_libc_close(int32_t fd) {
  int32_t r = close(fd);
  if (r == -1) {
    return -errno;
  }
  return r;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_tonyfettes_go_syscall_libc_pread(
  int32_t fd,
  moonbit_bytes_t buf,
  uint32_t nbyte,
  int64_t offset
) {
  ssize_t r = pread(fd, buf, nbyte, offset);
  if (r == -1) {
    return -errno;
  }
  return (int32_t)r;
}
