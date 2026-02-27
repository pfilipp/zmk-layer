//
//  KeymapParser.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 27/02/2026.
//

import Foundation

// MARK: - Physical Layout

struct PhysicalKey: Codable {
    let x: Double
    let y: Double
    let row: Int
    let col: Int
}

struct PositionedKey: Codable {
    let physical: PhysicalKey
}

// MARK: - Key Labels

struct KeyLabel: Codable {
    let tap: String
    let hold: String?
    let isTransparent: Bool
    let isNone: Bool
    let isSticky: Bool
    let isModifierWrapped: Bool

    init(tap: String, hold: String?, isTransparent: Bool, isNone: Bool,
         isSticky: Bool = false, isModifierWrapped: Bool = false) {
        self.tap = tap
        self.hold = hold
        self.isTransparent = isTransparent
        self.isNone = isNone
        self.isSticky = isSticky
        self.isModifierWrapped = isModifierWrapped
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tap = try container.decode(String.self, forKey: .tap)
        hold = try container.decodeIfPresent(String.self, forKey: .hold)
        isTransparent = try container.decode(Bool.self, forKey: .isTransparent)
        isNone = try container.decode(Bool.self, forKey: .isNone)
        isSticky = try container.decodeIfPresent(Bool.self, forKey: .isSticky) ?? false
        isModifierWrapped = try container.decodeIfPresent(Bool.self, forKey: .isModifierWrapped) ?? false
    }
}

struct ParsedLayer: Codable {
    let name: String
    let keys: [KeyLabel]
}

// MARK: - Persisted Layout Data

struct KeyboardLayoutData: Codable {
    let physicalKeys: [PositionedKey]
    let layers: [ParsedLayer]
}

// MARK: - JSON Layout Parsing

private struct PhysicalLayoutJSON: Codable {
    let layouts: LayoutsContainer

    struct LayoutsContainer: Codable {
        let default_transform: TransformContainer
    }

    struct TransformContainer: Codable {
        let layout: [PhysicalKey]
    }
}

// MARK: - Keycode Display Map

let keycodeMap: [String: String] = [
    // Letters are passed through as-is (single uppercase letter)
    // Numbers
    "N0": "0", "N1": "1", "N2": "2", "N3": "3", "N4": "4",
    "N5": "5", "N6": "6", "N7": "7", "N8": "8", "N9": "9",
    "NUMBER_0": "0", "NUMBER_1": "1", "NUMBER_2": "2", "NUMBER_3": "3", "NUMBER_4": "4",
    "NUMBER_5": "5", "NUMBER_6": "6", "NUMBER_7": "7", "NUMBER_8": "8", "NUMBER_9": "9",
    // Numpad
    "KP_NUMBER_0": "Np0", "KP_NUMBER_1": "Np1", "KP_NUMBER_2": "Np2",
    "KP_NUMBER_3": "Np3", "KP_NUMBER_4": "Np4", "KP_NUMBER_5": "Np5",
    "KP_NUMBER_6": "Np6", "KP_NUMBER_7": "Np7", "KP_NUMBER_8": "Np8",
    "KP_NUMBER_9": "Np9",
    "KP_PLUS": "Np+", "KP_MINUS": "Np-", "KP_ENTER": "NpEnt", "KP_DOT": "Np.",
    // Modifiers
    "LEFT_SHIFT": "Shift", "RIGHT_SHIFT": "Shift",
    "LEFT_CONTROL": "Ctrl", "RIGHT_CONTROL": "Ctrl",
    "LEFT_ALT": "Alt", "RIGHT_ALT": "Alt",
    "LGUI": "Cmd", "RGUI": "Cmd",
    "LEFT_COMMAND": "Cmd", "RIGHT_COMMAND": "Cmd",
    "LEFT_GUI": "Cmd", "RIGHT_GUI": "Cmd",
    "LALT": "Alt", "RALT": "Alt",
    "LCTRL": "Ctrl", "RCTRL": "Ctrl",
    "LSHFT": "Shift", "RSHFT": "Shift",
    // Common keys
    "SPACE": "Spc", "BSPC": "Bspc", "BACKSPACE": "Bspc",
    "ENTER": "Ent", "RETURN": "Ent", "RET": "Ent",
    "TAB": "Tab", "ESCAPE": "Esc", "ESC": "Esc",
    "DELETE": "Del", "DEL": "Del",
    "CAPSLOCK": "Caps", "CAPS": "Caps",
    // Punctuation
    "COMMA": ",", "DOT": ".", "FSLH": "/", "BSLH": "\\",
    "SEMI": ";", "SEMICOLON": ";", "SQT": "'", "APOS": "'",
    "LBKT": "[", "RBKT": "]", "LEFT_BRACKET": "[", "RIGHT_BRACKET": "]",
    "LEFT_BRACE": "{", "RIGHT_BRACE": "}",
    "GRAVE": "`", "TILDE": "~",
    "MINUS": "-", "EQUAL": "=", "PLUS": "+",
    "UNDERSCORE": "_", "COLON": ":",
    // Arrow keys
    "LEFT": "\u{2190}", "RIGHT": "\u{2192}", "UP": "\u{2191}", "DOWN": "\u{2193}",
    "LEFT_ARROW": "\u{2190}", "RIGHT_ARROW": "\u{2192}",
    "UP_ARROW": "\u{2191}", "DOWN_ARROW": "\u{2193}",
    // Function keys
    "F1": "F1", "F2": "F2", "F3": "F3", "F4": "F4",
    "F5": "F5", "F6": "F6", "F7": "F7", "F8": "F8",
    "F9": "F9", "F10": "F10", "F11": "F11", "F12": "F12",
    // Media
    "C_VOLUME_UP": "Vol+", "C_VOL_UP": "Vol+",
    "C_VOLUME_DOWN": "Vol-", "C_VOL_DN": "Vol-",
    "C_MUTE": "Mute",
    "C_PLAY_PAUSE": "Play", "C_PP": "Play",
    "C_NEXT": "Next", "C_PREVIOUS": "Prev",
    // Bluetooth
    "BT_CLR": "BtClr",
]

