import Foundation

class TimerManager {
    var onTimerEnd: (() -> Void)?

    private var timer: Timer?
    private(set) var endDate: Date?

    var remaining: TimeInterval {
        guard let end = endDate else { return 0 }
        return max(0, end.timeIntervalSinceNow)
    }

    var isRunning: Bool { timer != nil }

    func start(duration: TimeInterval) {
        stop()
        endDate = Date().addingTimeInterval(duration)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remaining <= 0 {
                self.stop()
                self.onTimerEnd?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    deinit { stop() }
}
