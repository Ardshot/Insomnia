import SwiftUI

struct ToggleSection: View {
    @EnvironmentObject var appState: AppState

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                appState.toggle()
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: appState.isActive ? "eye.fill" : "eye.slash")
                    .font(.system(size: 40))
                    .foregroundColor(appState.isActive ? Color.activeYellow : .secondary)
                    .padding(.bottom, 4)

                Text(appState.isActive ? "Insomnia is Active" : "Insomnia is Off")
                    .font(.system(.title3, design: .rounded, weight: .semibold))

                if appState.isActive {
                    if appState.isTimed {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text(appState.remainingDisplay)
                                .font(.system(.title2, design: .rounded, weight: .bold).monospacedDigit())
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(.activeYellow)
                    } else {
                        Text("Indefinite — tap to stop")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Tap to keep your Mac awake")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(appState.isActive ? Color.activeYellow.opacity(isHovered ? 0.6 : 0.3) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = h }
        }
    }
}
