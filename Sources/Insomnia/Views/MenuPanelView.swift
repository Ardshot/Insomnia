import SwiftUI

struct MenuPanelView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            headerView

            GlassDivider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    SessionConfigView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    GlassDivider()

                    AutomationSection()

                    GlassDivider()

                    footerView
                }
            }
        }
        .frame(width: 320)
        .background(
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 30, y: 8)
    }

    private var headerView: some View {
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

    private var footerView: some View {
        HStack(spacing: 6) {
            Image(systemName: appState.isCharging ? "bolt.fill" : "battery.25")
                .font(.system(size: 10))
                .foregroundColor(appState.isCharging ? .calmGreen : .activeYellow)

            Text("\(appState.batteryLevel)%")
                .font(.system(.caption, design: .rounded, weight: .medium))

            Text(appState.isCharging ? "• Power Adapter" : "• Battery")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()

            Text("⌘Q")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(.caption, design: .rounded))
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .onHover { h in
                if h { NSCursor.pointingHand.push() }
                else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
