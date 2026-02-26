//
//  HIDManager.swift
//  zmk-layer
//
//  Created by Piotr Filipp on 26/02/2026.
//

import Foundation
import IOKit
import IOKit.hid

/// Manages the connection to a ZMK keyboard via IOKit HID,
/// listening for custom Report ID 0x04 that carries layer state.
@Observable
final class HIDManager {

    // MARK: - Published State

    var currentLayer: UInt8 = 0
    var isLocked: Bool = false
    var isConnected: Bool = false
    var deviceName: String = "No device"

    // MARK: - Private

    private var manager: IOHIDManager?

    // MARK: - Lifecycle

    init() {
        setupHIDManager()
    }

    deinit {
        if let manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    // MARK: - Setup

    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager

        // Match HID keyboards (Generic Desktop / Keyboard)
        let matching: [[String: Any]] = [
            [
                kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard
            ]
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)

        // Register callbacks — C function pointers with `self` passed as context.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(manager, hidDeviceMatchedCallback, selfPtr)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, hidDeviceRemovedCallback, selfPtr)
        IOHIDManagerRegisterInputReportCallback(manager, hidInputReportCallback, selfPtr)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            print("[HIDManager] Failed to open HID manager: \(result)")
        }
    }

    // MARK: - State Updates (called from callbacks)

    fileprivate func handleDeviceConnected(name: String) {
        isConnected = true
        deviceName = name
        print("[HIDManager] Device connected: \(name)")
    }

    fileprivate func handleDeviceRemoved(name: String) {
        isConnected = false
        deviceName = "No device"
        currentLayer = 0
        isLocked = false
        print("[HIDManager] Device removed: \(name)")
    }

    fileprivate func handleReport(layer: UInt8, locked: Bool) {
        print("[HIDManager] Layer: \(layer), locked: \(locked)")
        currentLayer = layer
        isLocked = locked
    }
}

// MARK: - C Callbacks

/// These must be nonisolated free functions to serve as C function pointers.
/// Since the HID manager is scheduled on CFRunLoopGetMain(), these execute on the main thread,
/// making MainActor.assumeIsolated safe.

nonisolated private func hidDeviceMatchedCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown device"

    MainActor.assumeIsolated {
        let mgr = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
        mgr.handleDeviceConnected(name: name)
    }
}

nonisolated private func hidDeviceRemovedCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown device"

    MainActor.assumeIsolated {
        let mgr = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
        mgr.handleDeviceRemoved(name: name)
    }
}

nonisolated private func hidInputReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    // Only process our custom ZMK layer report (Report ID 0x04)
    guard reportID == 0x04, reportLength >= 3 else { return }
    guard let context else { return }

    let layer = report[1]
    let locked = report[2] != 0

    MainActor.assumeIsolated {
        let mgr = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
        mgr.handleReport(layer: layer, locked: locked)
    }
}
