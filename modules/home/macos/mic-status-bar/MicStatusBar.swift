import AppKit
import Foundation

let stateFilePath = "/tmp/qs-mic-state"
let micTogglePath: String
if let envPath = ProcessInfo.processInfo.environment["MIC_TOGGLE_PATH"], !envPath.isEmpty {
    micTogglePath = envPath
} else {
    micTogglePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".nix-profile/bin/mic-toggle")
        .path
}

class StatusBarController: NSObject {
    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    override init() {
        super.init()
        statusItem.button?.action = #selector(toggleMic)
        statusItem.button?.target = self
        refresh()
        Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(refresh),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func toggleMic() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: micTogglePath)
        try? task.run()
    }

    @objc func refresh() {
        let state = (
            try? String(contentsOfFile: stateFilePath, encoding: .utf8)
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"

        let iconName: String
        let color: NSColor
        switch state {
        case "muted":
            iconName = "mic.slash.fill"
            color = NSColor(
                red: 0.953, green: 0.545, blue: 0.659, alpha: 1
            )
        case "unmuted":
            iconName = "mic.fill"
            color = NSColor(
                red: 0.651, green: 0.890, blue: 0.631, alpha: 1
            )
        default:
            iconName = "mic.fill"
            color = .systemGray
        }

        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(
            pointSize: 14, weight: .regular
        )
        button.image = NSImage(
            systemSymbolName: iconName,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(config)
        button.contentTintColor = color
    }
}

let controller = StatusBarController()
NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.run()
