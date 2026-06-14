import AppKit
import Foundation

let warpWindowMs: TimeInterval = 0.5

class AppDelegate: NSObject, NSApplicationDelegate {
    var pendingWarp = false
    var warpTimer: Timer?

    // ── App Delegate ──────────────────────────────────────────────────────────

    func applicationDidFinishLaunching(_: Notification) {
        guard AXIsProcessTrusted() else {
            NSLog("CursorWarp: accessibility permission not granted")
            return
        }

        setupEventTap()
        setupAXObserver()

        // Warp once on startup to initial focused window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.warpToFocusedWindow()
        }
    }

    // ── Event Tap: detect AeroSpace focus-change keys ────────────────────────
    // AeroSpace keycodes (ANSI physical positions):
    //   h=4, j=38, k=40, l=37  (focus/move direction)
    //   numbers 1-0 = 18-29    (workspace select/move)

    let focusKeys: Set<UInt16> = [4, 38, 40, 37]

    func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                let opts = event.flags
                guard opts.contains(.maskAlternate) else { return Unmanaged.passUnretained(event) }
                let key = event.keyCode
                let isFocusDir = delegate.focusKeys.contains(key)
                let isMoveToWS = key >= 18 && key <= 29 && opts.contains(.maskShift)
                if isFocusDir || isMoveToWS {
                    delegate.pendingWarp = true
                    delegate.warpTimer?.invalidate()
                    delegate.warpTimer = Timer.scheduledTimer(
                        withTimeInterval: warpWindowMs,
                        repeats: false
                    ) { _ in delegate.pendingWarp = false }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ), tap.isValid else {
            NSLog("CursorWarp: failed to create event tap")
            return
        }

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
            .defaultMode
        )
    }

    // ── AX Observer: detect focused window changes ──────────────────────────

    func setupAXObserver() {
        let systemWide = AXUIElementCreateSystemWide()
        var observer: AXObserver?
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
            DispatchQueue.main.async {
                guard delegate.pendingWarp else { return }
                delegate.pendingWarp = false
                delegate.warpTimer?.invalidate()
                delegate.warpToFocusedWindow()
            }
        }
        guard AXObserverCreate(getpid(), callback, &observer) == .success,
              let observer
        else {
            NSLog("CursorWarp: failed to create AX observer")
            return
        }
        let result = AXObserverAddNotification(
            observer,
            systemWide,
            "AXFocusedWindowChanged" as CFString,
            selfPtr
        )
        if result != .success {
            NSLog("CursorWarp: AXObserverAddNotification failed (\(result.rawValue))")
            return
        }
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(observer),
            .defaultMode
        )
    }

    // ── Warp ─────────────────────────────────────────────────────────────────

    func warpToFocusedWindow() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement, "AXFocusedWindow" as CFString, &focusedWindow
        ) == .success,
            let windowElement = focusedWindow as! AXUIElement?
        else { return }

        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, "AXPosition" as CFString, &positionRef)
        AXUIElementCopyAttributeValue(windowElement, "AXSize" as CFString, &sizeRef)
        guard
            let posValue = positionRef,
            let sizeValue = sizeRef,
            AXValueGetType(posValue as! AXValue) == .cgPoint,
            AXValueGetType(sizeValue as! AXValue) == .cgSize
        else { return }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        let center = CGPoint(
            x: position.x + size.width / 2,
            y: position.y + size.height / 2
        )
        CGWarpMouseCursorPosition(center)
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: center,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.prohibited)
NSApplication.shared.run()
