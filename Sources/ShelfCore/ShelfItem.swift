import Foundation

public struct ShelfItem: Identifiable, Codable, Hashable {
    public enum Kind: String, Codable {
        case file
        case link
        case note

        public var systemImage: String {
            switch self {
            case .file: "doc"
            case .link: "link"
            case .note: "note.text"
            }
        }
    }

    public let id: UUID
    public var kind: Kind
    public var title: String
    public var filename: String
    public var createdAt: Date
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        filename: String,
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.filename = filename
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}
