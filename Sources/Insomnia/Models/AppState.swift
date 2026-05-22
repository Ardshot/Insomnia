import Foundation

class AppState: ObservableObject {
    @Published var isActive = false
    @Published var activeUntil: Date?

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
}
