import Foundation

enum SessionMode: String, CaseIterable {
    case indefinite = "Indefinite"
    case timed = "Timed"
    case untilTime = "Until"
    case whileAppRunning = "App Open"
    case whileFileDownloads = "Download"

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
    @Published var timedDuration: TimeInterval = 1800
    @Published var untilTime: Date = Calendar.current.date(
        bySettingHour: 18, minute: 0, second: 0, of: Date()
    ) ?? Date().addingTimeInterval(3600)
    @Published var targetBundleID: String?
    @Published var targetAppName: String?
    @Published var downloadPath: String?
    @Published var downloadName: String?

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

    // Start the currently configured mode
    func startCurrent() {
        isActive = true
        onActivate?(sessionMode)
    }

    func activateIndefinite() {
        sessionMode = .indefinite
        startCurrent()
    }

    func activateTimed(duration: TimeInterval) {
        sessionMode = .timed
        timedDuration = duration
        startCurrent()
    }

    func deactivate() {
        isActive = false
        activeUntil = nil
        onDeactivate?()
    }

    func toggle() {
        if isActive { deactivate() }
        else { startCurrent() }
    }
}
