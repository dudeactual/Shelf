import AppKit
import ShelfCore
import SwiftUI

final class ShelfAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct ShelfApp: App {
    @NSApplicationDelegateAdaptor(ShelfAppDelegate.self) private var appDelegate
    @StateObject private var store = ShelfStore()
    private let updater = ShelfUpdater()

    var body: some Scene {
        WindowGroup("Shelf", id: "main") {
            ContentView(store: store, updater: updater)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 760, height: 560)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updater)
            }

            CommandGroup(after: .newItem) {
                Button("Open Shelf Folder") {
                    store.openShelfFolder()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("Shelf", systemImage: "tray.full") {
            ShelfMenu(store: store, updater: updater)
        }
    }
}

private struct ShelfMenu: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var store: ShelfStore
    let updater: ShelfUpdater

    var body: some View {
        Button("Open Shelf") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Open Shelf Folder") {
            store.openShelfFolder()
        }

        CheckForUpdatesButton(updater: updater)

        if !store.filteredItems.isEmpty {
            Divider()
            ForEach(store.filteredItems.prefix(5)) { item in
                Button(shortTitle(item.title)) {
                    store.open(item)
                }
            }
        }

        Divider()
        Button("Quit Shelf") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func shortTitle(_ value: String) -> String {
        value.count <= 30 ? value : String(value.prefix(27)) + "…"
    }
}
