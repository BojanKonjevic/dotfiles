#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

#define IDLE_TIMEOUT 3.0

typedef int (*CGSDefaultConnectionFunc)(void);
typedef void (*CGSSetConnectionPropertyFunc)(int cid, int targetCID,
                                             CFStringRef key,
                                             CFBooleanRef value);

static int hidden = 0;
static CGDirectDisplayID displayID;

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

@interface AppDel : NSObject <NSApplicationDelegate>
@end

@implementation AppDel
- (void)applicationDidFinishLaunching:(NSNotification *)note {
  displayID = CGMainDisplayID();
  setup_cgs();

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
          CFTimeInterval idle = CGEventSourceSecondsSinceLastEventType(
              kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved);
          if (!hidden && idle > IDLE_TIMEOUT) {
            dispatch_async(dispatch_get_main_queue(), ^{
              CGDisplayHideCursor(displayID);
              hidden = 1;
            });
          } else if (hidden && idle < 0.5) {
            dispatch_async(dispatch_get_main_queue(), ^{
              CGDisplayShowCursor(displayID);
              hidden = 0;
            });
          }
          usleep(100000);
        }
      });
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
