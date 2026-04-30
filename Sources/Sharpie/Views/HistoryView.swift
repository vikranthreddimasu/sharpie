import AppKit
import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @State private var query: String = ""
    @State private var selectedId: UUID?
    @State private var confirmingClearAll: Bool = false

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.3)
            HSplitView {
                listColumn
                    .frame(minWidth: 260, idealWidth: 300)
                detailColumn
                    .frame(minWidth: 360)
            }
        }
        .frame(minWidth: 720, minHeight: 460)
        .onAppear {
            if selectedId == nil {
                selectedId = filteredEntries.first?.id
            }
        }
        .alert("Delete all history?", isPresented: $confirmingClearAll) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                store.clearAll()
                selectedId = nil
            }
        } message: {
            Text("This permanently removes \(store.entries.count) entries from disk. This cannot be undone.")
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search inputs and outputs", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: 280)

            Spacer()

            Text("\(store.entries.count) of \(min(store.entries.count, 500)) saved")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if !store.entries.isEmpty {
                Button(role: .destructive) {
                    confirmingClearAll = true
                } label: {
                    Label("Clear all…", systemImage: "trash")
                        .labelStyle(.titleOnly)
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var listColumn: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyListState
            } else {
                List(selection: $selectedId) {
                    ForEach(filteredEntries) { entry in
                        HistoryRow(entry: entry)
                            .tag(entry.id)
                            .contextMenu {
                                Button("Copy current text") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.currentText, forType: .string)
                                }
                                Button("Copy original input") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.originalInput, forType: .string)
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    if selectedId == entry.id {
                                        selectedId = nextSelection(after: entry.id)
                                    }
                                    store.deleteEntry(entry.id)
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    private var emptyListState: some View {
        VStack(spacing: 10) {
            Image(systemName: query.isEmpty ? "clock" : "magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(query.isEmpty
                 ? "No history yet"
                 : "No entries match \"\(query)\"")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if query.isEmpty {
                Text("Sharpened prompts will appear here.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailColumn: some View {
        if let entry = currentEntry {
            HistoryDetailView(entry: entry)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                Text("Select an entry on the left")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
    }

    // MARK: - Helpers

    private var currentEntry: HistoryEntry? {
        guard let id = selectedId else { return nil }
        return store.entries.first(where: { $0.id == id })
    }

    private var filteredEntries: [HistoryEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return store.entries }
        return store.entries.filter { entry in
            entry.originalInput.lowercased().contains(q)
                || entry.aiOutput.lowercased().contains(q)
                || entry.revisions.contains { $0.text.lowercased().contains(q) }
        }
    }

    private func nextSelection(after deletedId: UUID) -> UUID? {
        let visible = filteredEntries
        guard let idx = visible.firstIndex(where: { $0.id == deletedId }) else {
            return visible.first?.id
        }
        let after = visible.dropFirst(idx + 1).first
        if let after { return after.id }
        return visible.dropLast(visible.count - idx).last?.id
    }
}

// MARK: - List row

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(entry.originalInput.prefix(80))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                if entry.wasEdited {
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundStyle(.tint)
                        .help("Edited \(entry.revisions.count) time\(entry.revisions.count == 1 ? "" : "s")")
                }
            }
            Text(entry.aiOutput.prefix(120))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
            HStack(spacing: 6) {
                Text(entry.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(providerBadge(for: entry))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 3)
    }

    private func providerBadge(for entry: HistoryEntry) -> String {
        switch entry.provider {
        case .appleIntelligence: return "Apple Intelligence"
        case .anthropic:         return "Anthropic"
        case .openrouter:
            return entry.modelSlug.map { "OR · \($0)" } ?? "OpenRouter"
        }
    }
}

// MARK: - Detail view

private struct HistoryDetailView: View {
    let entry: HistoryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                metadata
                section(title: "Original input", body: entry.originalInput, copyable: true)
                section(title: "AI output", body: entry.aiOutput, copyable: true, useMarkdown: true)
                if !entry.revisions.isEmpty {
                    revisionsSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var metadata: some View {
        HStack(spacing: 12) {
            Label(entry.createdAt.formatted(date: .abbreviated, time: .shortened),
                  systemImage: "clock")
            Label(providerBadge, systemImage: "cpu")
            if entry.wasEdited {
                Label("\(entry.revisions.count) edit\(entry.revisions.count == 1 ? "" : "s")",
                      systemImage: "pencil")
            }
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }

    private var providerBadge: String {
        switch entry.provider {
        case .appleIntelligence: return "Apple Intelligence (on-device)"
        case .anthropic:         return "Anthropic · Claude Sonnet"
        case .openrouter:
            return entry.modelSlug.map { "OpenRouter · \($0)" } ?? "OpenRouter"
        }
    }

    private func section(
        title: String,
        body: String,
        copyable: Bool,
        useMarkdown: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                if copyable {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(body, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.titleOnly)
                    }
                    .controlSize(.small)
                    .buttonStyle(.borderless)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                if useMarkdown {
                    MarkdownText(source: body)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                } else {
                    Text(body)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var revisionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EDITS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            ForEach(entry.revisions.indices, id: \.self) { i in
                let rev = entry.revisions[i]
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Revision \(i + 1)")
                            .font(.system(size: 11, weight: .medium))
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(rev.timestamp, format: .relative(presentation: .named))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(rev.text, forType: .string)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .labelStyle(.titleOnly)
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderless)
                    }
                    MarkdownText(source: rev.text)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.12))
                )
            }
        }
    }
}
