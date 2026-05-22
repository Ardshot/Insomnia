import Cocoa

class SessionManager {
    var onStop: (() -> Void)?

    private var timer: Timer?
    private var appObserver: NSObjectProtocol?
    private var filePath: String?
    private var lastSize: Int64 = -1
    private var stableChecks = 0

    func startIndefinite(using pm: PowerManager) {
        stop()
        pm.preventSleep()
    }

    func startTimed(duration: TimeInterval, using pm: PowerManager) {
        stop()
        pm.preventSleep()
        schedule(after: duration)
    }

    func startUntil(date: Date, using pm: PowerManager) {
        let d = date.timeIntervalSinceNow
        startTimed(duration: max(0, d), using: pm)
    }

    func startAppWatch(bundleID: String, using pm: PowerManager) {
        stop()
        pm.preventSleep()

        guard NSWorkspace.shared.runningApplications.contains(where: {
            $0.bundleIdentifier == bundleID
        }) else {
            DispatchQueue.main.async { [weak self] in self?.onStop?() }
            return
        }

        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication,
                  app.bundleIdentifier == bundleID
            else { return }
            self?.onStop?()
        }
    }

    func startFileWatch(path: String, using pm: PowerManager) {
        stop()
        pm.preventSleep()
        filePath = path
        lastSize = sizeOf(path)
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.checkFile(path)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let obs = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        appObserver = nil
        filePath = nil
        lastSize = -1
        stableChecks = 0
    }

    // MARK: - Private

    private func schedule(after: TimeInterval) {
        guard after > 0 else { onStop?(); return }
        timer = Timer(fire: Date().addingTimeInterval(after), interval: 0, repeats: false) { [weak self] _ in
            self?.onStop?()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkFile(_ path: String) {
        let size = sizeOf(path)
        if size == lastSize && size > 0 {
            stableChecks += 1
            if stableChecks >= 5 {
                onStop?()
            }
        } else {
            stableChecks = 0
        }
        lastSize = size
    }

    private func sizeOf(_ path: String) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return (attrs?[.size] as? Int64) ?? 0
    }

    deinit { stop() }
}
