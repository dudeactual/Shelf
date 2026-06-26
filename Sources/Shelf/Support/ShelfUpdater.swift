import AppKit
import SwiftUI

final class ShelfUpdater {
    static let latestReleaseURL = URL(string: "https://github.com/dudeactual/Shelf/releases/latest")!

    func checkForUpdates() {
        NSWorkspace.shared.open(Self.latestReleaseURL)
    }
}

struct CheckForUpdatesButton: View {
    let updater: ShelfUpdater

    var body: some View {
        Button {
            updater.checkForUpdates()
        } label: {
            Label("Check for Updates", systemImage: "arrow.down.circle")
        }
        .help("Open Shelf’s latest GitHub release")
    }
}
