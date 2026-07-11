#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <signal.h>

#define IDLE_TIMEOUT 1.0

typedef int (*CGSDefaultConnectionFunc)(void);
typedef void (*CGSSetConnectionPropertyFunc)(int cid, int targetCID,
                                             CFStringRef key,
                                             CFBooleanRef value);

static CGDirectDisplayID displayID;
static dispatch_source_t hideTimer;
static BOOL hidden = NO;
static CFMachPortRef eventTap;

static void setup_cgs(void) {
  void *handle =
      dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
             RTLD_LAZY);
  if (!handle)
    return;
  CGSDefaultConnectionFunc getConn = dlsym(handle, "_CGSDefaultConnection");
  CGSSetConnectionPropertyFunc setProp =
      dlsym(handle, "CGSSetConnectionProperty");
  if (getConn && setProp) {
    int cid = getConn();
    setProp(cid, cid, CFSTR("SetsCursorInBackground"), kCFBooleanTrue);
  }
  dlclose(handle);
}

static void hideCursorNow(void) {
  if (!hidden) {
    CGDisplayHideCursor(displayID);
    hidden = YES;
  }
}

static void showCursorNow(void) {
  if (hidden) {
    CGDisplayShowCursor(displayID);
    hidden = NO;
  }
}

// (Re)schedule the hide to happen IDLE_TIMEOUT seconds from now.
static void resetHideTimer(void) {
  dispatch_source_set_timer(
      hideTimer,
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(IDLE_TIMEOUT * NSEC_PER_SEC)),
      DISPATCH_TIME_FOREVER /* one-shot */, 0);
}

static CGEventRef tapCallback(CGEventTapProxy proxy, CGEventType type,
                              CGEventRef event, void *refcon) {
  if (type == kCGEventTapDisabledByTimeout ||
      type == kCGEventTapDisabledByUserInput) {
    // Re-enable if the system disabled the tap (e.g. under load).
    CGEventTapEnable(eventTap, true);
    return event;
  }

  // Only actual cursor motion (move or drag) gets here, since that's
  // all we listen for. Any such event = "not idle" -> show + reset timer.
  dispatch_async(dispatch_get_main_queue(), ^{
    showCursorNow();
    resetHideTimer();
  });

  return event; // pass through untouched
}

@interface AppDel : NSObject <NSApplicationDelegate>
@end

@implementation AppDel
- (void)applicationDidFinishLaunching:(NSNotification *)note {
  displayID = CGMainDisplayID();
  setup_cgs();

  // Only cursor-motion event types. Explicitly NOT clicks, keys, or scroll.
  CGEventMask mask = CGEventMaskBit(kCGEventMouseMoved) |
                     CGEventMaskBit(kCGEventLeftMouseDragged) |
                     CGEventMaskBit(kCGEventRightMouseDragged) |
                     CGEventMaskBit(kCGEventOtherMouseDragged);

  eventTap =
      CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                       kCGEventTapOptionListenOnly, mask, tapCallback, NULL);
  if (!eventTap) {
    fprintf(stderr,
            "Failed to create event tap. Grant Accessibility/Input "
            "Monitoring permission to this binary in System Settings.\n");
    exit(1);
  }

  CFRunLoopSourceRef runLoopSource =
      CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
  CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
  CGEventTapEnable(eventTap, true);
  CFRelease(runLoopSource);

  hideTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                     dispatch_get_main_queue());
  dispatch_source_set_event_handler(hideTimer, ^{
    hideCursorNow();
  });
  dispatch_resume(hideTimer);
  resetHideTimer();
}
@end

int main(void) {
  signal(SIGPIPE, SIG_IGN);
  NSApplication *app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
  AppDel *del = [[AppDel alloc] init];
  [app setDelegate:del];
  [app run];
  return 0;
}
