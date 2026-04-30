import SwiftUI

struct SettingsView: View {
    @State private var activeProvider: ProviderID
    @State private var openRouterModel: String

    // Newly entered keys live only in this view's @State. We never reload
    // an already-stored key from the Keychain into the SecureField — that
    // way the Reveal toggle can never expose a key the user hasn't just
    // typed.
    @State private var newOpenRouterKey: String = ""
    @State private var newAnthropicKey: String = ""

    @State private var openRouterStored: Bool
    @State private var anthropicStored: Bool

    /// `true` once the user clicks "Replace…", or by default when no key
    /// is stored yet for that provider.
    @State private var openRouterReplaceMode: Bool
    @State private var anthropicReplaceMode: Bool

    @State private var revealOpenRouterKey: Bool = false
    @State private var revealAnthropicKey: Bool = false
    @State private var savedAt: Date? = nil

    @StateObject private var modelDirectory = OpenRouterModelDirectory()

    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self._activeProvider = State(initialValue: AppPreferences.activeProvider)
        self._openRouterModel = State(initialValue: AppPreferences.openRouterModel)
        let openRouterStored = (KeychainService.get(.openrouter) != nil)
        let anthropicStored = (KeychainService.get(.anthropic) != nil)
        self._openRouterStored = State(initialValue: openRouterStored)
        self._anthropicStored = State(initialValue: anthropicStored)
        self._openRouterReplaceMode = State(initialValue: !openRouterStored)
        self._anthropicReplaceMode = State(initialValue: !anthropicStored)
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            picker
            Divider().opacity(0.4)
            providerSection
            Spacer(minLength: 4)
            footer
        }
        .padding(22)
        .frame(width: 520)
        .task { await modelDirectory.fetch() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sharpie").font(.title3.weight(.semibold))
            Text("Bring your own API key. Stored only in macOS Keychain — never written to disk in plaintext, never sent anywhere except your chosen provider.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var picker: some View {
        Picker("", selection: $activeProvider) {
            ForEach(ProviderID.allCases) { Text($0.displayName).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var providerSection: some View {
        switch activeProvider {
        case .openrouter:
            VStack(alignment: .leading, spacing: 14) {
                openRouterKeyBlock
                modelBlock
            }
        case .anthropic:
            anthropicKeyBlock
        }
    }

    // MARK: - OpenRouter

    private var openRouterKeyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("OpenRouter API key", hint: "Get one at openrouter.ai/keys.")
            if openRouterStored && !openRouterReplaceMode {
                storedKeyRow {
                    openRouterReplaceMode = true
                    newOpenRouterKey = ""
                    revealOpenRouterKey = false
                }
            } else {
                keyEntryRow(
                    text: $newOpenRouterKey,
                    reveal: $revealOpenRouterKey,
                    placeholder: "sk-or-…"
                )
            }
        }
    }

    private var modelBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Model", hint: "Live list from OpenRouter. Default is an Anthropic Sonnet.")
            modelPicker
        }
    }

    @ViewBuilder
    private var modelPicker: some View {
        switch modelDirectory.state {
        case .idle, .loading:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small).scaleEffect(0.7)
                Text("Loading models…").font(.caption).foregroundStyle(.secondary)
            }
            .frame(height: 28)
        case .loaded(let models):
            ModelPicker(selection: $openRouterModel, models: models)
                .onAppear { applyDefault(in: models) }
                .onChange(of: modelDirectory.state) { _, _ in
                    if case .loaded(let m) = modelDirectory.state {
                        applyDefault(in: m)
                    }
                }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn't load model list (\(message)). Type a slug instead:")
                    .font(.caption).foregroundStyle(.orange)
                TextField(AppPreferences.defaultOpenRouterModel, text: $openRouterModel)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func applyDefault(in models: [OpenRouterModel]) {
        guard !models.isEmpty else { return }
        if !models.contains(where: { $0.id == openRouterModel }) {
            if let pref = OpenRouterModelDirectory.preferredDefault(in: models) {
                openRouterModel = pref
            }
        }
    }

    // MARK: - Anthropic

    private var anthropicKeyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Anthropic API key", hint: "Get one at console.anthropic.com.")
            if anthropicStored && !anthropicReplaceMode {
                storedKeyRow {
                    anthropicReplaceMode = true
                    newAnthropicKey = ""
                    revealAnthropicKey = false
                }
            } else {
                keyEntryRow(
                    text: $newAnthropicKey,
                    reveal: $revealAnthropicKey,
                    placeholder: "sk-ant-…"
                )
            }
        }
    }

    // MARK: - Reusable bits

    private func fieldLabel(_ title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.medium))
            Text(hint).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func storedKeyRow(replace: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text("Stored in Keychain").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("Replace…", action: replace).controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.secondary.opacity(0.15))
        )
    }

    private func keyEntryRow(
        text: Binding<String>,
        reveal: Binding<Bool>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 6) {
            Group {
                if reveal.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))

            Button {
                reveal.wrappedValue.toggle()
            } label: {
                Image(systemName: reveal.wrappedValue ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
            .help(reveal.wrappedValue ? "Hide" : "Reveal")
        }
        // Auto-hide reveal after 5s — small privacy nicety in case the
        // user steps away with the key visible.
        .onChange(of: reveal.wrappedValue) { _, isRevealed in
            if isRevealed {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if reveal.wrappedValue { reveal.wrappedValue = false }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if let savedAt, Date().timeIntervalSince(savedAt) < 2 {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
            Spacer()
            Button("Cancel", action: onClose).keyboardShortcut(.cancelAction)
            Button("Save", action: save)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
        }
    }

    private var canSave: Bool {
        switch activeProvider {
        case .openrouter:
            if openRouterStored && !openRouterReplaceMode { return true }
            return !newOpenRouterKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .anthropic:
            if anthropicStored && !anthropicReplaceMode { return true }
            return !newAnthropicKey.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func save() {
        let trimmedOR = newOpenRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAN = newAnthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if openRouterReplaceMode && !trimmedOR.isEmpty {
            KeychainService.set(trimmedOR, for: .openrouter)
            openRouterStored = true
            openRouterReplaceMode = false
            newOpenRouterKey = ""
            revealOpenRouterKey = false
        }
        if anthropicReplaceMode && !trimmedAN.isEmpty {
            KeychainService.set(trimmedAN, for: .anthropic)
            anthropicStored = true
            anthropicReplaceMode = false
            newAnthropicKey = ""
            revealAnthropicKey = false
        }
        AppPreferences.openRouterModel = openRouterModel
        AppPreferences.activeProvider = activeProvider
        savedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onClose()
        }
    }
}
