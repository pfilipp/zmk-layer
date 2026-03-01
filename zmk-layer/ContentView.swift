import SwiftUI

/// Minimal menu bar popover with key actions only.
struct ContentView: View {

    let hidManager: HIDManager

    @Environment(\.openSettings) private var openSettings
    @State private var hasLayout = KeymapParser.load() != nil
    @State private var layoutShown = SharedKeyboardOverlay.shared.isShown

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if hasLayout {
                Button(layoutShown ? "Hide Layout" : "Show Layout") {
                    SharedKeyboardOverlay.shared.toggle()
                    layoutShown = SharedKeyboardOverlay.shared.isShown
                }

                Divider()
            }

            Button("Settings\u{2026}") {
                openSettings()
                NSApp.activate()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(4)
        .onAppear {
            hasLayout = KeymapParser.load() != nil
            layoutShown = SharedKeyboardOverlay.shared.isShown
        }
    }
}
