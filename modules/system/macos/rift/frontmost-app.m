#import <AppKit/AppKit.h>

int main(void) {
  @autoreleasepool {
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (app.bundleIdentifier) {
      printf("%s\n", app.bundleIdentifier.UTF8String);
    }
  }
  return 0;
}

