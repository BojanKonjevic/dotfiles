#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <signal.h>
#include <stdio.h>
#include <time.h>

#define IDLE_TIMEOUT 3.0
#define REHIDE_INTERVAL 0.5 // while idle, keep re-asserting hide this often

typedef int (*CGSDefaultConnectionFunc)(void);
typedef void (*CGSSetConnectionPropertyFunc)(int cid, int targetCID,
                                             CFStringRef key,
                                             CFBooleanRef value);

static dispatch_source_t hideTimer;
static dispatch_source_t rehideTimer;
static int hideDepth = 0;
static BOOL idle = NO;
static CFMachPortRef eventTap;

static void logmsg(const char *fmt, ...) {
  time_t t = time(NULL);
  struct tm tmv;
  localtime_r(&t, &tmv);
  char buf[32];
  strftime(buf, sizeof(buf), "%H:%M:%S", &tmv);
  fprintf(stderr, "[%s] ", buf);
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\n");
  fflush(stderr);
}

static void setup_cgs(void) {
  void *handle =
      dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
             RTLD_LAZY);
  if (!handle) {
    logmsg("setup_cgs: dlopen failed");
    return;
  }
  CGSDefaultConnectionFunc getConn = dlsym(handle, "_CGSDefaultConnection");
  CGSSetConnectionPropertyFunc setProp =
      dlsym(handle, "CGSSetConnectionProperty");
  if (getConn && setProp) {
    int cid = getConn();
    setProp(cid, cid, CFSTR("SetsCursorInBackground"), kCFBooleanTrue);
    logmsg("setup_cgs: SetsCursorInBackground set on cid=%d", cid);
  } else {
    logmsg("setup_cgs: symbols not found");
  }
  dlclose(handle);
}

static void hideCursorNow(void) {
  // CGDisplayHideCursor/ShowCursor maintain an internal *counter*, and
  // something outside this process (app/space switches, etc.) can also
  // nudge that counter independently of us. So we deliberately keep
  // calling hide repeatedly while idle (see rehideTimer) to fight any
  // external resets, and track how many hide calls we've personally
  // issued in hideDepth so show can fully undo exactly that many later
  // — instead of assuming a single show call is enough.
  CGError err = CGDisplayHideCursor(kCGNullDirectDisplay);
  hideDepth++;
  if (hideDepth == 1) {
    logmsg("hideCursorNow: hiding (err=%d)", err);
  }
}

static void showCursorNow(void) {
  if (hideDepth > 0) {
    logmsg("showCursorNow: draining %d hide(s)", hideDepth);
    while (hideDepth > 0) {
      CGDisplayShowCursor(kCGNullDirectDisplay);
      hideDepth--;
    }
  }
}

static void enterIdle(void) {
  idle = YES;
  hideCursorNow();
}

static void exitIdle(void) {
  idle = NO;
  showCursorNow();
}

// (Re)schedule entering idle to happen IDLE_TIMEOUT seconds from now.
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
    logmsg("tap disabled, re-enabling");
    CGEventTapEnable(eventTap, true);
    return event;
  }

  int64_t dx = CGEventGetIntegerValueField(event, kCGMouseEventDeltaX);
  int64_t dy = CGEventGetIntegerValueField(event, kCGMouseEventDeltaY);
  if (type == kCGEventMouseMoved) {
    logmsg("raw move dx=%lld dy=%lld", dx, dy);
  }

  // NOTE: previously filtered on nonzero deltaX/deltaY to try to ignore
  // synthetic warp-driven moves, but trackpad-generated moves report
  // fractional (subpixel) deltas per event at normal speed, which get
  // truncated to 0 by CGEventGetIntegerValueField — so that filter was
  // rejecting almost all real slow movement. Any mouseMoved event counts
  // as real for now; revisit warp-artifact filtering separately once this
  // baseline is confirmed solid.
  if (type == kCGEventMouseMoved) {
    dispatch_async(dispatch_get_main_queue(), ^{
      logmsg("move -> exitIdle");
      exitIdle();
      resetHideTimer();
    });
  }

  return event; // pass through untouched
}

@interface AppDel : NSObject <NSApplicationDelegate>
@end

@implementation AppDel
- (void)applicationDidFinishLaunching:(NSNotification *)note {
  logmsg("starting up");
  setup_cgs();

  CGEventMask mask = CGEventMaskBit(kCGEventMouseMoved);

  eventTap =
      CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                       kCGEventTapOptionListenOnly, mask, tapCallback, NULL);
  if (!eventTap) {
    logmsg("FATAL: failed to create event tap. Grant Accessibility + Input "
           "Monitoring permission to this binary in System Settings.");
    exit(1);
  }
  logmsg("event tap created");

  CFRunLoopSourceRef runLoopSource =
      CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
  CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
  CGEventTapEnable(eventTap, true);
  CFRelease(runLoopSource);

  hideTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                     dispatch_get_main_queue());
  dispatch_source_set_event_handler(hideTimer, ^{
    logmsg("idle timeout fired -> enterIdle");
    enterIdle();
  });
  dispatch_resume(hideTimer);
  resetHideTimer();

  // Keep re-asserting the hide while idle, in case something else
  // (another app, the system) shows the cursor back without us seeing
  // a real mouseMoved event for it.
  rehideTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                       dispatch_get_main_queue());
  dispatch_source_set_timer(rehideTimer, DISPATCH_TIME_NOW,
                            (uint64_t)(REHIDE_INTERVAL * NSEC_PER_SEC), 0);
  dispatch_source_set_event_handler(rehideTimer, ^{
    if (idle) {
      hideCursorNow();
    }
  });
  dispatch_resume(rehideTimer);

  logmsg("setup complete, idle timeout=%.1fs", IDLE_TIMEOUT);
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
