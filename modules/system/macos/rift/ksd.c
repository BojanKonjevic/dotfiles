#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <fcntl.h>
#include <mach-o/dyld.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
static int alreadyPromptedFor(const char *exe) {
  char prev[1024] = {0};
  FILE *f = fopen("/tmp/ksd.prompted", "r");
  if (!f) {
    return 0;
  }
  size_t r = fread(prev, 1, sizeof(prev) - 1, f);
  (void)r;
  fclose(f);
  return strcmp(prev, exe) == 0;
}
static void markPromptedFor(const char *exe) {
  FILE *f = fopen("/tmp/ksd.prompted", "w");
  if (f) {
    fputs(exe, f);
    fclose(f);
  }
}
static void waitForTrust(void) {
  if (AXIsProcessTrusted()) {
    fprintf(stderr, "ksd: accessibility trusted\n");
    return;
  }
  char exe[1024] = {0};
  uint32_t size = sizeof(exe);
  if (_NSGetExecutablePath(exe, &size) != 0) {
    snprintf(exe, sizeof(exe), "unknown");
  }
  if (!alreadyPromptedFor(exe)) {
    fprintf(stderr, "ksd: not trusted, requesting approval\n");
    const void *keys[] = {kAXTrustedCheckOptionPrompt};
    const void *vals[] = {kCFBooleanTrue};
    CFDictionaryRef opts = CFDictionaryCreate(
        NULL, keys, vals, 1, &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    AXIsProcessTrustedWithOptions(opts);
    CFRelease(opts);
    markPromptedFor(exe);
  } else {
    fprintf(stderr, "ksd: not trusted (already prompted)\n");
  }
  int n = 0;
  while (!AXIsProcessTrusted() && n < 24) {
    if (n % 12 == 0) {
      fprintf(stderr, "ksd: waiting for Accessibility approval...\n");
    }
    sleep(5);
    n++;
  }
  if (!AXIsProcessTrusted()) {
    fprintf(stderr, "ksd: approval not yet visible, exiting for respawn\n");
    exit(1);
  }
  fprintf(stderr, "ksd: accessibility trusted\n");
}
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
  waitForTrust();
  unlink(fifo);
  mkfifo(fifo, 0666);
  for (;;) {
    int fd = open(fifo, O_RDONLY);
    if (fd < 0)
      continue;
    char buf[64];
    while (read(fd, buf, sizeof(buf)) > 0) {
      if (!AXIsProcessTrusted()) {
        fprintf(stderr, "ksd: trust lost, dropping key (re-approve in "
                        "Accessibility settings)\n");
        continue;
      }
      send_key(kc, flags);
    }
    close(fd);
  }
  return 0;
}