// MARK: - Modifier Wrappers

private let modifierPrefixes: [(prefix: String, label: String)] = [
    ("LG", "Cmd"), ("RG", "Cmd"),
    ("LS", "Shift"), ("RS", "Shift"),
    ("LA", "Alt"), ("RA", "Alt"),
    ("LC", "Ctrl"), ("RC", "Ctrl"),
]

// MARK: - Parser

enum KeymapParser {

    private static let modifierKeycodes: Set<String> = [
        "LEFT_SHIFT", "RIGHT_SHIFT", "LSHFT", "RSHFT",
        "LEFT_CONTROL", "RIGHT_CONTROL", "LCTRL", "RCTRL",
        "LEFT_ALT", "RIGHT_ALT", "LALT", "RALT",
        "LGUI", "RGUI", "LEFT_COMMAND", "RIGHT_COMMAND", "LEFT_GUI", "RIGHT_GUI",
    ]

    // MARK: - Public API

    static func parse(keymapURL: URL, jsonURL: URL) throws -> KeyboardLayoutData {
        let physicalKeys = try parsePhysicalLayout(from: jsonURL)
        let layers = try parseKeymap(from: keymapURL, keyCount: physicalKeys.count)
        return KeyboardLayoutData(physicalKeys: physicalKeys, layers: layers)
    }

    // MARK: - Physical Layout

    static func parsePhysicalLayout(from url: URL) throws -> [PositionedKey] {
        let data = try Data(contentsOf: url)
        let layoutJSON = try JSONDecoder().decode(PhysicalLayoutJSON.self, from: data)
        let keys = layoutJSON.layouts.default_transform.layout

        return keys.map { key in
            PositionedKey(physical: key)
        }
    }

    // MARK: - Keymap Parsing

    static func parseKeymap(from url: URL, keyCount: Int) throws -> [ParsedLayer] {
        let content = try String(contentsOf: url, encoding: .utf8)

        // Find the keymap { ... } block
        guard let keymapRange = findKeymapBlock(in: content) else {
            throw ParseError.keymapBlockNotFound
        }
        let keymapContent = String(content[keymapRange])

        // Find each layer block within the keymap
        return parseLayerBlocks(from: keymapContent, keyCount: keyCount)
    }

    // MARK: - Private Helpers

    private static func findKeymapBlock(in content: String) -> Range<String.Index>? {
        // Find "keymap {" and match braces to find the end
        guard let keymapStart = content.range(of: "keymap {") ?? content.range(of: "keymap{") else {
            return nil
        }

        var depth = 0
        var foundOpen = false
        var idx = keymapStart.lowerBound

        while idx < content.endIndex {
            let ch = content[idx]
            if ch == "{" {
                depth += 1
                foundOpen = true
            } else if ch == "}" {
                depth -= 1
                if foundOpen && depth == 0 {
                    return keymapStart.lowerBound..<content.index(after: idx)
                }
            }
            idx = content.index(after: idx)
        }
        return nil
    }

