import SwiftUI

struct SharpenView: View {
    @ObservedObject var viewModel: SharpenViewModel
    let onDismiss: () -> Void

    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            inputBlock
            Divider().opacity(0.35)
            outputBlock
            Divider().opacity(0.35)
            statusBar
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .frame(width: 600, height: 360)
        .onAppear { inputFocused = true }
        .onChange(of: viewModel.inputFocusToken) { _, _ in
            inputFocused = true
        }
    }

    // MARK: - Input

    private var inputBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pencil.tip.crop.circle")
                .foregroundStyle(.tint)
                .font(.system(size: 16))
                .padding(.top, 6)
            ZStack(alignment: .topLeading) {
                if viewModel.input.isEmpty {
                    Text(viewModel.placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.input)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .focused($inputFocused)
                    .frame(minHeight: 60, maxHeight: 84)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Output

    private var outputBlock: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                outputContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
            }

            if case .copied = viewModel.status {
                ToastView(text: "Copied")
                    .padding(.top, 10)
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.18), value: statusKey)
    }

    @ViewBuilder
    private var outputContent: some View {
        switch viewModel.status {
        case .clarifying(let question, _):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "questionmark.diamond.fill")
                    .foregroundStyle(.tint)
                Text(question)
                    .font(.system(size: 14))
                    .textSelection(.enabled)
            }
        case .streaming, .copied:
            Text(viewModel.output)
                .font(.system(size: 14))
                .textSelection(.enabled)
                .lineSpacing(2)
        case .error(let message):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        case .idle:
            EmptyView()
        }
    }

    // A simple, equatable handle on `status` for animation. The associated
    // values on the enum aren't Sendable in all configurations, but the
    // *case* changing is what we want to animate on anyway.
    private var statusKey: String {
        switch viewModel.status {
        case .idle: return "idle"
        case .streaming: return "streaming"
        case .copied: return "copied"
        case .clarifying: return "clarifying"
        case .error: return "error"
        }
    }

    // MARK: - Status

    private var statusBar: some View {
        HStack(spacing: 8) {
            if case .streaming = viewModel.status {
                ProgressView().controlSize(.small)
            }
            Text(viewModel.statusLine)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            providerBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var providerBadge: some View {
        Text("Anthropic · Sonnet")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
    }
}
