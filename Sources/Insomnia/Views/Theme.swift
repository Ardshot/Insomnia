import SwiftUI

extension Color {
    static let panelBackground = Color(nsColor: .windowBackgroundColor)
    static let activeYellow = Color(red: 1.0, green: 0.80, blue: 0.0)
    static let calmGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let deepPurple = Color(red: 0.40, green: 0.23, blue: 0.72)
    static let mutedText = Color(nsColor: .secondaryLabelColor)
}

extension View {
    func glass(cornerRadius: CGFloat = 14) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = 14) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

struct TimerButtonStyle: ButtonStyle {
    var isActive: Bool = false
    var color: Color = .activeYellow

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .rounded, weight: .semibold))
            .foregroundColor(isActive ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? color : Color(nsColor: .controlBackgroundColor))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }
}
