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
        guard duration > 0 else { onTimerEnd?(); return }
        endDate = Date().addingTimeInterval(duration)
        schedule()
    }

    func start(until date: Date) {
        let d = date.timeIntervalSinceNow
        start(duration: max(0, d))
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    private func schedule() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remaining <= 0 {
                self.stop()
                self.onTimerEnd?()
            }
        }
    }

    deinit { stop() }
}
