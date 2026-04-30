import AppKit
import SwiftUI

// Click-to-record hotkey field. The button shows the current combo; click
// it to enter recording mode, then press any modifier+key combination —
// the next keyDown is captured. Esc cancels without changing the combo.
struct HotkeyRecorder: View {
    @Binding var combo: KeyCombo

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: { recording.toggle() }) {
            HStack(spacing: 6) {
                Text(recording ? "Press a shortcut…" : combo.display)
                    .font(.system(.body, design: .monospaced).monospacedDigit())
                    .foregroundStyle(recording ? Color.accentColor : Color.primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if recording {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minWidth: 130)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        recording ? Color.accentColor : Color.secondary.opacity(0.18),
                        lineWidth: recording ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onChange(of: recording) { _, isRecording in
            if isRecording { startCapture() } else { stopCapture() }
        }
        .onDisappear { stopCapture() }
    }

    private func startCapture() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Esc cancels without committing.
            if event.keyCode == 53 {
                Task { @MainActor in self.recording = false }
                return nil
            }
            if let new = KeyCombo(from: event) {
                Task { @MainActor in
                    self.combo = new
                    self.recording = false
                }
                return nil
            }
            // Bare key with no modifier — ignore. Keep recording.
            return nil
        }
    }

    private func stopCapture() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
