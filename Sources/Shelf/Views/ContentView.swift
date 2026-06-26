import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    let updater: ShelfUpdater
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @State private var isDropTargeted = false
    @State private var showingAddLink = false
    @State private var showingFileImporter = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            appBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                chromeRow
                header
                controlBar

                if store.filteredItems.isEmpty {
                    emptyState
                } else {
                    shelfCard
                }

                retentionFooter
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .ignoresSafeArea(.container, edges: .top)

            WindowChromeConfigurator()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .frame(minWidth: 680, minHeight: 470)
        .sheet(isPresented: $showingAddLink) {
            AddLinkView(store: store)
        }
        .sheet(isPresented: $showingSettings) {
            ShelfSettingsView(
                store: store,
                updater: updater,
                appearanceMode: $appearanceMode
            )
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                urls.forEach { store.importURL($0) }
            case .failure(let error):
                store.errorMessage = error.localizedDescription
            }
        }
        .preferredColorScheme(selectedColorScheme)
        .alert(
            "Shelf couldn’t save that",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
        .onDrop(
            of: [UTType.fileURL, UTType.url, UTType.utf8PlainText],
            isTargeted: $isDropTargeted
        ) { providers in
            DropHandler.handle(providers, store: store)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
    }

    private var appBackground: Color {
        colorScheme == .light
            ? Color(nsColor: .windowBackgroundColor)
            : Color(nsColor: .underPageBackgroundColor)
    }

    private var selectedColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private var chromeRow: some View {
        HStack {
            WindowTrafficLights()

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.quaternary.opacity(0.45), in: Circle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Shelf Settings")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(.blue.opacity(0.12))

                Image(systemName: "tray.full.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 46, height: 46)

            Text("Shelf")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Spacer()

            Button {
                showingFileImporter = true
            } label: {
                Label("Drop anything in here", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary.opacity(0.45), in: Capsule())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Choose files to add to Shelf")
        }
    }

    private var controlBar: some View {
        HStack(spacing: 10) {
            Button {
                showingAddLink = true
            } label: {
                Label("Add Link", systemImage: "link.badge.plus")
            }
            .buttonStyle(ShelfPillButtonStyle())
            .keyboardShortcut("l", modifiers: [.command])
            .pointingHandCursor()

            Button {
                showingFileImporter = true
            } label: {
                Label("Add File", systemImage: "plus")
            }
            .buttonStyle(ShelfPillButtonStyle())
            .pointingHandCursor()

            Button {
                store.openShelfFolder()
            } label: {
                Label("Folder", systemImage: "folder")
            }
            .buttonStyle(ShelfPillButtonStyle())
            .pointingHandCursor()

            Spacer(minLength: 14)

            searchField
                .frame(width: 280)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.primary.opacity(0.07), lineWidth: 1)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search Shelf", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.callout.weight(.medium))

            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.background.opacity(0.48), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your Shelf is empty", systemImage: "tray")
        } description: {
            Text("Drop files, web links, or text anywhere in this window.")
        } actions: {
            HStack {
                Button("Add a Link") { showingAddLink = true }
                Button("Open Shelf Folder") { store.openShelfFolder() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var shelfCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Saved for later today")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("\(store.filteredItems.count) \(store.filteredItems.count == 1 ? "item" : "items") on your shelf")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                retentionMenu
            }
            .padding(.horizontal, 6)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.filteredItems) { item in
                        ShelfRow(item: item, store: store)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.automatic)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 28, x: 0, y: 14)
    }

    private var retentionMenu: some View {
        Menu {
            ForEach(ShelfStore.linkRetentionOptions) { option in
                Button {
                    store.setLinkRetention(days: option.days)
                } label: {
                    if option.days == store.linkRetentionDays {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(store.linkRetentionSummary)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.55), in: Capsule())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help("Change how long links stay listed")
    }

    private var retentionFooter: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text("Links stay listed for")

            Menu {
                ForEach(ShelfStore.linkRetentionOptions) { option in
                    Button {
                        store.setLinkRetention(days: option.days)
                    } label: {
                        if option.days == store.linkRetentionDays {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                Text(store.linkRetentionTitle)
                    .underline()
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Text("· pinned links stay")
            Spacer()
            Text("Removing an item keeps its saved file.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
    }
}

private struct WindowTrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            TrafficLightButton(color: .red, symbol: "xmark") {
                activeWindow?.performClose(nil)
            }
            TrafficLightButton(color: .yellow, symbol: "minus") {
                activeWindow?.performMiniaturize(nil)
            }
            TrafficLightButton(color: .green, symbol: "arrow.up.left.and.arrow.down.right") {
                activeWindow?.performZoom(nil)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .help("Close, minimize, or resize Shelf")
    }

    private var activeWindow: NSWindow? {
        NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first { $0.isVisible }
    }
}

private struct TrafficLightButton: View {
    let color: Color
    let symbol: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 13, height: 13)

                if isHovering {
                    Image(systemName: symbol)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.black.opacity(0.58))
                }
            }
            .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .onHover { isHovering = $0 }
    }
}

private struct ShelfSettingsView: View {
    @ObservedObject var store: ShelfStore
    let updater: ShelfUpdater
    @Binding var appearanceMode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Settings", systemImage: "gearshape.fill")
                    .font(.title2.bold())

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.quaternary.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Appearance")
                    .font(.headline)

                Picker("Theme", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .settingsCard()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Links")
                        .font(.headline)

                    Spacer()

                    Menu {
                        ForEach(ShelfStore.linkRetentionOptions) { option in
                            Button {
                                store.setLinkRetention(days: option.days)
                            } label: {
                                if option.days == store.linkRetentionDays {
                                    Label(option.title, systemImage: "checkmark")
                                } else {
                                    Text(option.title)
                                }
                            }
                        }
                    } label: {
                        Text(store.linkRetentionTitle)
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary.opacity(0.55), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }

                Text("Unpinned links stay visible for this long. Pinned links stay until you remove them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .settingsCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("Storage")
                    .font(.headline)

                SettingsInfoRow(title: "Saved items", value: "\(store.items.count)")
                SettingsInfoRow(title: "Folder", value: store.storage.rootURL.path)

                Button {
                    store.openShelfFolder()
                } label: {
                    Label("Open Shelf Folder", systemImage: "folder")
                }
                .buttonStyle(ShelfPillButtonStyle())
                .pointingHandCursor()
            }
            .padding(16)
            .settingsCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("Updates")
                    .font(.headline)

                Text("Shelf opens the latest GitHub Release so users can download the newest version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                CheckForUpdatesButton(updater: updater)
                    .buttonStyle(ShelfPillButtonStyle())
                    .pointingHandCursor()
            }
            .padding(16)
            .settingsCard()

            Text("Removing an item from Shelf only hides it from the app list. The saved file stays in your Shelf folder.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(width: 430)
        .background(.regularMaterial)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.callout)
    }
}

private extension View {
    func settingsCard() -> some View {
        background(.background.opacity(0.46), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.primary.opacity(0.07), lineWidth: 1)
            }
    }
}

private struct ShelfPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.13 : 0.07),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.primary.opacity(0.07), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
