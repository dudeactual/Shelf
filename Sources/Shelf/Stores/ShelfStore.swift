import AppKit
import Combine
import Foundation
import ShelfCore

@MainActor
final class ShelfStore: ObservableObject {
    struct LinkRetentionOption: Identifiable, Hashable {
        let days: Int
        let title: String

        var id: Int { days }
    }

    static let linkRetentionOptions = [
        LinkRetentionOption(days: 1, title: "1 day"),
        LinkRetentionOption(days: 7, title: "7 days"),
        LinkRetentionOption(days: 30, title: "30 days"),
        LinkRetentionOption(days: 90, title: "90 days"),
        LinkRetentionOption(days: 0, title: "Forever")
    ]

    @Published private(set) var items: [ShelfItem] = []
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published private(set) var linkRetentionDays: Int

    private let retentionKey = "linkRetentionDays"

    let storage: ShelfStorage

    var filteredItems: [ShelfItem] {
        let sorted = items.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.createdAt > $1.createdAt
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.filename.localizedCaseInsensitiveContains(searchText)
        }
    }

    var linkRetentionTitle: String {
        Self.linkRetentionOptions.first { $0.days == linkRetentionDays }?.title ?? "30 days"
    }

    var linkRetentionSummary: String {
        linkRetentionDays == 0 ? "links stay forever" : "clears in \(linkRetentionTitle)"
    }

    init(storage: ShelfStorage = ShelfStorage()) {
        self.storage = storage
        if UserDefaults.standard.object(forKey: retentionKey) == nil {
            linkRetentionDays = 30
        } else {
            linkRetentionDays = UserDefaults.standard.integer(forKey: retentionKey)
        }
        reload()
    }

    func reload() {
        do {
            items = try storage.loadItems()
            removeExpiredLinks()
        } catch {
            show(error)
        }
    }

    func addLink(_ value: String) -> Bool {
        do {
            try append(storage.saveLink(value))
            return true
        } catch {
            show(error)
            return false
        }
    }

    func addNote(_ value: String) {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            try append(storage.saveNote(value))
        } catch {
            show(error)
        }
    }

    func importURL(_ url: URL) {
        do {
            if url.isFileURL {
                try append(storage.importFile(at: url))
            } else {
                try append(storage.saveLink(url.absoluteString))
            }
        } catch {
            show(error)
        }
    }

    func togglePin(_ item: ShelfItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        persist()
    }

    func removeFromShelf(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func setLinkRetention(days: Int) {
        linkRetentionDays = days
        UserDefaults.standard.set(days, forKey: retentionKey)
        removeExpiredLinks()
    }

    func open(_ item: ShelfItem) {
        if item.kind == .link,
           let value = storage.readText(for: item),
           let url = URL(string: value) {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(storage.itemURL(for: item))
        }
    }

    func reveal(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([storage.itemURL(for: item)])
    }

    func openShelfFolder() {
        do {
            try storage.prepare()
            NSWorkspace.shared.open(storage.rootURL)
        } catch {
            show(error)
        }
    }

    func retentionStatus(for item: ShelfItem, now: Date = Date()) -> String {
        guard item.kind == .link else { return "kept in Shelf folder" }
        guard !item.isPinned else { return "pinned" }
        guard linkRetentionDays > 0 else { return "saved forever" }
        guard let expirationDate = Calendar.current.date(
            byAdding: .day,
            value: linkRetentionDays,
            to: item.createdAt
        ) else {
            return "clears later"
        }

        let remaining = max(0, expirationDate.timeIntervalSince(now))
        if remaining < 60 * 60 {
            let minutes = max(1, Int(ceil(remaining / 60)))
            return "clears in \(minutes)m"
        }
        if remaining < 60 * 60 * 24 {
            let hours = max(1, Int(ceil(remaining / (60 * 60))))
            return "clears in \(hours)h"
        }

        let days = max(1, Int(ceil(remaining / (60 * 60 * 24))))
        return "clears in \(days)d"
    }

    private func append(_ item: ShelfItem) throws {
        items.append(item)
        do {
            try storage.saveItems(items)
        } catch {
            items.removeAll { $0.id == item.id }
            try? storage.delete(item)
            throw error
        }
    }

    private func persist() {
        do {
            try storage.saveItems(items)
        } catch {
            show(error)
        }
    }

    private func removeExpiredLinks(now: Date = Date()) {
        guard linkRetentionDays > 0,
              let cutoff = Calendar.current.date(
                byAdding: .day,
                value: -linkRetentionDays,
                to: now
              )
        else { return }

        let originalCount = items.count
        items.removeAll {
            $0.kind == .link && !$0.isPinned && $0.createdAt < cutoff
        }
        if items.count != originalCount {
            persist()
        }
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
