import SwiftUI
import AppKit

/// Without any WindowGroup scene, SwiftUI leaves the app's activation policy
/// at .prohibited, which means it can never become the active application —
/// so the AppKit windows AddEditWindowPresenter creates never actually come
/// to the front. Force .accessory (menu-bar-only, but can still activate and
/// show windows) as soon as the app finishes launching.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct CountdownMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = CountdownStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Ticks on its own so the menu bar title stays live without redrawing the whole app.
private struct MenuBarLabel: View {
    @ObservedObject var store: CountdownStore
    @State private var now = Date()

    var body: some View {
        Text(label)
            .help(store.active?.title ?? "")
            .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { newNow in
                now = newNow
            }
    }

    private var label: String {
        guard let countdown = store.active else { return "–" }
        return "\(countdown.menuBarLabel) \(countdown.displayString(now: now))"
    }
}
