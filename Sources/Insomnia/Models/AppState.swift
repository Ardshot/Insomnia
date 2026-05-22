import Foundation

class AppState: ObservableObject {
    @Published var isActive = false
    @Published var activeUntil: Date?
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
    var onActivate: ((TimeInterval?) -> Void)?
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

    func activateIndefinite() {
        isActive = true
        activeUntil = nil
        onActivate?(nil)
    }

    func activateTimed(duration: TimeInterval) {
        isActive = true
        activeUntil = Date().addingTimeInterval(duration)
        onActivate?(duration)
    }

    func deactivate() {
        isActive = false
        activeUntil = nil
        onDeactivate?()
    }

    func toggle() {
        if isActive { deactivate() }
        else { activateIndefinite() }
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
