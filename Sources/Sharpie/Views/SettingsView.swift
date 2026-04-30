import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainService.get(.anthropic) ?? ""
    @State private var revealKey: Bool = false
    @State private var savedAt: Date? = nil
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Anthropic API Key")
                .font(.headline)

            Text("Stored in macOS Keychain. Get one at console.anthropic.com.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Group {
                    if revealKey {
                        TextField("sk-ant-…", text: $apiKey)
                    } else {
                        SecureField("sk-ant-…", text: $apiKey)
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
                .help(revealKey ? "Hide key" : "Reveal key")
            }

            HStack {
                if let savedAt, Date().timeIntervalSince(savedAt) < 2 {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
                Spacer()
                Button("Cancel", action: onClose)
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private func save() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if KeychainService.set(trimmed, for: .anthropic) {
            savedAt = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onClose()
            }
        }
    }
}
