import SwiftUI

struct SharpenView: View {
    @ObservedObject var viewModel: SharpenViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            inputBlock
            if showsOutputArea {
                Divider().opacity(0.35)
                outputBlock
            }
            Divider().opacity(0.35)
            statusBar
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.18), value: statusKey)
    }

    private var showsOutputArea: Bool {
        switch viewModel.status {
        case .idle: return false
        case .streaming, .copied, .clarifying, .error: return true
        }
    }

    // MARK: - Input

    private var inputBlock: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.input.isEmpty {
                Text(viewModel.placeholder)
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
                    .padding(
                        EdgeInsets(
                            top: SharpieTextView.textInset.height,
                            leading: SharpieTextView.textInset.width,
                            bottom: 0,
                            trailing: 0
                        )
                    )
                    .allowsHitTesting(false)
            }
            SharpieTextView(
                text: $viewModel.input,
                focusToken: viewModel.inputFocusToken
            )
            .frame(minHeight: 36, maxHeight: 90)
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }

            if case .copied = viewModel.status {
                ToastView(text: "Copied")
                    .padding(.top, 10)
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var outputContent: some View {
        switch viewModel.status {
        case .clarifying(let question, _):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "questionmark.diamond.fill")
                    .foregroundStyle(.tint)
                    .font(.system(size: 14))
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
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                Text(message)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
            }
        case .idle:
            EmptyView()
        }
    }

    /// A simple equatable handle on `status` that we animate against. The
    /// associated values are case-stable enough for visual transitions.
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
                ProgressView().controlSize(.small).scaleEffect(0.7)
            }
            Text(viewModel.statusLine)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
