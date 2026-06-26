import Foundation
import ShelfCore

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw CheckFailure.failed(message) }
}

func makeStorage() -> (ShelfStorage, URL) {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("ShelfChecks-\(UUID().uuidString)", isDirectory: true)
    return (ShelfStorage(rootURL: rootURL), rootURL)
}

func checkReadableLinkFile() throws {
    let (storage, rootURL) = makeStorage()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let item = try storage.saveLink("https://example.com/a")
    let value = try String(contentsOf: storage.itemURL(for: item), encoding: .utf8)
    try expect(item.kind == .link, "Saved link has the wrong kind")
    try expect(item.filename.hasSuffix(".txt"), "Saved link is not a text file")
    try expect(value == "https://example.com/a\n", "Saved link contents changed")
}

func checkUniqueImports() throws {
    let (storage, rootURL) = makeStorage()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let source = FileManager.default.temporaryDirectory
        .appendingPathComponent("Shelf-source-\(UUID().uuidString).txt")
    try "hello".write(to: source, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: source) }

    let first = try storage.importFile(at: source)
    let second = try storage.importFile(at: source)
    try expect(first.filename != second.filename, "Duplicate imports overwrote one another")
    try expect(FileManager.default.fileExists(atPath: storage.itemURL(for: first).path), "First import is missing")
    try expect(FileManager.default.fileExists(atPath: storage.itemURL(for: second).path), "Second import is missing")
}

func checkIndexRoundTrip() throws {
    let (storage, rootURL) = makeStorage()
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let item = try storage.saveNote("A useful note")
    try storage.saveItems([item])
    let loadedItems = try storage.loadItems()
    try expect(loadedItems == [item], "Saved index did not round-trip")
}

do {
    try checkReadableLinkFile()
    try checkUniqueImports()
    try checkIndexRoundTrip()
    print("Shelf storage checks passed.")
} catch {
    fputs("Shelf storage check failed: \(error)\n", stderr)
    exit(1)
}
