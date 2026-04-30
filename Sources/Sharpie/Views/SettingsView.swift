import SwiftUI

struct SettingsView: View {
    @State private var activeProvider: ProviderID
    @State private var openRouterKey: String
    @State private var anthropicKey: String
    @State private var openRouterModel: String
    @State private var revealKey: Bool = false
    @State private var savedAt: Date? = nil

    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self._activeProvider = State(initialValue: AppPreferences.activeProvider)
        self._openRouterKey = State(initialValue: KeychainService.get(.openrouter) ?? "")
        self._anthropicKey = State(initialValue: KeychainService.get(.anthropic) ?? "")
        self._openRouterModel = State(initialValue: AppPreferences.openRouterModel)
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Picker("", selection: $activeProvider) {
                ForEach(ProviderID.allCases) { p in
                    Text(p.displayName).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider().opacity(0.4)

            providerSection

            Spacer(minLength: 4)

            footer
        }
        .padding(22)
        .frame(width: 480)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sharpie")
                .font(.title3.weight(.semibold))
            Text("Bring your own API key. Keys are stored in macOS Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var providerSection: some View {
        switch activeProvider {
        case .openrouter:
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel(
                    "OpenRouter API key",
                    hint: "Get one at openrouter.ai/keys."
                )
                keyField($openRouterKey, placeholder: "sk-or-…")

                fieldLabel(
                    "Model",
                    hint: "Any OpenRouter slug — e.g. anthropic/claude-sonnet-4.5, openai/gpt-4o, google/gemini-2.5-flash."
                )
                TextField(AppPreferences.defaultOpenRouterModel, text: $openRouterModel)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        case .anthropic:
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel(
                    "Anthropic API key",
                    hint: "Get one at console.anthropic.com. Uses Claude Sonnet."
                )
                keyField($anthropicKey, placeholder: "sk-ant-…")
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
            return !openRouterKey.trimmingCharacters(in: .whitespaces).isEmpty
        case .anthropic:
            return !anthropicKey.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func fieldLabel(_ title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.medium))
            Text(hint).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func keyField(_ binding: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 6) {
            Group {
                if revealKey {
                    TextField(placeholder, text: binding)
                } else {
                    SecureField(placeholder, text: binding)
                }
            }
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))

            Button {
                revealKey.toggle()
            } label: {
                Image(systemName: revealKey ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
            .help(revealKey ? "Hide" : "Reveal")
        }
    }

    private func save() {
        let trimmedOR = openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAN = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOR.isEmpty { KeychainService.set(trimmedOR, for: .openrouter) }
        if !trimmedAN.isEmpty { KeychainService.set(trimmedAN, for: .anthropic) }
        AppPreferences.openRouterModel = openRouterModel
        AppPreferences.activeProvider = activeProvider
        savedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onClose()
        }
    }
}
