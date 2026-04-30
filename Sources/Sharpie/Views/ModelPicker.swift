import SwiftUI

// SwiftUI's Picker(.menu) with hundreds of items is unusable: no search,
// no grouping, the popup overflows the screen and silently drops rows.
// This is a custom button-with-popover that:
// - shows the current selection in a compact pill
// - opens a 460×420 popover with a search box + list grouped by provider
// - filters live as the user types
// - works for any number of models — minimax through anthropic
struct ModelPicker: View {
    @Binding var selection: String
    let models: [OpenRouterModel]

    @State private var presented = false
    @State private var query = ""

    var body: some View {
        Button(action: { presented.toggle() }) {
            HStack(spacing: 8) {
                Text(selection.isEmpty ? "Select a model…" : selection)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(selection.isEmpty ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $presented, arrowEdge: .bottom) {
            popoverContent.frame(width: 460, height: 420)
        }
    }

    @ViewBuilder
    private var popoverContent: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            list
            Divider()
            footer
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))
            TextField("Search providers, models, slugs…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    private var list: some View {
        ScrollViewReader { _ in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(grouped, id: \.provider) { group in
                        Section {
                            ForEach(group.models, id: \.id) { model in
                                ModelRow(
                                    model: model,
                                    isSelected: model.id == selection
                                ) {
                                    selection = model.id
                                    presented = false
                                }
                            }
                        } header: {
                            providerHeader(group.provider, count: group.models.count)
                        }
                    }
                    if grouped.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.tertiary)
                            Text("No models match \"\(query)\"")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func providerHeader(_ name: String, count: Int) -> some View {
        HStack {
            Text(name.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.regularMaterial)
    }

    private var footer: some View {
        HStack {
            Text("\(filtered.count) of \(models.count) models")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Filtering / grouping

    private var filtered: [OpenRouterModel] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return models }
        return models.filter {
            $0.id.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    private struct Group {
        let provider: String
        let models: [OpenRouterModel]
    }

    private var grouped: [Group] {
        var bucket: [String: [OpenRouterModel]] = [:]
        for m in filtered {
            bucket[providerName(of: m.id), default: []].append(m)
        }
        return bucket
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { Group(provider: $0.key, models: $0.value.sorted { $0.id < $1.id }) }
    }

    private func providerName(of id: String) -> String {
        // Strip OpenRouter's variant tilde prefix and split on first slash.
        let stripped = id.hasPrefix("~") ? String(id.dropFirst()) : id
        if let slash = stripped.firstIndex(of: "/") {
            return String(stripped[..<slash])
        }
        return "Other"
    }
}

private struct ModelRow: View {
    let model: OpenRouterModel
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.id)
                        .font(.system(.callout, design: .monospaced))
                    if model.name != model.id {
                        Text(model.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(rowBackground)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var rowBackground: some View {
        Group {
            if isSelected {
                Color.accentColor.opacity(0.15)
            } else if hovering {
                Color.secondary.opacity(0.10)
            } else {
                Color.clear
            }
        }
    }
}
