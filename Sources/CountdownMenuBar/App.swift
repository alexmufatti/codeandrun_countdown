import SwiftUI
import AppKit
import Combine

/// SwiftUI's `MenuBarExtra` always shows its content window on any click, with no
/// way to tell left- from right-click before that happens — so cycling the label
/// with a left click can't coexist with opening the dropdown. Managing the
/// `NSStatusItem` directly lets us route left clicks to cycling and right clicks
/// (or the equivalent) to the dropdown.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: CountdownStore!
    private var tickTimer: Timer?
    private var storeSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        closeStrayWindows()

        let store = CountdownStore()
        self.store = store

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView().environmentObject(store)
        )
        self.popover = popover

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.target = self
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item

        updateLabel()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateLabel() }
        }
        storeSubscription = store.objectWillChange.sink { [weak self] _ in
            // objectWillChange fires before the change is applied; hop to the next
            // run loop turn so updateLabel reads the store's already-updated state.
            DispatchQueue.main.async { self?.updateLabel() }
        }
    }

    @objc @MainActor private func statusItemClicked(_ sender: NSStatusBarButton) {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
            || NSApp.currentEvent?.modifierFlags.contains(.control) == true
        if isRightClick {
            showMenu()
        } else {
            store.cycleDisplay()
            updateLabel()
        }
    }

    /// SwiftUI can restore/auto-present the app's only Scene (our empty
    /// Settings placeholder) at launch via window-state restoration, showing
    /// a blank "Countdown Settings" window. Close it immediately, and once
    /// more on the next run loop turn in case the scene finishes setting up
    /// after this method returns.
    private func closeStrayWindows() {
        let closeStray = {
            // Exclude the status-bar item's own backing window, which also
            // shows up in NSApp.windows — closing it would kill the menu
            // bar icon's click handling.
            NSApp.windows
                .filter { $0.level != .statusBar }
                .forEach { $0.close() }
        }
        closeStray()
        DispatchQueue.main.async(execute: closeStray)
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @MainActor private func updateLabel() {
        guard let button = statusItem.button else { return }
        guard let countdown = store.displayed else {
            button.title = "–"
            button.toolTip = nil
            return
        }
        button.title = "\(countdown.menuBarLabel) \(countdown.displayString())"
        button.toolTip = countdown.title
    }
}

@main
struct CountdownMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Empty placeholder: the app is accessory-only and has no real
        // settings UI, but SwiftUI's App protocol requires at least one
        // Scene. Strip the default Cmd+, command so this window never
        // opens on its own.
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) { }
        }
    }
}
