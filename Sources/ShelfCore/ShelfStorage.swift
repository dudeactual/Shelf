import Foundation

public struct ShelfStorage {
    public enum StorageError: LocalizedError {
        case invalidLink

        public var errorDescription: String? {
            switch self {
            case .invalidLink:
                "That doesn’t look like a web link."
            }
        }
    }

    public let rootURL: URL
    private let fileManager: FileManager
    private let indexName = ".shelf-index.json"

    public init(
        rootURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
            self.rootURL = documents.appendingPathComponent("Shelf", isDirectory: true)
        }
    }

    public func prepare() throws {
        try fileManager.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func loadItems() throws -> [ShelfItem] {
        try prepare()
        let indexURL = rootURL.appendingPathComponent(indexName)
        guard fileManager.fileExists(atPath: indexURL.path) else { return [] }
        let data = try Data(contentsOf: indexURL)
        return try JSONDecoder.shelf.decode([ShelfItem].self, from: data)
            .filter { fileManager.fileExists(atPath: itemURL(for: $0).path) }
    }

    public func saveItems(_ items: [ShelfItem]) throws {
        try prepare()
        let data = try JSONEncoder.shelf.encode(items)
        try data.write(to: rootURL.appendingPathComponent(indexName), options: .atomic)
    }

    public func importFile(at sourceURL: URL) throws -> ShelfItem {
        try prepare()
        let destination = uniqueURL(
            preferredName: sourceURL.lastPathComponent.isEmpty ? "Saved Item" : sourceURL.lastPathComponent
        )
        try fileManager.copyItem(at: sourceURL, to: destination)
        return ShelfItem(
            kind: .file,
            title: sourceURL.deletingPathExtension().lastPathComponent,
            filename: destination.lastPathComponent
        )
    }

    public func saveLink(_ rawValue: String) throws -> ShelfItem {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme)
        else {
            throw StorageError.invalidLink
        }

        try prepare()
        let host = url.host(percentEncoded: false) ?? "Link"
        let title = host.replacingOccurrences(of: "www.", with: "")
        let destination = uniqueURL(preferredName: "\(safeName(title))-link.txt")
        try (trimmed + "\n").write(to: destination, atomically: true, encoding: .utf8)

        return ShelfItem(kind: .link, title: title, filename: destination.lastPathComponent)
    }

    public func saveNote(_ text: String) throws -> ShelfItem {
        try prepare()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.split(separator: "\n").first.map(String.init) ?? "Note"
        let title = String(firstLine.prefix(60))
        let destination = uniqueURL(preferredName: "\(safeName(title))-note.txt")
        try (trimmed + "\n").write(to: destination, atomically: true, encoding: .utf8)
        return ShelfItem(kind: .note, title: title, filename: destination.lastPathComponent)
    }

    public func delete(_ item: ShelfItem) throws {
        let url = itemURL(for: item)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    public func itemURL(for item: ShelfItem) -> URL {
        rootURL.appendingPathComponent(item.filename)
    }

    public func readText(for item: ShelfItem) -> String? {
        guard item.kind != .file else { return nil }
        return try? String(contentsOf: itemURL(for: item), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func uniqueURL(preferredName: String) -> URL {
        let cleaned = safeName(preferredName)
        let preferred = rootURL.appendingPathComponent(cleaned)
        guard fileManager.fileExists(atPath: preferred.path) else { return preferred }

        let extensionName = preferred.pathExtension
        let stem = preferred.deletingPathExtension().lastPathComponent
        var number = 2

        while true {
            let candidateName = extensionName.isEmpty
                ? "\(stem) \(number)"
                : "\(stem) \(number).\(extensionName)"
            let candidate = rootURL.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            number += 1
        }
    }

    private func safeName(_ value: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let parts = value.components(separatedBy: forbidden)
        let joined = parts.joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? "Shelf Item" : String(joined.prefix(120))
    }
}

private extension JSONEncoder {
    static var shelf: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .deferredToDate
        return encoder
    }
}

private extension JSONDecoder {
    static var shelf: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }
}
