import SwiftUI

struct AddLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ShelfStore
    @State private var link = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save a link")
                .font(.title2.bold())

            TextField("https://example.com", text: $link)
                .textFieldStyle(.roundedBorder)
                .frame(width: 420)
                .onSubmit(save)

            Text("Shelf saves the address in a normal text file inside your Shelf folder.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
    }

    private func save() {
        if store.addLink(link) {
            dismiss()
        }
    }
}
