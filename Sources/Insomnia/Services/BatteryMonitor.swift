import IOKit.ps
import Foundation

class BatteryMonitor {
    var onBatteryUpdate: ((Int, Bool) -> Void)?

    private var timer: Timer?

    func start(interval: TimeInterval = 5) {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return }
        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first else {
            onBatteryUpdate?(100, true)
            return
        }
        guard let desc = IOPSGetPowerSourceDescription(blob, first)?.takeUnretainedValue()
                as? [String: Any] else { return }

        let current = desc["CurrentCapacity"] as? Int ?? 0
        let maxCap = desc["MaxCapacity"] as? Int ?? 100
        let percent = maxCap > 0 ? (current * 100) / maxCap : 0

        let psState = desc["Power Source State"] as? String ?? ""
        let isCharging = psState == "AC Power"

        onBatteryUpdate?(percent, isCharging)
    }

    deinit { stop() }
}
