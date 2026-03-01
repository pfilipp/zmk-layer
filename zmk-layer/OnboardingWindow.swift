import AppKit
import SwiftUI

final class OnboardingWindow: NSWindow {
    var onComplete: (() -> Void)?

    private let onboardingState = OnboardingState()
    private var hasCompleted = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = ""
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        center()

        let view = OnboardingView(
            state: onboardingState,
            onComplete: { [weak self] in self?.close() }
        )
        contentView = NSHostingView(rootView: view)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func close() {
        guard !hasCompleted else { return }
        hasCompleted = true
        orderOut(nil)
        onComplete?()
    }
}
