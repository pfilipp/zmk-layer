//
//  LayerOverlay.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import SwiftUI
import AppKit

// MARK: - Overlay Panel

/// A non-activating floating panel that sits above all windows and ignores mouse events.
final class OverlayPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        hasShadow = false
    }
}

// MARK: - Overlay View

/// The floating pill overlay that shows the current layer name and optional lock indicator.
struct LayerOverlayView: View {

    let layer: UInt8
    let isLocked: Bool
    let isVisible: Bool

    private var layerDisplayName: String {
        LayerSettings.shared.displayName(for: layer)
    }

    var body: some View {
        HStack(spacing: 4) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(layerDisplayName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .fixedSize()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .scaleEffect(isVisible ? 1.0 : 0.85)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: isVisible)
        .animation(.spring(duration: 0.3, bounce: 0.3), value: layer)
    }
}

// MARK: - Overlay Window Controller

/// Manages the overlay panel lifecycle and positioning.
final class OverlayWindowController {

    private var panel: OverlayPanel?
    private let hidManager: HIDManager

    init(hidManager: HIDManager) {
        self.hidManager = hidManager
    }

    func showOverlay() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFrontRegardless()
        panel?.ignoresMouseEvents = true
    }

    // MARK: - Panel Creation

    private func createPanel() {
        let panelSize = NSSize(width: 160, height: 40)
        let panel = OverlayPanel(contentRect: NSRect(origin: .zero, size: panelSize))

        let hostingView = NSHostingView(
            rootView: OverlayContentWrapper(hidManager: hidManager)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        panel.contentView = hostingView

        positionPanel(panel, size: panelSize)
        self.panel = panel
    }

    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let padding: CGFloat = 12

        let x = visibleFrame.maxX - size.width - padding
        let y = visibleFrame.maxY - size.height - padding

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - SwiftUI Wrapper (bridges controller visibility state into SwiftUI)

/// A small wrapper that observes both the HIDManager and the controller's visibility flag.
struct OverlayContentWrapper: View {

    let hidManager: HIDManager

    @State private var isVisible = false
    @State private var showBump = false
    @State private var hideTask: Task<Void, Never>?
    @State private var hasReceivedNonZeroLayer = false

    var body: some View {
        LayerOverlayView(
            layer: hidManager.currentLayer,
            isLocked: hidManager.isLocked,
            isVisible: isVisible
        )
        .scaleEffect(showBump ? 1.08 : 1.0)
        .animation(.spring(duration: 0.2, bounce: 0.4), value: showBump)
        .onChange(of: hidManager.currentLayer) { oldValue, newValue in
            handleLayerChange(from: oldValue, to: newValue)
        }
        .onChange(of: hidManager.isLocked) { _, locked in
            guard LayerSettings.shared.showOnlyWhenLocked else { return }
            if locked && hidManager.currentLayer != 0 {
                withAnimation { isVisible = true }
            } else if !locked && !(LayerSettings.shared.showMomentaryFromLocked && hidManager.isMomentaryFromLocked) {
                withAnimation { isVisible = false }
            }
        }
        .onChange(of: hidManager.isMomentaryFromLocked) { _, momentary in
            guard LayerSettings.shared.showOnlyWhenLocked,
                  LayerSettings.shared.showMomentaryFromLocked else { return }
            // When momentary ends and we return to a locked layer, isLocked handles visibility.
            // When momentary starts, ensure overlay stays visible.
            if momentary {
                withAnimation { isVisible = true }
            }
        }
        .onChange(of: hidManager.isConnected) { _, connected in
            if !connected {
                withAnimation { isVisible = false }
                hasReceivedNonZeroLayer = false
            }
        }
    }

    private func handleLayerChange(from oldLayer: UInt8, to newLayer: UInt8) {
        hideTask?.cancel()
        hideTask = nil

        // Brief scale bump on layer change
        showBump = true
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            showBump = false
        }

        let lockedOnly = LayerSettings.shared.showOnlyWhenLocked

        if newLayer == 0 {
            // Don't show overlay if we've never left the base layer
            guard hasReceivedNonZeroLayer else { return }

            // Base layer: show briefly then fade out
            if !lockedOnly {
                withAnimation { isVisible = true }
            }
            hideTask = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation { isVisible = false }
            }
        } else {
            hasReceivedNonZeroLayer = true
            if lockedOnly && !hidManager.isLocked
                && !(LayerSettings.shared.showMomentaryFromLocked && hidManager.isMomentaryFromLocked) {
                withAnimation { isVisible = false }
            } else {
                withAnimation { isVisible = true }
            }
        }
    }
}
