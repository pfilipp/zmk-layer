import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    @State private var importedLayout: KeyboardLayoutData? = KeymapParser.load()
    @State private var importError: String?

    var body: some View {
        Form {

            // MARK: Layers

            Section("Layers") {
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

            // MARK: Display

            Section("Display") {
                Toggle("Show only when locked", isOn: Binding(
                    get: { LayerSettings.shared.showOnlyWhenLocked },
                    set: { LayerSettings.shared.showOnlyWhenLocked = $0 }
                ))

                Toggle("Show momentary from locked", isOn: Binding(
                    get: { LayerSettings.shared.showMomentaryFromLocked },
                    set: { LayerSettings.shared.showMomentaryFromLocked = $0 }
                ))
                .disabled(!LayerSettings.shared.showOnlyWhenLocked)
            }

            // MARK: Keyboard Layout

            Section("Keyboard Layout") {
                if let layout = importedLayout {
                    LabeledContent("Imported") {
                        Text("\(layout.physicalKeys.count) keys, \(layout.layers.count) layers")
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = importError {
                    Text(error)
                        .foregroundStyle(.red)
                }

                HStack(spacing: 8) {
                    Button("Import Layout\u{2026}") {
                        importKeymapFile()
                    }

                    if importedLayout != nil {
                        Button("Show Layout") {
                            SharedKeyboardOverlay.shared.toggle()
                        }
                    }
                }

                LabeledContent("Toggle Layout") {
                    ShortcutRecorderView(keyCombo: Binding(
                        get: { SharedHotkeySettings.shared.overlayShortcut },
                        set: { SharedHotkeySettings.shared.overlayShortcut = $0 }
                    ))
                }
            }

            // MARK: About

            Section {
                VStack(spacing: 4) {
                    Text("ZMK Layer Monitor")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "\u{00A9} \(Calendar.current.component(.year, from: Date())) Piotr Filipp")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link(destination: URL(string: "https://apps.filipp.tech")!) {
                        Text(verbatim: "apps.filipp.tech")
                    }
                    .font(.footnote)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 480)
    }

    // MARK: - Import

    private func importKeymapFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "keymap")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a .keymap file"

        guard panel.runModal() == .OK, let keymapURL = panel.url else { return }

        do {
            let layoutData = try KeymapParser.parse(keymapURL: keymapURL)
            KeymapParser.save(layoutData)
            importedLayout = layoutData
            importError = nil
            SharedKeyboardOverlay.shared.reloadLayout()
        } catch {
            importError = error.localizedDescription
        }
    }

    // MARK: - Binding Helper

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
