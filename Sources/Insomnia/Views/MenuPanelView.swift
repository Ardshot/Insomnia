import SwiftUI

struct MenuPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulseGlow = false
    @State private var showAppPicker = false
    @State private var showFilePicker = false
    @State private var runningApps = NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular }

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

            modePicker
                .padding(.horizontal, 16)
                .padding(.top, 12)

            configPanel
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 0)

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

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(SessionMode.allCases, id: \.self) { mode in
                Button {
                    appState.sessionMode = mode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 10))
                        Text(mode.rawValue)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                    }
                    .foregroundColor(appState.sessionMode == mode ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(appState.sessionMode == mode
                                  ? Color.activeYellow.opacity(0.8)
                                  : Color(nsColor: .controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Config Panel

    @ViewBuilder
    private var configPanel: some View {
        switch appState.sessionMode {
        case .indefinite:
            EmptyView()
        case .timed:
            timedConfig
        case .untilTime:
            untilConfig
        case .whileAppRunning:
            appConfig
        case .whileFileDownloads:
            downloadConfig
        }
    }

    private var timedConfig: some View {
        HStack(spacing: 6) {
            ForEach(timers, id: \.duration) { t in
                Button(t.label) {
                    appState.timedDuration = t.duration
                }
                .buttonStyle(TimerButtonStyle(isActive: appState.timedDuration == t.duration,
                                              color: .calmGreen))
            }

            Text("\(Int(appState.timedDuration / 60))m")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
        }
        .padding(.bottom, 12)
    }

    private var untilConfig: some View {
        HStack {
            DatePicker("", selection: $appState.untilTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .scaleEffect(0.85)

            Text("today")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.bottom, 12)
    }

    private var appConfig: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = appState.targetAppName {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.calmGreen)
                        .font(.caption)
                    Text(name)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                    Button { appState.targetAppName = nil; appState.targetBundleID = nil } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                runningApps = NSWorkspace.shared.runningApplications
                    .filter { $0.activationPolicy == .regular }
                showAppPicker.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                    Text("Choose an app…")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAppPicker, arrowEdge: .trailing) {
                appPickerList
            }
        }
        .padding(.bottom, 12)
    }

    private var appPickerList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(runningApps, id: \.processIdentifier) { app in
                    Button {
                        appState.targetBundleID = app.bundleIdentifier
                        appState.targetAppName = app.localizedName ?? app.bundleIdentifier ?? "App"
                        showAppPicker = false
                    } label: {
                        HStack(spacing: 8) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            Text(app.localizedName ?? app.bundleIdentifier ?? "Unknown")
                                .font(.system(.caption, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 200, height: min(CGFloat(runningApps.count) * 32 + 8, 250))
        .padding(4)
    }

    private var downloadConfig: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = appState.downloadName {
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.calmGreen)
                        .font(.caption)
                    Text(name)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button { appState.downloadPath = nil; appState.downloadName = nil } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                let panel = NSOpenPanel()
                panel.canChooseFiles = true
                panel.canChooseDirectories = false
                panel.allowsMultipleSelection = false
                panel.begin { response in
                    guard response == .OK, let url = panel.url else { return }
                    appState.downloadPath = url.path
                    appState.downloadName = url.lastPathComponent
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                    Text(appState.downloadName ?? "Choose a file…")
                }
                .font(.system(.caption, design: .rounded))
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
        .padding(.bottom, 12)
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

#Preview {
    MenuPanelView()
        .environmentObject(AppState())
}
