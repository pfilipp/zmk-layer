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
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = OverlayWindowController(hidManager: SharedHIDManager.shared)
        self.overlayController = controller
        controller.showOverlay()
    }
}

// MARK: - Shared HID Manager

/// Singleton so both the menu bar popover and the overlay panel observe the same HID state.
enum SharedHIDManager {
    static let shared = HIDManager()
}
