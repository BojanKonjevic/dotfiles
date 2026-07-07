#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <unistd.h>

int main(int argc, char **argv) {
  if (@available(macOS 14.0, *)) {
    CGRequestListenEventAccess();
  }
  argv[0] = "/opt/homebrew/bin/rift";
  execv(argv[0], argv);
  return 1;
}
