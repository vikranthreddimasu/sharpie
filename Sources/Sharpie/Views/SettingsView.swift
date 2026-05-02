import AppKit
import SwiftUI

/// Settings is the only settled-in window in Sharpie. The prompt window is
/// transient; this is where the user lives when they want to change
/// something. Three things, in order of how often they're touched:
///
///   1. Hotkey  — set once, sometimes changed
///   2. Backend — set once, occasionally changed
///   3. Model   — per-backend, sometimes changed
///
/// "More" disclosure holds launch-at-login and history toggle. No card
/// chrome — flat layout, generous whitespace, type does the structuring.
struct SettingsView: View {
    @ObservedObject var detector: BackendDetector
    @State private var selectedBackend: BackendID?
    @State private var hotkey: KeyCombo
    @State private var launchAtLogin: Bool
    @State private var historyEnabled: Bool
    @State private var savedAt: Date? = nil
    @State private var modelOverrides: [String: String]
    @State private var customLatched: Set<String> = []

    let onClose: () -> Void

    init(detector: BackendDetector, onClose: @escaping () -> Void) {
        self.detector = detector
        self._selectedBackend = State(initialValue: AppPreferences.activeBackend)
        self._hotkey = State(initialValue: AppPreferences.hotkey)
        self._launchAtLogin = State(initialValue: LaunchAtLoginService.isEnabled)
        self._historyEnabled = State(initialValue: AppPreferences.historyEnabled)
        var overrides: [String: String] = [:]
        var latched: Set<String> = []
        for backend in BackendID.allCases {
            let saved = AppPreferences.model(for: backend) ?? ""
            overrides[backend.rawValue] = saved
            let presetValues = Set(backend.modelOptions.compactMap(\.value))
            if !saved.isEmpty && !presetValues.contains(saved) {
                latched.insert(backend.rawValue)
            }
        }
        self._modelOverrides = State(initialValue: overrides)
        self._customLatched = State(initialValue: latched)
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hotkeySection
                    Divider().opacity(0.18)
                    backendSection
                    Divider().opacity(0.18)
                    moreDisclosure
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            footer
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.thinMaterial)
                .overlay(Divider().opacity(0.3), alignment: .top)
        }
        .frame(width: 540, height: 560)
        .onAppear { detector.scan() }
    }

    // MARK: - Hotkey

    private var hotkeySection: some View {
        sectionRow(
            title: "Hotkey",
            subtitle: "Use this from any app."
        ) {
            HotkeyRecorder(combo: $hotkey)
        }
    }

    // MARK: - Backend

    private var backendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Backend",
                subtitle: "Sharpie uses an AI CLI you're already signed into."
            )
            if detector.available.isEmpty {
                noBackendBlock
            } else {
                ForEach(detector.available) { detection in
                    backendRow(detection: detection)
                }
                // Missing CLIs are intentionally hidden here — discovery
                // happens during the no-CLI first-run flow. Once you have
                // at least one installed, the others stay out of view
                // until you go install one yourself.
            }
        }
    }

    private func backendRow(detection: BackendDetector.Detection) -> some View {
        let isSelected = (selectedBackend == detection.id)
            || (selectedBackend == nil && detection == detector.available.first)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                selectedBackend = detection.id
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detection.displayName)
                            .font(.system(size: 13, weight: .medium))
                        Text(detection.executablePath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected {
                modelField(for: detection.id)
                    .padding(.leading, 28)
                    .padding(.bottom, 4)
            }
        }
    }

    /// Empty state — no AI CLI installed. Settings is not the place to
    /// list install options; the prompt window's first-run setup screen
    /// owns that flow. Here we just say what's wrong and how to fix it.
    private var noBackendBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text("No AI CLI detected.")
                    .font(.system(size: 13, weight: .medium))
                Text("Install Claude Code, Codex, or Gemini. Sharpie picks it up the next time you open this window.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    detector.scan()
                } label: {
                    Label("Re-scan", systemImage: "arrow.clockwise")
                }
                .controlSize(.small)
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.orange.opacity(0.18))
        )
    }

    // MARK: - Model field

    @ViewBuilder
    private func modelField(for backend: BackendID) -> some View {
        let key = backend.rawValue
        let saved = modelOverrides[key] ?? ""
        let options = backend.modelOptions
        let isCustom = customLatched.contains(key)

        let selection = Binding<String>(
            get: { isCustom ? Self.customTag : saved },
            set: { newValue in
                if newValue == Self.customTag {
                    customLatched.insert(key)
                } else {
                    customLatched.remove(key)
                    modelOverrides[key] = newValue
                }
            }
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Model")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                Picker("", selection: selection) {
                    ForEach(options, id: \.label) { option in
                        Text(option.label).tag(option.value ?? "")
                    }
                    if options.count > 1 {
                        Divider()
                        Text("Custom…").tag(Self.customTag)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                Spacer(minLength: 0)
            }

            if isCustom {
                let customBinding = Binding<String>(
                    get: { modelOverrides[key] ?? "" },
                    set: { modelOverrides[key] = $0 }
                )
                TextField("Exact model ID, e.g. claude-sonnet-4-6", text: customBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.leading, 60)
            }

            Text(modelHint(for: backend, isCustom: isCustom))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 60)
        }
    }

    private static let customTag: String = "\u{E000}_sharpie_custom"

    private func modelHint(for backend: BackendID, isCustom: Bool) -> String {
        if isCustom {
            return "Sharpie passes this string verbatim as the model flag."
        }
        switch backend {
        case .claudeCode:
            return "Sonnet handles prompt rewriting well; Haiku is faster but follows the contract less reliably."
        case .gemini:
            return "2.5 Pro is the more reliable rewriter; Flash is quicker but rougher."
        case .codex:
            return "Uses whichever model your codex CLI is set to."
        }
    }

    // MARK: - More

    private var moreDisclosure: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $historyEnabled) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Save history")
                            .font(.system(size: 12, weight: .medium))
                        Text("Local file. ⌘Y opens it from the prompt window.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)

                if LaunchAtLoginService.isAvailable {
                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Launch at login")
                                .font(.system(size: 12, weight: .medium))
                            Text("Sharpie loads when you sign in.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding(.top, 12)
        } label: {
            Text("More")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Layout helpers

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 16, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionRow<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            content()
        }
    }

    // MARK: - Footer

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
        }
    }

    private func save() {
        AppPreferences.activeBackend = selectedBackend
        for backend in BackendID.allCases {
            AppPreferences.setModel(modelOverrides[backend.rawValue], for: backend)
        }
        let oldHotkey = AppPreferences.hotkey
        AppPreferences.hotkey = hotkey
        if hotkey != oldHotkey {
            NotificationCenter.default.post(name: .sharpieHotkeyDidChange, object: nil)
        }
        if LaunchAtLoginService.isAvailable && launchAtLogin != LaunchAtLoginService.isEnabled {
            LaunchAtLoginService.set(launchAtLogin)
        }
        AppPreferences.historyEnabled = historyEnabled
        savedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onClose() }
    }
}
