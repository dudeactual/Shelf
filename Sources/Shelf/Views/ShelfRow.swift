import SwiftUI
import ShelfCore

struct ShelfRow: View {
    let item: ShelfItem
    let store: ShelfStore
    @State private var isHovering = false
    @State private var showOpenHint = false
    @State private var hintTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 14) {
            icon

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(rowDetail)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            trailingStatus
            actionButtons
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(rowBackground)
        .overlay(rowBorder)
        .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .pointingHandCursor()
        .onHover { hovering in
            isHovering = hovering
            hintTask?.cancel()

            if hovering {
                hintTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
                        showOpenHint = true
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.12)) {
                    showOpenHint = false
                }
            }
        }
        .onDisappear {
            hintTask?.cancel()
        }
        .onTapGesture(count: 2) { store.open(item) }
        .contextMenu {
            Button("Open") { store.open(item) }
            Button("Show in Finder") { store.reveal(item) }
            Divider()
            Button(item.isPinned ? "Unpin" : "Pin") { store.togglePin(item) }
            Button("Remove from Shelf", role: .destructive) {
                store.removeFromShelf(item)
            }
        }
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconTint.opacity(0.11))

            Image(systemName: item.kind.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconTint)
        }
        .frame(width: 38, height: 38)
    }

    private var trailingStatus: some View {
        Group {
            if showOpenHint {
                Text("Double-Click to Open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.72), in: Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                Text(store.retentionStatus(for: item))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .animation(.easeOut(duration: 0.18), value: showOpenHint)
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            Button {
                store.togglePin(item)
            } label: {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(item.isPinned ? .orange : .secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(isHovering ? 0.08 : 0), in: Circle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help(item.isPinned ? "Unpin" : "Pin to Shelf")

            Button(role: .destructive) {
                store.removeFromShelf(item)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(isHovering ? 0.08 : 0), in: Circle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Remove from Shelf (saved file stays in the Shelf folder)")
        }
        .opacity(isHovering || item.isPinned ? 1 : 0.45)
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    private var rowBackground: some ShapeStyle {
        if isHovering {
            AnyShapeStyle(.quaternary.opacity(0.7))
        } else {
            AnyShapeStyle(.background.opacity(0.55))
        }
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .stroke(isHovering ? .blue.opacity(0.62) : .primary.opacity(0.07), lineWidth: isHovering ? 1.5 : 1)
    }

    private var iconTint: Color {
        switch item.kind {
        case .link: .blue
        case .file: .indigo
        case .note: .purple
        }
    }

    private var rowDetail: String {
        switch item.kind {
        case .link:
            item.filename.replacingOccurrences(of: ".txt", with: "")
        case .file:
            "File • \(item.filename)"
        case .note:
            "Note • \(item.filename)"
        }
    }
}
