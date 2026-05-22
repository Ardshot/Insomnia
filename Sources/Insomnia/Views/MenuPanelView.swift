import SwiftUI

struct MenuPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulseGlow = false

    private let timers: [(label: String, duration: TimeInterval)] = [
        ("15m", 900), ("30m", 1800), ("1h", 3600), ("2h", 7200),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            GlassDivider()

            toggleCard
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

            GlassDivider()

            timerSection
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Spacer()

            quitButton
                .padding(.bottom, 10)
                .padding(.trailing, 16)
        }
        .frame(width: 300)
        .background(
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 30, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseGlow.toggle()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Insomnia")
                .font(.system(.headline, design: .rounded, weight: .bold))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isActive ? Color.activeYellow : Color.secondary)
                    .frame(width: 8, height: 8)

                Text(appState.isActive ? "Awake" : "Sleeping")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(appState.isActive ? .activeYellow : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Toggle Card

    private var toggleCard: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                appState.toggle()
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: appState.isActive ? "eye.fill" : "eye.slash")
                    .font(.system(size: 44))
                    .foregroundColor(appState.isActive ? .activeYellow : .secondary)

                Text(appState.isActive ? "Insomnia is On" : "Insomnia is Off")
                    .font(.system(.title3, design: .rounded, weight: .semibold))

                if appState.isActive {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                        if appState.isTimed {
                            Text(appState.remainingDisplay)
                                .font(.system(.title2, design: .rounded, weight: .bold).monospacedDigit())
                                .contentTransition(.numericText())
                        } else {
                            Text("Indefinite")
                                .font(.system(.subheadline, design: .rounded))
                        }
                    }
                    .foregroundColor(.activeYellow)

                    Text("Tap to let your Mac sleep")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap to keep your Mac awake")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.activeYellow.opacity(appState.isActive ? (pulseGlow ? 0.5 : 0.15) : 0),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.activeYellow.opacity(appState.isActive ? (pulseGlow ? 0.35 : 0.05) : 0),
                radius: 24
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Timer")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(timers, id: \.duration) { t in
                    let isActive = appState.isActive && appState.isTimed
                        && abs(appState.remainingSeconds - Int(t.duration)) < 2
                    Button(t.label) {
                        withAnimation(.spring(response: 0.3)) {
                            appState.activateTimed(duration: t.duration)
                        }
                    }
                    .buttonStyle(TimerButtonStyle(isActive: isActive))
                }

                Button("∞") {
                    withAnimation(.spring(response: 0.3)) {
                        appState.activateIndefinite()
                    }
                }
                .buttonStyle(TimerButtonStyle(
                    isActive: appState.isIndefinite,
                    color: .deepPurple
                ))
            }
        }
    }

    // MARK: - Quit Button

    private var quitButton: some View {
        HStack {
            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Text("Quit Insomnia")
                        .font(.system(.caption, design: .rounded))
                    Text("⌘Q")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
