import AppKit
import SwiftUI

/// Presents the add/edit form in a plain AppKit window instead of a SwiftUI
/// WindowGroup/openWindow, which doesn't reliably open when the app runs as a
/// bare SwiftPM executable (no proper .app bundle) rather than an Xcode target.
@MainActor
final class AddEditWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = AddEditWindowPresenter()

    private var windows: [ObjectIdentifier: NSWindow] = [:]

    func present(editing: Countdown?, store: CountdownStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self

        let view = AddEditCountdownView(editing: editing, onDismiss: { [weak window] in
            window?.close()
        })
        .environmentObject(store)
        window.contentViewController = NSHostingController(rootView: view)
        // Assigning contentViewController resizes the window to the SwiftUI
        // content's fitting size, which can come back as zero before the view
        // has laid out — pin an explicit size and re-center afterwards.
        window.setContentSize(NSSize(width: 360, height: 380))
        window.center()

        windows[ObjectIdentifier(window)] = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows.removeValue(forKey: ObjectIdentifier(window))
    }
}
