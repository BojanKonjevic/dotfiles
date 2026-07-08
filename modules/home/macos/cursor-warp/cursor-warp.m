#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define POLL_MS 0.05

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property CGRect lastBounds;
@property BOOL ready;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note {
  fprintf(stderr, "cursor-warp: started\n");
  self.lastBounds = CGRectNull;
  self.ready = NO;

  [self performSelector:@selector(onReady) withObject:nil afterDelay:0.5];

  [NSTimer scheduledTimerWithTimeInterval:POLL_MS repeats:YES block:^(NSTimer *t) {
    [self poll];
  }];
}

- (void)onReady {
  self.ready = YES;
  CGWarpMouseCursorPosition(CGPointMake(200, 200));
}

- (CGPoint)mouseLocation {
  CGEventRef e = CGEventCreate(NULL);
  CGPoint loc = CGEventGetLocation(e);
  CFRelease(e);
  return loc;
}

- (void)poll {
  if (!self.ready) return;

  pid_t pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
  if (!pid) return;

  CFArrayRef list = CGWindowListCopyWindowInfo(
      kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
      kCGNullWindowID);
  if (!list) return;

  CFIndex count = CFArrayGetCount(list);
  CGRect target = CGRectNull;

  for (CFIndex i = 0; i < count; i++) {
    NSDictionary *info = (__bridge NSDictionary *)CFArrayGetValueAtIndex(list, i);
    NSNumber *owner = info[(__bridge NSString *)kCGWindowOwnerPID];
    if (!owner || owner.intValue != pid) continue;
    NSNumber *layer = info[(__bridge NSString *)kCGWindowLayer];
    if (!layer || layer.intValue != 0) continue;
    NSDictionary *bounds = info[(__bridge NSString *)kCGWindowBounds];
    if (!bounds) continue;
    CGRect rect;
    CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)bounds, &rect);
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) continue;
    target = rect;
    break;
  }
  CFRelease(list);

  if (CGRectIsNull(target)) return;

  if (CGRectIsNull(self.lastBounds)) {
    self.lastBounds = target;
    return;
  }

  if (CGRectEqualToRect(target, self.lastBounds)) return;

  self.lastBounds = target;

  CGPoint mouse = [self mouseLocation];
  if (CGRectContainsPoint(target, mouse)) return;

  CFTimeInterval mouseAge = CGEventSourceSecondsSinceLastEventType(
      kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved);
  if (mouseAge < 0.1) return;

  CGWarpMouseCursorPosition(CGPointMake(
      CGRectGetMidX(target), CGRectGetMidY(target)));
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;
    [app setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [app run];
  }
  return 0;
}
