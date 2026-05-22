import SwiftUI

struct TimerGrid: View {
    @EnvironmentObject var appState: AppState

    let timers: [(label: String, duration: TimeInterval)] = [
        ("15m", 900),
        ("30m", 1800),
        ("1h", 3600),
        ("2h", 7200),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Timer", systemImage: "timer")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(timers, id: \.duration) { t in
                    let isTimedActive = appState.isActive
                        && appState.activeUntil != nil
                        && abs(Double(appState.remainingSeconds) - t.duration) < 2
                    Button(t.label) {
                        withAnimation(.spring(response: 0.4)) {
                            appState.sessionMode = .timed
                            appState.sessionTimedDuration = t.duration
                            appState.startSession()
                        }
                    }
                    .buttonStyle(TimerButtonStyle(isActive: isTimedActive))
                }

                Button("∞") {
                    withAnimation(.spring(response: 0.4)) {
                        appState.sessionMode = .indefinite
                        appState.startSession()
                    }
                }
                .buttonStyle(TimerButtonStyle(
                    isActive: appState.isIndefinite,
                    color: .deepPurple
                ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
