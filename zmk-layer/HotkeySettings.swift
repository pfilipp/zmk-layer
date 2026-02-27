import AppKit

struct KeyCombo: Equatable {
    var keyCode: UInt16
    var modifiers: NSEvent.ModifierFlags

    static let defaultOverlay = KeyCombo(keyCode: 40, modifiers: [.command, .control]) // ⌘⌃K

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyCodeToString(keyCode))
        return parts.joined(separator: " ")
    }

    private static func keyCodeToString(_ keyCode: UInt16) -> String {
        let mapping: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 105: "F13", 107: "F14",
            109: "F10", 111: "F12", 113: "F15",
            118: "F4", 120: "F2", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return mapping[keyCode] ?? "?"
    }
}

@Observable
final class HotkeySettings {
    var overlayShortcut: KeyCombo {
        didSet { save() }
    }

    var onShortcutChanged: (() -> Void)?

    init() {
        let defaults = UserDefaults.standard
        if let code = defaults.object(forKey: "overlayKeyCode") as? Int,
           let mods = defaults.object(forKey: "overlayModifiers") as? UInt {
            overlayShortcut = KeyCombo(keyCode: UInt16(code), modifiers: NSEvent.ModifierFlags(rawValue: mods))
        } else {
            overlayShortcut = .defaultOverlay
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(Int(overlayShortcut.keyCode), forKey: "overlayKeyCode")
        defaults.set(overlayShortcut.modifiers.rawValue, forKey: "overlayModifiers")
        onShortcutChanged?()
    }
}
