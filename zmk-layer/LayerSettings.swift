//
//  LayerSettings.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import Foundation

struct LayerConfig: Codable, Identifiable {
    var id: UInt8 { index }
    let index: UInt8
    var name: String
    var emoji: String
}

@Observable
final class LayerSettings {

    static let shared = LayerSettings()

    var layers: [LayerConfig] {
        didSet { save() }
    }

    private static let defaultLayers: [LayerConfig] = [
        LayerConfig(index: 0, name: "Base", emoji: ""),
        LayerConfig(index: 1, name: "Lower", emoji: ""),
        LayerConfig(index: 2, name: "Raise", emoji: ""),
        LayerConfig(index: 3, name: "Adjust", emoji: ""),
        LayerConfig(index: 4, name: "Nav", emoji: ""),
        LayerConfig(index: 5, name: "Num", emoji: ""),
        LayerConfig(index: 6, name: "Sym", emoji: ""),
        LayerConfig(index: 7, name: "Fun", emoji: ""),
    ]

    var showOnlyWhenLocked: Bool {
        didSet { UserDefaults.standard.set(showOnlyWhenLocked, forKey: Self.lockedOnlyKey) }
    }

    private static let storageKey = "layerConfigs"
    private static let lockedOnlyKey = "showOnlyWhenLocked"

    private init() {
        self.showOnlyWhenLocked = UserDefaults.standard.bool(forKey: Self.lockedOnlyKey)
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([LayerConfig].self, from: data) {
            self.layers = decoded
        } else {
            self.layers = Self.defaultLayers
        }
    }

    func displayName(for index: UInt8) -> String {
        let config = layers.first { $0.index == index }
        let name = config?.name ?? "Layer \(index)"
        let emoji = config?.emoji ?? ""
        return emoji.isEmpty ? name : "\(emoji) \(name)"
    }

    func addLayer() {
        let nextIndex = (layers.map(\.index).max() ?? 0) + 1
        layers.append(LayerConfig(index: nextIndex, name: "Layer \(nextIndex)", emoji: ""))
    }

    func removeLayer(at index: Int) {
        guard layers.indices.contains(index) else { return }
        layers.remove(at: index)
    }

    func resetToDefaults() {
        layers = Self.defaultLayers
    }

    private func save() {
        if let data = try? JSONEncoder().encode(layers) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
