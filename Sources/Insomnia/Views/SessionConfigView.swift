import SwiftUI

struct SessionConfigView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            modePicker

            if !appState.isActive {
                configPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            toggleButton
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Session")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.leading, 2)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
            ], spacing: 6) {
                ForEach(SessionMode.allCases, id: \.self) { mode in
                    modeButton(mode)
                }
            }
        }
    }

    private func modeButton(_ mode: SessionMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                appState.sessionMode = mode
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 14))
                Text(mode.rawValue)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(appState.sessionMode == mode
                          ? Color.accentColor.opacity(0.2)
                          : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(appState.sessionMode == mode
                            ? Color.accentColor.opacity(0.5)
                            : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
            appPickerConfig

        case .whileFileDownloads:
            filePickerConfig
        }
    }

    // MARK: Timed Config

    private var timedConfig: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("", selection: $appState.sessionTimedDuration) {
                ForEach(timedOptions, id: \.self) { option in
                    Text(timedLabel(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private let timedOptions: [TimeInterval] = [
        300, 600, 900, 1800, 2700, 3600, 5400, 7200, 10800, 14400, 28800, 43200, 86400
    ]

    private func timedLabel(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let h = m / 60
        if h >= 1 && m % 60 == 0 { return "\(h)h" }
        if m >= 60 { return "\(h)h \(m % 60)m" }
        return "\(m)m"
    }

    // MARK: Until-Time Config

    private var untilConfig: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker(
                "End time",
                selection: $appState.sessionUntilTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedDurationUntil)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var formattedDurationUntil: String {
        let d = appState.sessionUntilTime.timeIntervalSinceNow
        guard d > 0 else { return "in the past" }
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        if h > 0 { return "(\(h)h \(m)m)" }
        return "(\(m)m)"
    }

    // MARK: App Picker Config

    private var appPickerConfig: some View {
        HStack(spacing: 8) {
            Image(systemName: "app")
                .font(.caption)
                .foregroundColor(.secondary)

            if let name = appState.targetAppName {
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .lineLimit(1)
                    Text("monitoring active")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Choose an app to watch")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                ForEach(runningApps, id: \.bundleIdentifier) { app in
                    Button {
                        appState.targetAppBundleID = app.bundleIdentifier
                        appState.targetAppName = app.localizedName
                    } label: {
                        HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            Text(app.localizedName ?? "Unknown")
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down.circle")
                    .foregroundColor(.calmGreen)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    // MARK: File Picker Config

    private var filePickerConfig: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc")
                .font(.caption)
                .foregroundColor(.secondary)

            if let name = appState.downloadFileName {
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .lineLimit(1)
                    Text("waiting for download")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Select a downloading file")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                selectFile()
            } label: {
                Image(systemName: "folder.badge.plus")
                    .foregroundColor(.calmGreen)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                appState.downloadFilePath = url.path
                appState.downloadFileName = url.lastPathComponent
            }
        }
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                appState.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: appState.isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isActive ? "Stop Session" : "Start Session")
                        .font(.system(.body, design: .rounded, weight: .semibold))

                    if appState.isActive {
                        Text(sessionActiveLabel)
                            .font(.system(.caption, design: .rounded))
                    } else {
                        Text(appState.sessionMode.rawValue)
                            .font(.system(.caption, design: .rounded))
                    }
                }

                Spacer()

                if appState.isActive, appState.sessionMode == .timed || appState.sessionMode == .untilTime {
                    Text(appState.remainingDisplay)
                        .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                        .contentTransition(.numericText())
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(appState.isActive ? AnyShapeStyle(Color.rose) : AnyShapeStyle(Color.accentGradient))
            )
        }
        .buttonStyle(.plain)
        .disabled(startDisabled)
    }

    private var startDisabled: Bool {
        guard !appState.isActive else { return false }
        switch appState.sessionMode {
        case .indefinite:
            return false
        case .timed:
            return false
        case .untilTime:
            return appState.sessionUntilTime.timeIntervalSinceNow <= 0
        case .whileAppRunning:
            return appState.targetAppBundleID == nil
        case .whileFileDownloads:
            return appState.downloadFilePath == nil
        }
    }

    private var sessionActiveLabel: String {
        let timeFmt = DateFormatter()
        timeFmt.timeStyle = .short
        switch appState.sessionMode {
        case .indefinite: return "Indefinite"
        case .timed: return "Timed"
        case .untilTime: return "Until \(timeFmt.string(from: appState.sessionUntilTime))"
        case .whileAppRunning: return "Watching: \(appState.targetAppName ?? "app")"
        case .whileFileDownloads: return "Downloading: \(appState.downloadFileName ?? "file")"
        }
    }
}