    private static func parseLayerBlocks(from keymapContent: String, keyCount: Int) -> [ParsedLayer] {
        var layers: [ParsedLayer] = []

        // Pattern: find named blocks like "sweep34 {" that contain "bindings = <...>;"
        // We look for: label { ... bindings = <...>; ... }
        let lines = keymapContent.components(separatedBy: "\n")

        var i = 0
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // Check if this line starts a layer block: "name {" (but not "keymap {" or "compatible")
            if trimmed.hasSuffix("{"),
               !trimmed.contains("keymap"),
               !trimmed.contains("compatible") {
                let name = trimmed
                    .replacingOccurrences(of: "{", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // Collect lines until matching closing brace
                var depth = 1
                var blockContent = ""
                i += 1
                while i < lines.count && depth > 0 {
                    for ch in lines[i] {
                        if ch == "{" { depth += 1 }
                        if ch == "}" { depth -= 1 }
                    }
                    if depth > 0 {
                        blockContent += lines[i] + "\n"
                    }
                    i += 1
                }

                // Extract bindings from the block
                if let bindings = extractBindings(from: blockContent) {
                    let keyLabels = parseBindings(bindings, keyCount: keyCount)
                    if !keyLabels.isEmpty {
                        layers.append(ParsedLayer(name: name, keys: keyLabels))
                    }
                }
                continue
            }
            i += 1
        }

        return layers
    }

    private static func extractBindings(from blockContent: String) -> String? {
        // Find "bindings = <...>;" — content may span multiple lines
        guard let startRange = blockContent.range(of: "bindings = <") else { return nil }
        let afterOpen = startRange.upperBound

        guard let endRange = blockContent.range(of: ">;", range: afterOpen..<blockContent.endIndex) else {
            return nil
        }

        return String(blockContent[afterOpen..<endRange.lowerBound])
    }

    private static func parseBindings(_ raw: String, keyCount: Int) -> [KeyLabel] {
        // Normalize whitespace
        let normalized = raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        // Split on "&" to get individual bindings
        let parts = normalized.components(separatedBy: "&")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return parts.prefix(keyCount).map { parseBinding($0) }
    }

    private static func parseBinding(_ raw: String) -> KeyLabel {
        // Tokenize respecting parentheses: "kp LG(C)" → ["kp", "LG(C)"]
        let tokens = tokenize(raw)
        guard let behavior = tokens.first else {
            return KeyLabel(tap: "?", hold: nil, isTransparent: false, isNone: false)
        }

        switch behavior {
        case "trans":
            return KeyLabel(tap: "", hold: nil, isTransparent: true, isNone: false)
        case "none":
            return KeyLabel(tap: "", hold: nil, isTransparent: false, isNone: true)
        case "bootloader":
            return KeyLabel(tap: "Boot", hold: nil, isTransparent: false, isNone: false)
        case "kp":
            let keycode = tokens.count > 1 ? tokens[1] : "?"
            let isModifier = keycode.contains("(") || Self.modifierKeycodes.contains(keycode)
            return KeyLabel(tap: displayName(for: keycode), hold: nil, isTransparent: false, isNone: false, isModifierWrapped: isModifier)
        case "hml", "hmr", "mt":
            let holdMod = tokens.count > 1 ? tokens[1] : "?"
            let tapKey = tokens.count > 2 ? tokens[2] : "?"
            return KeyLabel(tap: displayName(for: tapKey), hold: displayName(for: holdMod), isTransparent: false, isNone: false)
        case "lt":
            let layerNum = tokens.count > 1 ? tokens[1] : "?"
            let tapKey = tokens.count > 2 ? tokens[2] : "?"
            return KeyLabel(tap: displayName(for: tapKey), hold: "L\(layerNum)", isTransparent: false, isNone: false)
        case "mo":
            let layerNum = tokens.count > 1 ? tokens[1] : "?"
            return KeyLabel(tap: "L\(layerNum)", hold: nil, isTransparent: false, isNone: false)
        case "tog":
            let layerNum = tokens.count > 1 ? tokens[1] : "?"
            return KeyLabel(tap: "Tog\(layerNum)", hold: nil, isTransparent: false, isNone: false)
        case "sk":
            let mod = tokens.count > 1 ? tokens[1] : "?"
            return KeyLabel(tap: displayName(for: mod), hold: nil, isTransparent: false, isNone: false, isSticky: true)
        case "bt":
            let param = tokens.dropFirst().joined(separator: " ")
            let display = keycodeMap[param] ?? param
                .replacingOccurrences(of: "BT_SEL ", with: "BT")
                .replacingOccurrences(of: "BT_CLR", with: "BtClr")
            return KeyLabel(tap: display, hold: nil, isTransparent: false, isNone: false)
        case "shift_caps_tap_dance":
            return KeyLabel(tap: "Shift", hold: "Caps", isTransparent: false, isNone: false)
        default:
            // Unknown behavior — show as-is
            let label = tokens.joined(separator: " ")
            return KeyLabel(tap: label, hold: nil, isTransparent: false, isNone: false)
        }
    }

