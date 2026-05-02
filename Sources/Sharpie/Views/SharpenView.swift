import SwiftUI

struct SharpenView: View {
    @ObservedObject var viewModel: SharpenViewModel
    @ObservedObject var detector: BackendDetector
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        Group {
            if case .needsSetup = viewModel.status {
                SetupView(
                    detector: detector,
                    onOpenSettings: onOpenSettings,
                    onDetectionChanged: {
                        // The user just installed a CLI and re-scanned. If
                        // anything is now detectable, leave the setup screen
                        // and land on the prompt input.
                        viewModel.windowDidOpen()
                    }
                )
            } else {
                surface
            }
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Surface

    private var surface: some View {
        VStack(spacing: 0) {
            morphArea
            StateHairline(state: viewModel.hairline)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)

            // Error message lives just below the hairline, intentionally
            // small — the user reads it and resubmits in the same window.
            if case .error(let message) = viewModel.status {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.85))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// The single text region. Phase derived from the viewmodel — the view
    /// transitions cleanly on phase change with implicit cross-fade.
    private var morphArea: some View {
        MorphSurface(
            input: $viewModel.input,
            output: $viewModel.output,
            phase: phase,
            inputFocusToken: viewModel.inputFocusToken,
            isInputEditable: viewModel.isInputEditable,
            placeholder: viewModel.placeholder
        )
        .onChange(of: viewModel.output) { _, _ in
            // If the user edits the rewrite in place after the stream
            // finished, refresh clipboard so paste matches what's on screen.
            if case .copied = viewModel.status {
                viewModel.userEditedOutput()
            }
        }
    }

    private var phase: MorphSurface.Phase {
        switch viewModel.status {
        case .idle, .error: return .input
        case .working: return .working
        case .streaming: return .streaming
        case .copied: return .result
        case .needsSetup: return .input  // unreachable here; setup view branches
        }
    }
}

// MARK: - First-run setup

/// Shown when no AI CLI is installed. Three rows, one per supported backend,
/// each with an Install link (deep-link to the official docs) and a status
/// dot. Bottom: a Re-scan that re-checks $PATH the moment a CLI lands.
///
/// IMPORTANT: this view shares the *same* `BackendDetector` instance as the
/// ViewModel — re-scanning here updates the source of truth, so when a user
/// installs a CLI and clicks Re-scan, the prompt window flips out of setup
/// mode (via `onDetectionChanged`).
private struct SetupView: View {

    @ObservedObject var detector: BackendDetector
    let onOpenSettings: () -> Void
    let onDetectionChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sharpie needs one of these installed.")
                    .font(.system(size: 15, weight: .semibold))
                Text("No API keys. Sharpie uses your existing CLI session.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                installRow(.claudeCode, oneLiner: "Anthropic. Recommended.")
                installRow(.codex, oneLiner: "OpenAI.")
                installRow(.gemini, oneLiner: "Google.")
            }

            HStack(spacing: 8) {
                Button {
                    detector.scan()
                    if detector.hasAnyBackend {
                        onDetectionChanged()
                    }
                } label: {
                    Label("Re-scan", systemImage: "arrow.clockwise")
                }
                .controlSize(.small)
                Spacer()
                Button("Settings", action: onOpenSettings)
                    .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { detector.scan() }
    }

    @ViewBuilder
    private func installRow(_ backend: BackendID, oneLiner: String) -> some View {
        let installed = detector.detection(for: backend) != nil
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(installed ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(backend.displayName)
                        .font(.system(size: 13, weight: .medium))
                    if installed {
                        Text("Installed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green)
                    }
                }
                Text(oneLiner)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !installed {
                Button("Install") {
                    if let url = URL(string: backend.installURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(installed ? 0.04 : 0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.12))
        )
    }
}

import AppKit
