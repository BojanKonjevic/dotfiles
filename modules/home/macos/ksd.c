#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>

static void send_key(CGKeyCode code, CGEventFlags flags) {
  CGEventRef d = CGEventCreateKeyboardEvent(NULL, code, true);
  CGEventSetFlags(d, flags);
  CGEventPost(kCGSessionEventTap, d);
  CFRelease(d);
  usleep(10000);
  CGEventRef u = CGEventCreateKeyboardEvent(NULL, code, false);
  CGEventPost(kCGSessionEventTap, u);
  CFRelease(u);
}

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: %s <fifo-path> <key-code>\n", argv[0]);
    return 1;
  }

  const char *fifo = argv[1];
  CGKeyCode kc = (CGKeyCode)atoi(argv[2]);

  signal(SIGPIPE, SIG_IGN);
  unlink(fifo);
  mkfifo(fifo, 0666);

  for (;;) {
    int fd = open(fifo, O_RDONLY);
    if (fd < 0) continue;
    char buf[64];
    while (read(fd, buf, sizeof(buf)) > 0) {
      send_key(kc, kCGEventFlagMaskCommand);
    }
    close(fd);
  }
  return 0;
}
