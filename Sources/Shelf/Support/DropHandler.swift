import Foundation
import UniformTypeIdentifiers

enum DropHandler {
    static func handle(_ providers: [NSItemProvider], store: ShelfStore) -> Bool {
        var accepted = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                accepted = true
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let url: URL?
                    if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    } else {
                        url = item as? URL
                    }
                    guard let url else { return }
                    Task { @MainActor in store.importURL(url) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                accepted = true
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    let url = (item as? URL) ?? (item as? String).flatMap(URL.init(string:))
                    guard let url else { return }
                    Task { @MainActor in store.importURL(url) }
                }
            } else if provider.canLoadObject(ofClass: NSString.self) {
                accepted = true
                provider.loadObject(ofClass: NSString.self) { object, _ in
                    guard let text = object as? String else { return }
                    Task { @MainActor in
                        if let url = URL(string: text),
                           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                            store.importURL(url)
                        } else {
                            store.addNote(text)
                        }
                    }
                }
            }
        }

        return accepted
    }
}
