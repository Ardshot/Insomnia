import SwiftUI

struct MenuPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulseGlow = false
    @State private var showAppPicker = false
    @State private var runningApps = NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular }
    @State private var tick = Date()

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let timers: [(label: String, duration: TimeInterval)] = [
        ("15m", 900), ("30m", 1800), ("1h", 3600), ("2h", 7200),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            GlassDivider()

            heroCard
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            GlassDivider()

            sessionSelector
                .padding(.horizontal, 16)
                .padding(.top, 12)

            configPanel
                .padding(.horizontal, 16)
                .padding(.top, 6)

            GlassDivider()
                .padding(.top, 6)

            quickTimers
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Spacer(minLength: 0)

            quitButton
                .padding(.bottom, 8)
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
        .onReceive(tickTimer) { now in
            tick = now
            if appState.isActive && appState.isTimed && appState.remainingSeconds <= 0 {
                appState.deactivate()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Insomnia")
                .font(.system(.headline, design: .rounded, weight: .bold))

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(appState.isActive ? Color.activeYellow : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(appState.isActive ? "Awake" : "Sleeping")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(appState.isActive ? .activeYellow : .secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                appState.toggle()
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: appState.isActive ? "eye.fill" : "eye.slash")
                    .font(.system(size: 40))
                    .foregroundColor(appState.isActive ? .activeYellow : .secondary)

                Text(appState.isActive ? "Insomnia is On" : "Insomnia is Off")
                    .font(.system(.title3, design: .rounded, weight: .semibold))

                if appState.isActive {
                    if appState.isTimed {
                        Text(appState.remainingDisplay)
                            .font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                            .foregroundColor(.activeYellow)
                            .contentTransition(.numericText())
                    } else {
                        Text("Indefinite")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.activeYellow)
                    }

                    Text("Tap to let Mac sleep")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap to keep Mac awake")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .glassCard(cornerRadius: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color.activeYellow.opacity(appState.isActive ? (pulseGlow ? 0.5 : 0.15) : 0),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.activeYellow.opacity(appState.isActive ? (pulseGlow ? 0.3 : 0.05) : 0),
                radius: 20
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Selector Grid

    private var sessionSelector: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(Array(SessionMode.allCases.enumerated()), id: \.offset) { _, mode in
                Button {
                    appState.sessionMode = mode
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 11))
                        Text(mode.rawValue)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(appState.sessionMode == mode ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(appState.sessionMode == mode
                                  ? Color.activeYellow.opacity(0.85)
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
                .buttonStyle(TimerButtonStyle(
                    isActive: appState.timedDuration == t.duration,
                    color: .calmGreen
                ))
            }
        }
        .padding(.bottom, 4)
    }

    private var untilConfig: some View {
        HStack {
            DatePicker("Until", selection: $appState.untilTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
            Text("today")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var appConfig: some View {
        HStack {
            if let name = appState.targetAppName {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.calmGreen)
                        .font(.caption)
                    Text(name)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .lineLimit(1)
                    Button { appState.targetAppName = nil; appState.targetBundleID = nil } label: {
                        Image(systemName: "x.circle.fill")
                            .font(.caption)
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
                    Text("Choose app…")
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

            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var appPickerList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
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
                                    .frame(width: 16, height: 16)
                            }
                            Text(app.localizedName ?? app.bundleIdentifier ?? "Unknown")
                                .font(.system(.caption, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 200, height: min(CGFloat(runningApps.count) * 28 + 8, 220))
        .padding(4)
    }

    private var downloadConfig: some View {
        HStack {
            if let name = appState.downloadName {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.calmGreen)
                        .font(.caption)
                    Text(name)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button { appState.downloadPath = nil; appState.downloadName = nil } label: {
                        Image(systemName: "x.circle.fill")
                            .font(.caption)
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
                    Text(appState.downloadName ?? "Choose file…")
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

            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Quick Timers

    private var quickTimers: some View {
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
                .padding(.vertical, 4)
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
