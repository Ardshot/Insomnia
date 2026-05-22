import Foundation

enum SessionMode: String, CaseIterable {
    case indefinite = "Indefinite"
    case timed = "Timed"
    case untilTime = "Until"
    case whileAppRunning = "App Open"
    case whileFileDownloads = "Downloading"

    var symbol: String {
        switch self {
        case .indefinite: return "infinity"
        case .timed: return "timer"
        case .untilTime: return "clock.badge.checkmark"
        case .whileAppRunning: return "app.badge.checkmark"
        case .whileFileDownloads: return "arrow.down.doc"
        }
    }
}

class AppState: ObservableObject {
    @Published var isActive = false
    @Published var activeUntil: Date?
    @Published var sessionMode: SessionMode = .indefinite
    @Published var sessionTimedDuration: TimeInterval = 1800
    @Published var sessionUntilTime: Date = Calendar.current.date(
        bySettingHour: 18, minute: 0, second: 0, of: Date()
    ) ?? Date().addingTimeInterval(3600)
    @Published var targetAppBundleID: String?
    @Published var targetAppName: String?
    @Published var downloadFilePath: String?
    @Published var downloadFileName: String?

    @Published var batteryThreshold: Int = 20
    @Published var batterySafeguardEnabled = true
    @Published var batteryLevel: Int = 100
    @Published var isCharging = true
    @Published var watchedProcesses: [String] = ["npm", "python"] {
        didSet { onWatchedProcessesChanged?(watchedProcesses) }
    }
    @Published var processStatus: [String: Bool] = [:]
    @Published var allProcessesFinished = true

    var onWatchedProcessesChanged: (([String]) -> Void)?
    var onActivate: ((SessionMode?) -> Void)?
    var onDeactivate: (() -> Void)?

    var isTimed: Bool { isActive && activeUntil != nil }
    var isIndefinite: Bool { isActive && activeUntil == nil }

    var remainingSeconds: Int {
        guard let until = activeUntil else { return 0 }
        return max(0, Int(until.timeIntervalSince(Date())))
    }

    var remainingDisplay: String {
        let s = remainingSeconds
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        if m > 0 { return String(format: "%d:%02d", m, sec) }
        return String(format: "0:%02d", sec)
    }

    func startSession() {
        isActive = true
        onActivate?(sessionMode)
    }

    func deactivate() {
        isActive = false
        activeUntil = nil
        onDeactivate?()
    }

    func toggle() {
        if isActive { deactivate() }
        else { startSession() }
    }

    func addProcess(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !watchedProcesses.contains(trimmed) else { return }
        var updated = watchedProcesses
        updated.append(trimmed)
        watchedProcesses = updated
    }

    func removeProcess(_ name: String) {
        var updated = watchedProcesses
        updated.removeAll { $0 == name }
        watchedProcesses = updated
    }
}
