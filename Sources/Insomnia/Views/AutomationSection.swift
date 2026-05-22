import SwiftUI

struct AutomationSection: View {
    @EnvironmentObject var appState: AppState
    @State private var newProcess = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Automation", systemImage: "gearshape.2")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)

            // Battery Safeguard
            HStack(spacing: 12) {
                Image(systemName: "battery.100.bolt")
                    .font(.title3)
                    .foregroundColor(.calmGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Battery Safeguard")
                        .font(.system(.body, design: .rounded, weight: .medium))
                    HStack(spacing: 4) {
                        Text("\(appState.batteryLevel)%")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(appState.isCharging ? .calmGreen : .activeYellow)
                            .contentTransition(.numericText())
                        Text(appState.isCharging ? "• Charging" : "• On Battery")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: $appState.batterySafeguardEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding(.vertical, 4)

            // Watched Processes
            VStack(alignment: .leading, spacing: 8) {
                Label("Watched Processes", systemImage: "terminal")
                    .font(.system(.body, design: .rounded, weight: .medium))

                if appState.watchedProcesses.isEmpty {
                    Text("No processes watched")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                } else {
                    ForEach(appState.watchedProcesses, id: \.self) { name in
                        HStack(spacing: 8) {
                            let running = appState.processStatus[name] ?? true
                            Circle()
                                .fill(running ? Color.activeYellow : Color.calmGreen)
                                .frame(width: 7, height: 7)

                            Text(name)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .monospaced()

                            Spacer()

                            if !running {
                                Text("done")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(.calmGreen)
                            }

                            Button {
                                appState.removeProcess(name)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            .help("Remove \(name)")
                        }
                        .padding(.leading, 4)
                    }
                }

                // Add process
                HStack(spacing: 6) {
                    TextField("Add process…", text: $newProcess)
                        .textFieldStyle(.plain)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .monospaced()
                        .onSubmit { addProcess() }

                    Button(action: addProcess) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.calmGreen)
                    }
                    .buttonStyle(.plain)
                    .disabled(newProcess.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func addProcess() {
        appState.addProcess(newProcess)
        newProcess = ""
    }
}
