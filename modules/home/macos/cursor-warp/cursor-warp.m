#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define WARP_WINDOW_MS 0.5

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type,
                                   CGEventRef event, void *refcon) {
  if (type == kCGEventTapDisabledByTimeout) {
    fprintf(stderr, "cursor-warp: event tap disabled by timeout\n");
    return NULL;
  }
  if (type != kCGEventKeyDown)
    return event;

  CGEventFlags flags = CGEventGetFlags(event);
  if (!(flags & kCGEventFlagMaskAlternate))
    return event;

  uint16_t key = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
  BOOL isFocusDir = (key == 4 || key == 38 || key == 40 || key == 37);
  BOOL isMoveToWS = (key >= 18 && key <= 29) && (flags & kCGEventFlagMaskShift);

  if (isFocusDir || isMoveToWS) {
    fprintf(stderr, "cursor-warp: scheduling warp\n");
    [(__bridge id)refcon performSelector:@selector(scheduleWarp)];
  }
  return event;
}

static void axObserverCallback(AXObserverRef observer, AXUIElementRef element,
                               CFStringRef notification, void *refcon) {
  [(__bridge id)refcon performSelector:@selector(onFocusChanged)];
}

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property BOOL pendingWarp;
@property(strong) NSTimer *warpTimer;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note {
  fprintf(stderr, "cursor-warp: started\n");

  if (!AXIsProcessTrusted()) {
    fprintf(stderr, "cursor-warp: accessibility permission not granted\n");
    return;
  }
  fprintf(stderr, "cursor-warp: accessibility granted\n");
  [self setupEventTap];
  [self setupAXObserver];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        fprintf(stderr, "cursor-warp: initial warp\n");
        [self warpToFocusedWindow];
      });
}

- (void)scheduleWarp {
  self.pendingWarp = YES;
  [self.warpTimer invalidate];
  self.warpTimer = [NSTimer scheduledTimerWithTimeInterval:WARP_WINDOW_MS
                                                   repeats:NO
                                                     block:^(NSTimer *t) {
                                                       self.pendingWarp = NO;
                                                     }];
}

- (void)onFocusChanged {
  if (!self.pendingWarp)
    return;
  self.pendingWarp = NO;
  [self.warpTimer invalidate];
  [self warpToFocusedWindow];
}

- (void)setupEventTap {
  CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);
  CFMachPortRef tap = CGEventTapCreate(
      kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, mask,
      eventTapCallback, (__bridge void *)self);
  if (!tap || !CFMachPortIsValid(tap)) {
    NSLog(@"CursorWarp: failed to create event tap");
    return;
  }
  CFRunLoopAddSource(CFRunLoopGetCurrent(),
                     CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
                     kCFRunLoopDefaultMode);
}

- (void)setupAXObserver {
  AXObserverRef observer;
  if (AXObserverCreate(getpid(), axObserverCallback, &observer) !=
      kAXErrorSuccess) {
    NSLog(@"CursorWarp: failed to create AX observer");
    return;
  }

  AXUIElementRef systemWide = AXUIElementCreateSystemWide();
  AXError err = AXObserverAddNotification(observer, systemWide,
                                          CFSTR("AXFocusedWindowChanged"),
                                          (__bridge void *)self);
  CFRelease(systemWide);

  if (err != kAXErrorSuccess) {
    NSLog(@"CursorWarp: AXObserverAddNotification failed (%d)", err);
    CFRelease(observer);
    return;
  }

  CFRunLoopAddSource(CFRunLoopGetCurrent(),
                     AXObserverGetRunLoopSource(observer),
                     kCFRunLoopDefaultMode);
}

- (void)warpToFocusedWindow {
  NSRunningApplication *frontApp =
      NSWorkspace.sharedWorkspace.frontmostApplication;
  if (!frontApp)
    return;

  AXUIElementRef appElement =
      AXUIElementCreateApplication(frontApp.processIdentifier);
  CFTypeRef focusedWindow;
  AXError err = AXUIElementCopyAttributeValue(
      appElement, CFSTR("AXFocusedWindow"), &focusedWindow);
  CFRelease(appElement);
  if (err != kAXErrorSuccess)
    return;

  AXUIElementRef window = focusedWindow;

  CFTypeRef positionRef;
  CFTypeRef sizeRef;
  AXUIElementCopyAttributeValue(window, CFSTR("AXPosition"), &positionRef);
  AXUIElementCopyAttributeValue(window, CFSTR("AXSize"), &sizeRef);
  CFRelease(window);

  if (!positionRef || !sizeRef) {
    if (positionRef)
      CFRelease(positionRef);
    if (sizeRef)
      CFRelease(sizeRef);
    return;
  }

  CGPoint position;
  CGSize size;
  Boolean ok = AXValueGetValue(positionRef, kAXValueCGPointType, &position);
  if (!ok) {
    CFRelease(positionRef);
    CFRelease(sizeRef);
    return;
  }
  ok = AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
  if (!ok) {
    CFRelease(positionRef);
    CFRelease(sizeRef);
    return;
  }
  CFRelease(positionRef);
  CFRelease(sizeRef);

  CGPoint center =
      CGPointMake(position.x + size.width / 2, position.y + size.height / 2);

  CGWarpMouseCursorPosition(center);
  CGEventRef moveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved,
                                                 center, kCGMouseButtonLeft);
  if (moveEvent) {
    CGEventPost(kCGHIDEventTap, moveEvent);
    CFRelease(moveEvent);
  }
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
