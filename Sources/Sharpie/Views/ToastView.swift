import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .labelStyle(.titleAndIcon)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.green.opacity(0.9), in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
    }
}
