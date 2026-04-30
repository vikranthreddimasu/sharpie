import SwiftUI

struct SharpenView: View {
    @ObservedObject var viewModel: SharpenViewModel
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        Group {
            if case .needsSetup = viewModel.status {
                setupView
            } else {
                primaryView
            }
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

    private var primaryView: some View {
        VStack(spacing: 0) {
            inputBlock
            if showsOutputArea {
                Divider().opacity(0.35)
                outputBlock
            }
            Divider().opacity(0.35)
            statusBar
        }
    }

    private var setupView: some View {
        VStack(spacing: 14) {
            Image(systemName: "key.fill")
                .font(.system(size: 28))
                .foregroundStyle(.tint)
            VStack(spacing: 4) {
                Text("Welcome to Sharpie")
                    .font(.title3.weight(.semibold))
                Text("Add an API key to start sharpening prompts.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: onOpenSettings) {
                Label("Open Settings", systemImage: "gearshape.fill")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var showsOutputArea: Bool {
        switch viewModel.status {
        case .idle, .needsSetup: return false
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
                focusToken: viewModel.inputFocusToken,
                isEditable: viewModel.isInputEditable,
                identifier: "sharpieInput"
            )
            .frame(minHeight: 36, maxHeight: 90)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Output

    private var outputBlock: some View {
        ZStack(alignment: .topTrailing) {
            outputBody
            outputControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var outputBody: some View {
        if case .copied = viewModel.status, viewModel.outputEditing {
            outputEditor
        } else {
            outputViewer
        }
    }

    private var outputViewer: some View {
        ScrollViewReader { proxy in
            ScrollView {
                outputContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                Color.clear.frame(height: 1).id("outputBottom")
            }
            .onChange(of: viewModel.output) { _, _ in
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo("outputBottom", anchor: .bottom)
                }
            }
        }
    }

    private var outputEditor: some View {
        SharpieTextView(
            text: $viewModel.output,
            focusToken: viewModel.outputFocusToken,
            isEditable: true,
            identifier: "sharpieOutput",
            onCommit: { _ in
                viewModel.commitOutputEdit()
            }
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var outputControls: some View {
        if case .copied = viewModel.status {
            Button(action: viewModel.toggleOutputEditing) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.outputEditing
                          ? "checkmark"
                          : "pencil")
                        .font(.system(size: 10, weight: .semibold))
                    Text(viewModel.outputEditing ? "Done" : "Edit")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(viewModel.outputEditing ? Color.white : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(
                        viewModel.outputEditing
                            ? Color.accentColor
                            : Color.secondary.opacity(0.18)
                    )
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.trailing, 12)
            .help(viewModel.outputEditing
                  ? "Save your edits and switch back to the rendered view"
                  : "Edit the rewrite before pasting")
        }
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
        case .streaming:
            // While streaming we render plain text — markdown parsing
            // mid-stream produces flicker as the AI types unbalanced
            // bold/italic markers.
            Text(viewModel.output)
                .font(.system(size: 14))
                .textSelection(.enabled)
                .lineSpacing(2)
        case .copied:
            MarkdownText(source: viewModel.output)
                .font(.system(size: 14))
                .textSelection(.enabled)
        case .error(let message):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                Text(message)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
            }
        case .idle, .needsSetup:
            EmptyView()
        }
    }

    /// A simple equatable handle on `status` that we animate against. The
    /// associated values are case-stable enough for visual transitions.
    private var statusKey: String {
        switch viewModel.status {
        case .idle: return "idle"
        case .needsSetup: return "needsSetup"
        case .streaming: return "streaming"
        case .copied: return "copied"
        case .clarifying: return "clarifying"
        case .error: return "error"
        }
    }

    // MARK: - Status

    private var statusBar: some View {
        HStack(spacing: 8) {
            statusBarLeading
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

    @ViewBuilder
    private var statusBarLeading: some View {
        switch viewModel.status {
        case .streaming:
            ProgressView().controlSize(.small).scaleEffect(0.7)
        case .copied:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 11, weight: .semibold))
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11, weight: .semibold))
        case .clarifying:
            Image(systemName: "questionmark.diamond.fill")
                .foregroundStyle(.tint)
                .font(.system(size: 11, weight: .semibold))
        case .idle, .needsSetup:
            EmptyView()
        }
    }
}
