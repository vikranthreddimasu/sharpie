import AppKit
import SwiftUI

/// Sheet UI that browses Sharpie's curated Ollama catalog and lets the
/// user install / remove models without ever touching a terminal.
/// Hosted by SettingsView; sized to feel focused, not overwhelming.
struct OllamaCatalogView: View {
    @ObservedObject var directory: OllamaModelDirectory
    @StateObject private var pull = OllamaPullService()

    let baseURL: URL
    let onClose: () -> Void

    @State private var query: String = ""
    @State private var removing: String? = nil
    @State private var removalError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            content
        }
        .frame(width: 640, height: 580)
        .onChange(of: pull.phase) { _, new in
            // When a pull finishes, re-fetch the installed model list so
            // the new model immediately shows the "Installed" badge and
            // the SettingsView's picker has it.
            if case .finished = new {
                Task { await directory.fetch(baseURL: baseURL) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ollama models")
                        .font(.title3.weight(.semibold))
                    Text("Browse what to run locally on your Mac. No terminal, no setup — pick a model and Sharpie handles the rest.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done", action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search models", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
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
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(20)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let removalError {
                    errorBanner(removalError) { self.removalError = nil }
                }
                ForEach(filteredCategories, id: \.0) { (category, models) in
                    if !models.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.6)
                                Text(category.hint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 8) {
                                ForEach(models) { model in
                                    modelCard(model)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func errorBanner(_ message: String, dismiss: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message).font(.caption).foregroundStyle(.primary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func modelCard(_ model: OllamaCatalog.Model) -> some View {
        let installed = isInstalled(model.slug)
        let pullingThis = pull.modelName == model.slug && pull.isActive
        let removingThis = removing == model.slug

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.displayName)
                    .font(.system(size: 14, weight: .semibold))
                if model.recommended && !installed {
                    badge("Recommended", tint: .green)
                }
                if installed {
                    badge("Installed", tint: .blue)
                }
                Spacer()
                Text(model.displaySize)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(model.blurb)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(model.slug)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)

            if pullingThis {
                pullProgressRow
            } else {
                actionsRow(model: model, installed: installed, removingThis: removingThis)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.12))
        )
    }

    @ViewBuilder
    private var pullProgressRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                if let frac = pull.phase.fraction {
                    ProgressView(value: frac)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView().progressViewStyle(.linear)
                }
                Text(pull.phase.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Cancel", role: .destructive) {
                pull.cancel()
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder
    private func actionsRow(model: OllamaCatalog.Model, installed: Bool, removingThis: Bool) -> some View {
        HStack(spacing: 8) {
            Spacer()
            if installed {
                Button(role: .destructive) {
                    Task { await removeModel(model) }
                } label: {
                    if removingThis {
                        ProgressView().controlSize(.small).scaleEffect(0.7)
                    } else {
                        Text("Remove")
                    }
                }
                .controlSize(.small)
                .disabled(removingThis || pull.isActive)
            } else {
                Button {
                    pull.pull(model: model.slug, baseURL: baseURL)
                } label: {
                    Label("Install", systemImage: "arrow.down.circle")
                        .labelStyle(.titleAndIcon)
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .disabled(pull.isActive)
            }
        }
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
    }

    // MARK: - Filtering

    private var filteredCategories: [(OllamaCatalog.Category, [OllamaCatalog.Model])] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return OllamaCatalog.byCategory.map { (cat, models) in
            let filtered = q.isEmpty
                ? models
                : models.filter {
                    $0.slug.lowercased().contains(q)
                        || $0.displayName.lowercased().contains(q)
                        || $0.blurb.lowercased().contains(q)
                }
            return (cat, filtered)
        }
    }

    // MARK: - Actions

    private func isInstalled(_ slug: String) -> Bool {
        if case .loaded(let models) = directory.state {
            return models.contains { $0.id == slug }
        }
        return false
    }

    private func removeModel(_ model: OllamaCatalog.Model) async {
        removing = model.slug
        do {
            try await OllamaRemoveService.remove(model: model.slug, baseURL: baseURL)
            await directory.fetch(baseURL: baseURL)
        } catch {
            removalError = "Couldn't remove \(model.slug): \(error.localizedDescription)"
        }
        removing = nil
    }

}
