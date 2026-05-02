import SwiftUI

/// The single piece of system feedback in the Sharpie window. A 1pt-tall
/// line at the bottom of the surface that conveys state through movement
/// and color rather than words:
///
///   - idle:    invisible (a bare hairline at 4% opacity)
///   - working: a traveling pulse loops left → right indefinitely; a faint
///              seconds counter ghosts in past 3s so the user knows the
///              wait is real
///   - copied:  glows green for 400ms, then fades back to idle
///   - error:   glows red for ~600ms, then fades back to idle
///
/// No "Copied" toast view, no "Sharpening with Claude Code…" text. Motion
/// and color carry the meaning.
struct StateHairline: View {

    enum Mode: Equatable {
        case idle
        case working(elapsed: TimeInterval)
        case copied
        case error
    }

    var state: Mode

    @State private var pulseTrip: CGFloat = 0  // 0 → 1, animated when working

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                // Base hairline — present in every state, just very faint
                // when idle so the user sees a "rail" the activity rides on.
                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                switch state {
                case .idle:
                    EmptyView()

                case .working:
                    // Traveling pulse: a 22%-wide gradient sliver loops
                    // left to right at ~1.4s per loop. Continuous motion is
                    // the only "we're alive" cue the user needs.
                    let pulseWidth = w * 0.22
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.0),
                            Color.accentColor.opacity(0.85),
                            Color.accentColor.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: pulseWidth, height: 2)
                    .offset(x: -pulseWidth + (w + pulseWidth) * pulseTrip)
                    .blur(radius: 1.0)
                    .onAppear { startPulse() }

                case .copied:
                    Rectangle()
                        .fill(Color.green.opacity(0.85))
                        .frame(height: 2)
                        .blur(radius: 0.6)
                        .transition(.opacity)

                case .error:
                    Rectangle()
                        .fill(Color.red.opacity(0.85))
                        .frame(height: 2)
                        .blur(radius: 0.6)
                        .transition(.opacity)
                }
            }
            // Past the 3-second mark, ghost in a tiny seconds counter at
            // the trailing edge. Rendered as a chip with a translucent
            // backdrop so the traveling pulse passing under it doesn't
            // make the digits flicker.
            .overlay(alignment: .trailing) {
                if case let .working(elapsed) = state, elapsed >= 3 {
                    Text(String(format: "%.0fs", elapsed))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.trailing, 4)
                        .transition(.opacity)
                }
            }
        }
        .frame(height: 16)
        .animation(.easeInOut(duration: 0.2), value: stateKey)
    }

    /// Drives the traveling pulse by repeatedly animating `pulseTrip` from
    /// 0 to 1 and resetting. Implicit animation handles the smoothing.
    private func startPulse() {
        pulseTrip = 0
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            pulseTrip = 1
        }
    }

    /// Stable key used to drive the .animation modifier between top-level
    /// state transitions (the inner views handle their own subtleties).
    private var stateKey: String {
        switch state {
        case .idle: return "idle"
        case .working: return "working"
        case .copied: return "copied"
        case .error: return "error"
        }
    }
}
