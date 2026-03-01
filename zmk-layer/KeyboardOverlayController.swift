//
//  KeyboardOverlayController.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 27/02/2026.
//

import SwiftUI
import AppKit

// MARK: - Keyboard Overlay Controller

final class KeyboardOverlayController {

    private var panel: OverlayPanel?
    private let hidManager: HIDManager
    private(set) var isShown = false

    init(hidManager: HIDManager) {
        self.hidManager = hidManager
    }

    func toggle() {
        if isShown {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard KeymapParser.load() != nil else { return }

        if panel == nil {
            createPanel()
        }
        panel?.orderFrontRegardless()
        panel?.ignoresMouseEvents = true
        isShown = true
    }

    func hide() {
        panel?.orderOut(nil)
        isShown = false
    }

    func reloadLayout() {
        panel?.orderOut(nil)
        panel = nil
        if isShown {
            show()
        }
    }

    // MARK: - Panel Creation

    private func createPanel() {
        guard let layoutData = KeymapParser.load() else { return }

        let rootView = KeyboardOverlayContentWrapper(hidManager: hidManager)
        let hostingView = NSHostingView(rootView: rootView)

        // Calculate panel size from layout data
        let unit: CGFloat = 48  // keySize (44) + gap (4)
        let maxX = layoutData.physicalKeys.map(\.physical.x).max() ?? 0
        let maxY = layoutData.physicalKeys.map(\.physical.y).max() ?? 0
        let padding: CGFloat = 20
        let headerHeight: CGFloat = 20
        let headerSpacing: CGFloat = 12
        let panelWidth = (maxX + 1) * unit + padding * 2
        let panelHeight = (maxY + 1) * unit + headerHeight + headerSpacing + padding * 2

        let panelSize = NSSize(width: ceil(panelWidth), height: ceil(panelHeight))

        let panel = OverlayPanel(contentRect: NSRect(origin: .zero, size: panelSize))
        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        panel.contentView = hostingView

        positionPanel(panel, size: panelSize)
        self.panel = panel
    }

    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY - size.height / 2

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - SwiftUI Wrapper

struct KeyboardOverlayContentWrapper: View {

    let hidManager: HIDManager

    var body: some View {
        if let layoutData = KeymapParser.load() {
            KeyboardLayoutView(
                layoutData: layoutData,
                layerIndex: Int(hidManager.currentLayer),
                layerName: LayerSettings.shared.displayName(for: hidManager.currentLayer)
            )
            .fixedSize()
        } else {
            Text("No layout imported")
                .foregroundStyle(.white.opacity(0.5))
                .padding(40)
        }
    }
}
