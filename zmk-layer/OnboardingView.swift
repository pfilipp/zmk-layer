import SwiftUI
import IOKit
import IOKit.hid
import UniformTypeIdentifiers

struct OnboardingView: View {
    let state: OnboardingState
    var onComplete: (() -> Void)?

    @State private var isInputMonitoringGranted = false
    @State private var permissionTimer: Timer?
    @State private var importedLayout: KeyboardLayoutData?
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)

            Divider()

            navigationBar
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .onAppear {
            checkInputMonitoringPermission()
        }
        .onDisappear {
            permissionTimer?.invalidate()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case .welcome:          welcomeStep
        case .inputMonitoring:  inputMonitoringStep
        case .importLayout:     importLayoutStep
        case .complete:         completeStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            Text("Welcome to ZMK Layer Monitor")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Monitor your ZMK keyboard's active layer in real time and display a layout overlay on screen. A quick setup is needed to get started.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var inputMonitoringStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Input Monitoring Permission")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Required to read HID reports from your ZMK keyboard. Without this, the app cannot detect layer changes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if isInputMonitoringGranted {
                Label("Permission Enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
            } else {
                VStack(spacing: 12) {
                    Button("Open Input Monitoring Settings") {
                        openInputMonitoringSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Add ZMK Layer Monitor to the list, then the app will detect the change automatically.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var importLayoutStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Import Keyboard Layout")
                .font(.title2)
                .fontWeight(.semibold)

            Text("A .keymap file is needed to display your keybindings. You can also import later from Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let layout = importedLayout {
                Label("\(layout.physicalKeys.count) keys, \(layout.layers.count) layers", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
            } else {
                VStack(spacing: 12) {
                    if let error = importError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Import Layout\u{2026}") {
                        importKeymapFile()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("ZMK Layer Monitor lives in your menu bar. Use the keyboard shortcut to toggle the layout overlay on screen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Input Monitoring

    private func checkInputMonitoringPermission() {
        isInputMonitoringGranted = isInputMonitoringEnabled()

        if state.currentStep == .inputMonitoring && isInputMonitoringGranted {
            state.advance()
            return
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            let granted = isInputMonitoringEnabled()
            isInputMonitoringGranted = granted
            if granted && state.currentStep == .inputMonitoring {
                permissionTimer?.invalidate()
                permissionTimer = nil
                state.advance()
            }
        }
    }

    private func isInputMonitoringEnabled() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatchingMultiple(manager, nil)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return result == kIOReturnSuccess
    }

    private func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Import Layout

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
        } catch {
            importError = error.localizedDescription
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            stepDots

            Spacer()

            HStack(spacing: 12) {
                skipButton
                primaryButton
            }
        }
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(OnboardingState.Step.allCases.enumerated()), id: \.element) { index, step in
                Circle()
                    .fill(step == state.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
                    .accessibilityLabel("Step \(index + 1) of \(OnboardingState.Step.allCases.count)")
            }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        let showSkip: Bool = switch state.currentStep {
        case .inputMonitoring: !isInputMonitoringGranted
        case .importLayout:    importedLayout == nil
        default:               false
        }

        if showSkip {
            Button("Skip") { state.advance() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch state.currentStep {
        case .welcome:
            Button("Continue") { state.advance() }
                .buttonStyle(.borderedProminent)
        case .inputMonitoring:
            if isInputMonitoringGranted {
                Button("Continue") { state.advance() }
                    .buttonStyle(.borderedProminent)
            }
        case .importLayout:
            if importedLayout != nil {
                Button("Continue") { state.advance() }
                    .buttonStyle(.borderedProminent)
            }
        case .complete:
            Button("Get Started") {
                OnboardingState.markOnboardingComplete()
                onComplete?()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
