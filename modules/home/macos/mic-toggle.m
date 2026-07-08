#import <CoreAudio/CoreAudio.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <fcntl.h>
#import <unistd.h>
#import <errno.h>
#import <sys/file.h>
#import <stdio.h>
#import <time.h>

#define STATE_FILE_PATH @"/tmp/qs-mic-state"
#define LOCK_FILE_PATH @"/tmp/qs-mic-toggle.lock"
#define LOG_FILE_PATH @"/tmp/qs-mic-toggle.log"
#define LOG(...) do { \
  NSString *_msg = [NSString stringWithFormat:__VA_ARGS__]; \
  FILE *_f = fopen([LOG_FILE_PATH fileSystemRepresentation], "a"); \
  if (_f) { \
    fprintf(_f, "[%ld] %s\n", time(NULL), [_msg UTF8String]); \
    fclose(_f); \
  } \
} while(0)

static AudioDeviceID getDevice(void) {
  AudioDeviceID device = kAudioObjectUnknown;
  UInt32 size = sizeof(device);
  AudioObjectPropertyAddress addr = {
    kAudioHardwarePropertyDefaultInputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMain
  };
  AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL,
                              &size, &device);
  return device;
}

static int getMuted(void) {
  AudioDeviceID device = getDevice();
  AudioObjectPropertyAddress addr = {
    kAudioDevicePropertyMute,
    kAudioDevicePropertyScopeInput,
    kAudioObjectPropertyElementMain
  };
  if (!AudioObjectHasProperty(device, &addr)) return -1;
  UInt32 val;
  UInt32 size = sizeof(val);
  if (AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &val) != noErr) return -1;
  return val;
}

static void writeState(NSString *state) {
  [state writeToFile:STATE_FILE_PATH
          atomically:YES
            encoding:NSUTF8StringEncoding
               error:NULL];
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    LOG(@"=== mic-toggle invoked (pid=%d) ===", getpid());

    uint32_t bufsize = 0;
    _NSGetExecutablePath(NULL, &bufsize);
    char *buf = malloc(bufsize);
    _NSGetExecutablePath(buf, &bufsize);
    NSString *binPath = [NSString stringWithUTF8String:buf];
    free(buf);
    binPath = [binPath stringByResolvingSymlinksInPath];
    NSString *binDir = binPath.stringByDeletingLastPathComponent;

    int lock = open([LOCK_FILE_PATH fileSystemRepresentation],
                    O_CREAT | O_WRONLY, 0644);
    if (lock == -1) {
      LOG(@"failed to create lock file, proceeding anyway");
    } else if (flock(lock, LOCK_EX | LOCK_NB) == -1) {
      LOG(@"another instance is already running, skipping");
      close(lock);
      return 1;
    }

    int muted = getMuted();
    if (muted < 0) {
      LOG(@"getMuted failed (device=%u), aborting", getDevice());
      if (lock != -1) close(lock);
      unlink([LOCK_FILE_PATH fileSystemRepresentation]);
      return 1;
    }

    LOG(@"muted=%d, action=%@", muted, muted ? @"UNMUTE" : @"MUTE");

    NSString *cmd = [NSString stringWithFormat:
        @"set volume input volume %d", muted ? 50 : 0];
    NSTask *osaTask = [[NSTask alloc] init];
    osaTask.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
    osaTask.arguments = @[@"-e", cmd];
    [osaTask launch];
    [osaTask waitUntilExit];

    writeState(muted ? @"unmuted" : @"muted");

    NSString *soundName = muted ? @"unmute.mp3" : @"mute.mp3";
    NSString *soundPath = [binDir stringByAppendingPathComponent:soundName];

    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/afplay"];
    task.arguments = @[soundPath];
    [task launch];
    [task waitUntilExit];

    if (lock != -1) close(lock);
    unlink([LOCK_FILE_PATH fileSystemRepresentation]);
    LOG(@"done");
  }
  return 0;
}
