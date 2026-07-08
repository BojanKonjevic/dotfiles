#import <AppKit/AppKit.h>
#import <CoreAudio/CoreAudio.h>
#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <AudioUnit/AudioUnit.h>

static OSStatus micCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                            UInt32 inNumberFrames, AudioBufferList *ioData) {
  AudioUnit unit = (AudioUnit)inRefCon;
  AudioBufferList buf;
  buf.mNumberBuffers = 1;
  buf.mBuffers[0].mDataByteSize = inNumberFrames * 4;
  buf.mBuffers[0].mData = alloca(buf.mBuffers[0].mDataByteSize);
  buf.mBuffers[0].mNumberChannels = 1;
  AudioUnitRender(unit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &buf);
  return noErr;
}

#define STATE_FILE_PATH @"/tmp/qs-mic-state"

static AudioDeviceID getDefaultInputDevice(void) {
  AudioDeviceID device = kAudioObjectUnknown;
  UInt32 size = sizeof(device);
  AudioObjectPropertyAddress addr = {
    kAudioHardwarePropertyDefaultInputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMain
  };
  if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL,
                                  &size, &device) != noErr)
    return kAudioObjectUnknown;
  return device;
}

static BOOL getInputMuted(void) {
  AudioDeviceID device = getDefaultInputDevice();
  if (device == kAudioObjectUnknown) return NO;

  AudioObjectPropertyAddress addr = {
    kAudioDevicePropertyMute,
    kAudioDevicePropertyScopeInput,
    kAudioObjectPropertyElementMain
  };
  if (!AudioObjectHasProperty(device, &addr)) return NO;
  UInt32 val;
  UInt32 size = sizeof(val);
  if (AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &val) != noErr) return NO;
  return val != 0;
}



static NSString *binDir = nil;

static void playSound(NSString *name) {
  NSString *path = [binDir stringByAppendingPathComponent:name];
  NSTask *task = [[NSTask alloc] init];
  task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/afplay"];
  task.arguments = @[path];
  [task launch];
}

@class StatusBarController;

static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
  StatusBarController *self = (__bridge StatusBarController *)userData;
  [self toggleMic];
  return noErr;
}

@interface StatusBarController : NSObject
@property(strong) NSStatusItem *statusItem;
@property AudioUnit micUnit;
@property BOOL unmuted;
- (void)setIcon:(NSString *)state;
- (void)toggleMic;
@end

@implementation StatusBarController

- (instancetype)init {
  self = [super init];
  if (!self) return nil;

  _micUnit = NULL;
  _unmuted = !getInputMuted();
  _statusItem = [NSStatusBar.systemStatusBar
      statusItemWithLength:NSVariableStatusItemLength];

  [self setIcon:_unmuted ? @"unmuted" : @"muted"];
  if (_unmuted) {
    [self startMonitoring];
    applyInputState(YES);
  }

  [NSTimer scheduledTimerWithTimeInterval:0.5
                                   target:self
                                 selector:@selector(poll)
                                 userInfo:nil
                                  repeats:YES];

  EventHotKeyRef hotKeyRef;
  EventHotKeyID hotKeyID;
  hotKeyID.signature = 'MICT';
  hotKeyID.id = 1;
  RegisterEventHotKey(kVK_ANSI_Backslash, optionKey, hotKeyID,
                      GetApplicationEventTarget(), 0, &hotKeyRef);

  EventTypeSpec eventType;
  eventType.eventClass = kEventClassKeyboard;
  eventType.eventKind = kEventHotKeyPressed;
  InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType,
                                  (__bridge void *)self, NULL);

  return self;
}

