//
//  ContentView.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import SwiftUI

/// Menu bar popover content showing device status, layer editor, and controls.
struct ContentView: View {

    let hidManager: HIDManager

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

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 260)
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
