#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <unistd.h>
#include <signal.h>

#define KEY_Q 12
#define KEY_W 13
#define KEY_N 45

static int should_block(CGKeyCode kc, CGEventFlags flags) {
  if ((flags & kCGEventFlagMaskCommand) == 0) return 0;
  return kc == KEY_Q || kc == KEY_W || kc == KEY_N;
}

static CGEventRef tap_cb(CGEventTapProxy proxy, CGEventType type,
                          CGEventRef event, void *refcon) {
  (void)proxy;
  (void)refcon;
  if (type == kCGEventKeyDown) {
    CGKeyCode kc = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags flags = CGEventGetFlags(event);
    if (should_block(kc, flags)) {
      return NULL;
    }
  }
  return event;
}

int main(void) {
  signal(SIGPIPE, SIG_IGN);

  CFMachPortRef tap = CGEventTapCreate(
    kCGHIDEventTap, 0,
    kCGEventTapOptionDefault,
    CGEventMaskBit(kCGEventKeyDown),
    tap_cb, NULL);

  if (!tap) {
    fprintf(stderr, "need accessibility permissions\n");
    return 1;
  }

  CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(
    kCFAllocatorDefault, tap, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes);
  CFRelease(src);
  CFRelease(tap);
  CFRunLoopRun();
  return 0;
}
