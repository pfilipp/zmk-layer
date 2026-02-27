//
//  KeyboardOverlay.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 27/02/2026.
//

import SwiftUI

// MARK: - Single Key View

struct KeyView: View {

    let label: KeyLabel
    let keySize: CGFloat

    private var fontSize: CGFloat {
        let longestLine = label.tap.components(separatedBy: "\n")
            .max(by: { $0.count < $1.count })?.count ?? 0
        if longestLine <= 1 { return keySize * 0.45 }
        if longestLine <= 3 { return keySize * 0.35 }
        if longestLine <= 5 { return keySize * 0.25 }
        return keySize * 0.2
    }

    // Okabe-Ito colorblind-safe palette
    fileprivate static let skyBlue = Color(red: 0.34, green: 0.71, blue: 0.91)
    fileprivate static let orange = Color(red: 0.90, green: 0.62, blue: 0.0)
    fileprivate static let bluishGreen = Color(red: 0.0, green: 0.62, blue: 0.45)

    private var holdTextColor: Color {
        Self.skyBlue
    }

    private var tapStyledText: AttributedString {
        if label.isTransparent {
            var s = AttributedString("\u{25BD}")
            s.foregroundColor = .white.opacity(0.2)
            return s
        }
        if label.isSticky {
            var s = AttributedString(label.tap)
            s.foregroundColor = Self.bluishGreen
            return s
        }
        if label.isModifierWrapped {
            let lines = label.tap.components(separatedBy: "\n")
            if lines.count > 1 {
                var result = AttributedString(lines.dropLast().joined(separator: " ") + "\n")
                result.foregroundColor = Self.orange
                var key = AttributedString(lines.last!)
                key.foregroundColor = .white
                result.append(key)
                return result
            }
            var s = AttributedString(label.tap)
            s.foregroundColor = Self.orange
            return s
        }
        var s = AttributedString(label.tap)
        s.foregroundColor = .white
        return s
    }

    var body: some View {
        if label.isNone {
            Color.clear
                .frame(width: keySize, height: keySize)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: keySize * 0.15)
                    .fill(label.isTransparent
                          ? Color.white.opacity(0.03)
                          : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: keySize * 0.15)
                            .strokeBorder(
                                label.isTransparent
                                    ? Color.white.opacity(0.05)
                                    : Color.white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )

                VStack(spacing: 1) {
                    if let hold = label.hold {
                        Text(hold)
                            .font(.system(size: keySize * 0.18, weight: .regular, design: .rounded))
                            .foregroundStyle(holdTextColor.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Text(tapStyledText)
                        .font(.system(size: fontSize, weight: .medium, design: .rounded))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                }
                .padding(2)
            }
            .frame(width: keySize, height: keySize)
        }
    }
}

// MARK: - Full Keyboard Layout

struct KeyboardLayoutView: View {

    let layoutData: KeyboardLayoutData
    let layerIndex: Int
    let layerName: String

    private let keySize: CGFloat = 44
    private let gap: CGFloat = 4

    private var currentLayer: ParsedLayer? {
        guard layerIndex < layoutData.layers.count else { return nil }
        return layoutData.layers[layerIndex]
    }

    var body: some View {
        let labels = currentLayer?.keys ?? []
        let unit = keySize + gap
        let maxX = layoutData.physicalKeys.map(\.physical.x).max() ?? 0
        let maxY = layoutData.physicalKeys.map(\.physical.y).max() ?? 0
        let totalWidth = (maxX + 1) * unit
        let totalHeight = (maxY + 1) * unit

        VStack(spacing: 12) {
            // Layer name header
            Text(layerName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            // All keys in a single absolute-positioned ZStack
            ZStack {
                Color.clear.frame(width: totalWidth, height: totalHeight)

                ForEach(Array(layoutData.physicalKeys.enumerated()), id: \.offset) { i, key in
                    let label = i < labels.count
                        ? labels[i]
                        : KeyLabel(tap: "?", hold: nil, isTransparent: false, isNone: false)

                    KeyView(label: label, keySize: keySize)
                        .position(
                            x: key.physical.x * unit + keySize / 2,
                            y: key.physical.y * unit + keySize / 2
                        )
                }
            }

            // Legend
            HStack(spacing: 12) {
                legendItem(color: KeyView.skyBlue, text: "Tap-hold")
                legendItem(color: KeyView.orange, text: "Modifier")
                legendItem(color: KeyView.bluishGreen, text: "Sticky")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.55))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .animation(.spring(duration: 0.35, bounce: 0.25), value: layerIndex)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
