#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
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
    fprintf(stderr, "usage: %s <fifo-path> <key-code> [extra-mods]\n", argv[0]);
    fprintf(stderr, "  extra-mods: comma-separated, any of: control,option,shift\n");
    return 1;
  }
  const char *fifo = argv[1];
  CGKeyCode kc = (CGKeyCode)atoi(argv[2]);

  CGEventFlags flags = kCGEventFlagMaskCommand;
  if (argc >= 4) {
    if (strstr(argv[3], "control")) flags |= kCGEventFlagMaskControl;
    if (strstr(argv[3], "option"))  flags |= kCGEventFlagMaskAlternate;
    if (strstr(argv[3], "shift"))   flags |= kCGEventFlagMaskShift;
  }

  signal(SIGPIPE, SIG_IGN);
  unlink(fifo);
  mkfifo(fifo, 0666);
  for (;;) {
    int fd = open(fifo, O_RDONLY);
    if (fd < 0)
      continue;
    char buf[64];
    while (read(fd, buf, sizeof(buf)) > 0) {
      send_key(kc, flags);
    }
    close(fd);
  }
  return 0;
}
