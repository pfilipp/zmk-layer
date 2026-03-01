//
//  zmk_layerApp.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import SwiftUI

@main
struct zmk_layerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView(hidManager: SharedHIDManager.shared)
        } label: {
            Image(systemName: "keyboard")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var overlayController: OverlayWindowController?
    private let hotkeyService = HotkeyService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = OverlayWindowController(hidManager: SharedHIDManager.shared)
        self.overlayController = controller
        controller.showOverlay()

        setupHotkey()
    }

    private func setupHotkey() {
        let settings = SharedHotkeySettings.shared
        hotkeyService.onHotkeyPressed = {
            SharedKeyboardOverlay.shared.toggle()
        }
        settings.onShortcutChanged = { [weak self] in
            self?.hotkeyService.restart(settings: SharedHotkeySettings.shared)
        }
        hotkeyService.start(settings: settings)
    }

    @objc func toggleKeyboardOverlay() {
        SharedKeyboardOverlay.shared.toggle()
    }
}

// MARK: - Shared HID Manager

/// Singleton so both the menu bar popover and the overlay panel observe the same HID state.
enum SharedHIDManager {
    static let shared = HIDManager()
}

/// Singleton for the keyboard overlay so ContentView can toggle it without going through the delegate.
enum SharedKeyboardOverlay {
    static let shared = KeyboardOverlayController(hidManager: SharedHIDManager.shared)
}

/// Singleton for hotkey settings so both the popover and app delegate share the same instance.
enum SharedHotkeySettings {
    static let shared = HotkeySettings()
}