    /// Tokenizes a binding string, keeping parenthesized groups together.
    /// e.g. "kp LS(LA(LG(SPACE)))" → ["kp", "LS(LA(LG(SPACE)))"]
    private static func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var depth = 0

        for ch in input {
            if ch == "(" {
                depth += 1
                current.append(ch)
            } else if ch == ")" {
                depth -= 1
                current.append(ch)
            } else if ch == " " && depth == 0 {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    /// Converts a ZMK keycode to a short display label.
    /// Modifier wrappers are collected on one line (space-separated) with a
    /// newline before the final key value, e.g. `LS(LA(LG(SPACE)))` → "Shift Alt Cmd\nSpc".
    static func displayName(for keycode: String) -> String {
        let parts = displayParts(for: keycode)
        if parts.count <= 1 { return parts.first ?? keycode }
        let modifiers = parts.dropLast().joined(separator: " ")
        return "\(modifiers)\n\(parts.last!)"
    }

    /// Recursively unwraps modifier prefixes, returning each label as a separate element.
    private static func displayParts(for keycode: String) -> [String] {
        if let mapped = keycodeMap[keycode] {
            return [mapped]
        }

        if let parenStart = keycode.firstIndex(of: "("),
           keycode.last == ")" {
            let prefix = String(keycode[keycode.startIndex..<parenStart])
            let inner = String(keycode[keycode.index(after: parenStart)..<keycode.index(before: keycode.endIndex)])

            if let mod = modifierPrefixes.first(where: { $0.prefix == prefix }) {
                return [mod.label] + displayParts(for: inner)
            }
        }

        if keycode.count == 1 && keycode.first!.isLetter {
            return [keycode.uppercased()]
        }

        return [keycode]
    }

    // MARK: - Persistence

    private static let storageKey = "keyboardLayoutData"

    static func save(_ layoutData: KeyboardLayoutData) {
        if let data = try? JSONEncoder().encode(layoutData) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func load() -> KeyboardLayoutData? {
        // Try UserDefaults first (user-imported layout)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let layout = try? JSONDecoder().decode(KeyboardLayoutData.self, from: data) {
            return layout
        }
        // Fall back to bundled default layout
        return loadBundledDefault()
    }

    static func loadBundledDefault() -> KeyboardLayoutData? {
        guard let keymapURL = Bundle.main.url(forResource: "splitkb_aurora_sweep", withExtension: "keymap") else {
            print("[KeymapParser] Bundled .keymap not found in bundle")
            print("[KeymapParser] Bundle path: \(Bundle.main.bundlePath)")
            return nil
        }
        guard let jsonURL = Bundle.main.url(forResource: "splitkb_aurora_sweep", withExtension: "json") else {
            print("[KeymapParser] Bundled .json not found in bundle")
            return nil
        }
        print("[KeymapParser] Loading from bundle: \(keymapURL.path)")
        do {
            let result = try parse(keymapURL: keymapURL, jsonURL: jsonURL)
            print("[KeymapParser] Parsed \(result.physicalKeys.count) keys, \(result.layers.count) layers")
            return result
        } catch {
            print("[KeymapParser] Parse error: \(error)")
            return nil
        }
    }

    // MARK: - Errors

    enum ParseError: LocalizedError {
        case keymapBlockNotFound
        case jsonDecodingFailed

        var errorDescription: String? {
            switch self {
            case .keymapBlockNotFound: return "Could not find 'keymap { }' block in the .keymap file."
            case .jsonDecodingFailed: return "Failed to decode physical layout from JSON file."
            }
        }
    }
}