- (void)startMonitoring {
  if (_micUnit) return;
  AudioComponentDescription desc = {
    kAudioUnitType_Output, kAudioUnitSubType_HALOutput,
    kAudioUnitManufacturer_Apple, 0, 0
  };
  AudioComponent comp = AudioComponentFindNext(NULL, &desc);
  if (!comp) return;
  AudioComponentInstanceNew(comp, &_micUnit);

  UInt32 enable = 1, disable = 0;
  AudioUnitSetProperty(_micUnit, kAudioOutputUnitProperty_EnableIO,
    kAudioUnitScope_Input, 1, &enable, sizeof(enable));
  AudioUnitSetProperty(_micUnit, kAudioOutputUnitProperty_EnableIO,
    kAudioUnitScope_Output, 0, &disable, sizeof(disable));

  AudioDeviceID device = getDefaultInputDevice();
  AudioUnitSetProperty(_micUnit, kAudioOutputUnitProperty_CurrentDevice,
    kAudioUnitScope_Global, 0, &device, sizeof(device));

  AURenderCallbackStruct cb = { .inputProc = micCallback, .inputProcRefCon = _micUnit };
  AudioUnitSetProperty(_micUnit, kAudioOutputUnitProperty_SetInputCallback,
    kAudioUnitScope_Global, 0, &cb, sizeof(cb));

  AudioUnitInitialize(_micUnit);
  AudioOutputUnitStart(_micUnit);
}

- (void)stopMonitoring {
  if (!_micUnit) return;
  AudioOutputUnitStop(_micUnit);
  AudioUnitUninitialize(_micUnit);
  AudioComponentInstanceDispose(_micUnit);
  _micUnit = NULL;
}

static void applyInputState(BOOL unmute) {
  AudioDeviceID device = getDefaultInputDevice();
  if (device == kAudioObjectUnknown) return;
  AudioObjectPropertyAddress addr;

  UInt32 muteVal = unmute ? 0 : 1;
  addr.mSelector = kAudioDevicePropertyMute;
  addr.mScope = kAudioDevicePropertyScopeInput;
  addr.mElement = kAudioObjectPropertyElementMain;
  if (AudioObjectHasProperty(device, &addr))
    AudioObjectSetPropertyData(device, &addr, 0, NULL, sizeof(muteVal), &muteVal);

  Float32 volVal = unmute ? 0.5 : 0.0;
  addr.mSelector = kAudioDevicePropertyVolumeScalar;
  if (AudioObjectHasProperty(device, &addr))
    AudioObjectSetPropertyData(device, &addr, 0, NULL, sizeof(volVal), &volVal);
}

- (void)toggleMic {
  _unmuted = !_unmuted;
  if (_unmuted) {
    [self startMonitoring];
    applyInputState(YES);
  } else {
    applyInputState(NO);
    [self stopMonitoring];
  }

  writeState(_unmuted ? @"unmuted" : @"muted");
  [self setIcon:_unmuted ? @"unmuted" : @"muted"];
  playSound(_unmuted ? @"unmute.mp3" : @"mute.mp3");
}

- (void)poll {
  BOOL hwMuted = getInputMuted();
  [self setIcon:_unmuted ? @"unmuted" : @"muted"];
  if (_unmuted && hwMuted) {
    [self startMonitoring];
    applyInputState(YES);
  }
}

- (void)setIcon:(NSString *)state {
  NSButton *button = _statusItem.button;
  if (!button) return;

  button.action = @selector(toggleMic);
  button.target = self;

  NSString *iconName;
  NSColor *color;
  if ([state isEqualToString:@"muted"]) {
    iconName = @"mic.slash.fill";
    color = [NSColor colorWithRed:0.953 green:0.545 blue:0.659 alpha:1];
  } else {
    iconName = @"mic.fill";
    color = [NSColor colorWithRed:0.651 green:0.890 blue:0.631 alpha:1];
  }

  NSImageSymbolConfiguration *cfg =
      [NSImageSymbolConfiguration configurationWithPointSize:14
                                                      weight:NSFontWeightRegular];
  NSImageSymbolConfiguration *colorCfg =
      [NSImageSymbolConfiguration configurationWithHierarchicalColor:color];
  NSImage *img = [[[NSImage imageWithSystemSymbolName:iconName
                             accessibilityDescription:nil]
      imageWithSymbolConfiguration:cfg]
      imageWithSymbolConfiguration:colorCfg];
  button.image = img;
}

static void writeState(NSString *state) {
  [state writeToFile:STATE_FILE_PATH
          atomically:YES
            encoding:NSUTF8StringEncoding
               error:NULL];
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    binDir = [NSString stringWithUTF8String:argv[0]].stringByDeletingLastPathComponent;
    [NSApplication sharedApplication];
    [[StatusBarController alloc] init];
    [NSApplication.sharedApplication
        setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApplication.sharedApplication run];
  }
  return 0;
}
