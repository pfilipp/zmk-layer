//
//  ContentView.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// Menu bar popover content showing device status, layer editor, and controls.
struct ContentView: View {

    let hidManager: HIDManager

    @State private var importedLayout: KeyboardLayoutData? = KeymapParser.load()
    @State private var importError: String?

    private var layerDisplayName: String {
        LayerSettings.shared.displayName(for: hidManager.currentLayer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Connection status
            HStack(spacing: 8) {
                Circle()
                    .fill(hidManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(hidManager.isConnected ? "Connected" : "Disconnected")
                    .font(.headline)
            }

            if hidManager.isConnected {
                // Device name
                LabeledContent("Device") {
                    Text(hidManager.deviceName)
                        .foregroundStyle(.secondary)
                }

                // Current layer
                LabeledContent("Layer") {
                    Text(layerDisplayName)
                        .foregroundStyle(.secondary)
                }

                // Lock state
                LabeledContent("Locked") {
                    HStack(spacing: 4) {
                        Image(systemName: hidManager.isLocked ? "lock.fill" : "lock.open")
                        Text(hidManager.isLocked ? "Yes" : "No")
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Connect a ZMK keyboard to see layer info.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Layer editor
            DisclosureGroup("Layers") {
                VStack(spacing: 6) {
                    ForEach(Array(LayerSettings.shared.layers.enumerated()), id: \.element.id) { arrayIndex, config in
                        HStack(spacing: 6) {
                            Text("\(config.index)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 16, alignment: .trailing)

                            TextField("Name", text: binding(for: arrayIndex, keyPath: \.name))
                                .textFieldStyle(.roundedBorder)

                            Button {
                                LayerSettings.shared.removeLayer(at: arrayIndex)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Button {
                            LayerSettings.shared.addLayer()
                        } label: {
                            Label("Add Layer", systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button("Reset") {
                            LayerSettings.shared.resetToDefaults()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            Toggle("Show only when locked", isOn: Binding(
                get: { LayerSettings.shared.showOnlyWhenLocked },
                set: { LayerSettings.shared.showOnlyWhenLocked = $0 }
            ))
            .font(.caption)

            Toggle("Show momentary from locked", isOn: Binding(
                get: { LayerSettings.shared.showMomentaryFromLocked },
                set: { LayerSettings.shared.showMomentaryFromLocked = $0 }
            ))
            .font(.caption)
            .disabled(!LayerSettings.shared.showOnlyWhenLocked)
            .padding(.leading, 16)

            Divider()

            // Keyboard layout section
            DisclosureGroup("Keyboard Layout") {
                VStack(alignment: .leading, spacing: 8) {
                    if let layout = importedLayout {
                        Text("\(layout.physicalKeys.count) keys, \(layout.layers.count) layers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let error = importError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 8) {
                        Button("Import Layout") {
                            importKeymapFile()
                        }
                        .font(.caption)

                        if importedLayout != nil {
                            Button("Show Layout") {
                                toggleKeyboardOverlay()
                            }
                            .font(.caption)
                        }
                    }

                    LabeledContent("Toggle Layout") {
                        ShortcutRecorderView(keyCombo: Binding(
                            get: { SharedHotkeySettings.shared.overlayShortcut },
                            set: { SharedHotkeySettings.shared.overlayShortcut = $0 }
                        ))
                    }
                    .font(.caption)
                }
                .padding(.top, 4)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    private func importKeymapFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "keymap")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a .keymap file"

        guard panel.runModal() == .OK, let keymapURL = panel.url else { return }

        // Look for matching .json in the same directory
        let directory = keymapURL.deletingLastPathComponent()
        let stem = keymapURL.deletingPathExtension().lastPathComponent
        let jsonURL = directory.appendingPathComponent(stem + ".json")

        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            importError = "Could not find \(stem).json in the same directory."
            return
        }

        do {
            let layoutData = try KeymapParser.parse(keymapURL: keymapURL, jsonURL: jsonURL)
            KeymapParser.save(layoutData)
            importedLayout = layoutData
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
    }

    private func toggleKeyboardOverlay() {
        SharedKeyboardOverlay.shared.toggle()
    }

    private func binding(for index: Int, keyPath: WritableKeyPath<LayerConfig, String>) -> Binding<String> {
        Binding(
            get: {
                guard LayerSettings.shared.layers.indices.contains(index) else { return "" }
                return LayerSettings.shared.layers[index][keyPath: keyPath]
            },
            set: { newValue in
                guard LayerSettings.shared.layers.indices.contains(index) else { return }
                LayerSettings.shared.layers[index][keyPath: keyPath] = newValue
            }
        )
    }
}
