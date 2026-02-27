import SwiftUI
import AppKit

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.keyCombo = keyCombo
        view.onKeyComboChanged = { newCombo in
            keyCombo = newCombo
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.keyCombo = keyCombo
        nsView.needsDisplay = true
    }
}

final class KeyCaptureView: NSView {
    var keyCombo = KeyCombo.defaultOverlay
    var onKeyComboChanged: ((KeyCombo) -> Void)?

    private var isRecording = false
    private var trackingArea: NSTrackingArea?
    private var isHovered = false

    override var acceptsFirstResponder: Bool { true }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 140, height: 28)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            isRecording = true
            window?.makeFirstResponder(self)
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 { // Escape
            isRecording = false
            needsDisplay = true
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !modifiers.isEmpty else { return }

        let newCombo = KeyCombo(keyCode: event.keyCode, modifiers: modifiers)
        keyCombo = newCombo
        isRecording = false
        needsDisplay = true
        onKeyComboChanged?(newCombo)
    }

    override func flagsChanged(with event: NSEvent) {
        if isRecording { return }
        super.flagsChanged(with: event)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)

        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.1).setFill()
        } else if isHovered {
            NSColor.quaternaryLabelColor.setFill()
        } else {
            NSColor.controlBackgroundColor.setFill()
        }
        path.fill()

        if isRecording {
            NSColor.controlAccentColor.setStroke()
        } else {
            NSColor.separatorColor.setStroke()
        }
        path.lineWidth = 1
        path.stroke()

        let text = isRecording ? "Press shortcut…" : keyCombo.displayString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: isRecording ? .regular : .medium),
            .foregroundColor: isRecording ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let textSize = attrStr.size()
        let textRect = CGRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attrStr.draw(in: textRect)
    }
}
