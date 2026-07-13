#import <AppKit/AppKit.h>

#define RIFT_CLI "/opt/homebrew/bin/rift-cli"

static const CGFloat CW = 22;
static const CGFloat CH = 16;
static const CGFloat GAP = 4;
static const CGFloat CR = 4;
static const CGFloat FS = 11;

@interface WSView : NSView
@property (strong) NSArray *workspaces;
@end

@implementation WSView

- (void)drawRect:(NSRect)dirtyRect {
  NSGraphicsContext *ctx = NSGraphicsContext.currentContext;
  [ctx saveGraphicsState];
  CGContextRef cg = ctx.CGContext;
  CGContextSetShouldAntialias(cg, true);

  CGFloat y = round((self.bounds.size.height - CH) / 2);
  CGFloat x = 2;

  for (NSDictionary *ws in self.workspaces) {
    BOOL active = [ws[@"is_active"] boolValue];
    NSInteger wc = [ws[@"window_count"] integerValue];
    if (!active && wc == 0) continue;

    NSRect r = NSMakeRect(x, y, CW, CH);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:r xRadius:CR yRadius:CR];

    if (active) {
      [[NSColor whiteColor] setFill];
      [path fill];
      [[NSColor colorWithWhite:1 alpha:0.3] setStroke];
    } else {
      [[NSColor colorWithWhite:1 alpha:0.35] setFill];
      [path fill];
      [[NSColor colorWithWhite:1 alpha:0.5] setStroke];
    }
    [path setLineWidth:1];
    [path stroke];

    NSString *label = [NSString stringWithFormat:@"%ld",
      (long)[ws[@"index"] integerValue] + 1];
    NSColor *tc = active ? [NSColor blackColor] : [NSColor whiteColor];
    NSDictionary *attr = @{
      NSFontAttributeName: [NSFont systemFontOfSize:FS],
      NSForegroundColorAttributeName: tc,
    };
    NSSize ts = [label sizeWithAttributes:attr];
    [label drawAtPoint:NSMakePoint(
      round(NSMidX(r) - ts.width / 2),
      round(NSMidY(r) - ts.height / 2) - 1
    ) withAttributes:attr];

    x += CW + GAP;
  }

  [ctx restoreGraphicsState];
}

@end

@interface WSIndicator : NSObject
@property (strong) NSStatusItem *item;
@property (strong) WSView *view;
@end

@implementation WSIndicator

- (instancetype)init {
  self = [super init];
  self.view = [[WSView alloc] initWithFrame:NSMakeRect(0, 0, 30, CH + 4)];
  self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  self.item.button.action = nil;
  [self.item.button addSubview:self.view];
  [self update];
  [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(update) userInfo:nil repeats:YES];
  return self;
}

- (void)update {
  FILE *fp = popen(RIFT_CLI " query workspaces 2>/dev/null", "r");
  if (!fp) return;
  NSMutableData *data = [NSMutableData data];
  char buf[4096];
  size_t n;
  while ((n = fread(buf, 1, sizeof(buf), fp)) > 0)
    [data appendBytes:buf length:n];
  int rc = pclose(fp);
  if (rc != 0) return;

  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  if (![json isKindOfClass:[NSArray class]]) return;

  self.view.workspaces = (NSArray *)json;

  CGFloat count = 0;
  for (NSDictionary *ws in (NSArray *)json) {
    if ([ws[@"is_active"] boolValue] || [ws[@"window_count"] integerValue] > 0)
      count++;
  }
  if (count < 1) count = 1;

  CGFloat w = count * CW + (count - 1) * GAP + 4;
  self.item.length = w;

  NSView *btn = self.item.button;
  NSRect br = btn.bounds;
  CGFloat y = round((br.size.height - CH) / 2);
  [self.view setFrame:NSMakeRect(0, y, w, CH)];
  [self.view setNeedsDisplay:YES];
}

@end

int main() {
  @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    WSIndicator *indicator = [[WSIndicator alloc] init];
    (void)indicator;
    [NSApp run];
  }
  return 0;
}
