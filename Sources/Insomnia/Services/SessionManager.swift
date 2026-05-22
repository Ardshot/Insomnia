import Cocoa

class SessionManager {
    var onStop: (() -> Void)?

    private var timer: Timer?
    private var appObserver: NSObjectProtocol?
    private var filePath: String?
    private var lastFileSize: Int64 = -1
    private var stableChecks: Int = 0

    var kind: SessionKind = .indefinite

    enum SessionKind: Equatable {
        case indefinite
        case timed(TimeInterval)
        case untilTime(Date)
        case whileAppRunning(bundleID: String, appName: String)
        case whileFileDownloads(path: String)
    }

    func start(_ kind: SessionKind, using powerManager: PowerManager) {
        stop()
        self.kind = kind
        powerManager.preventSleep()

        switch kind {
        case .indefinite:
            break

        case .timed(let duration):
            scheduleTimer(date: Date().addingTimeInterval(duration))

        case .untilTime(let date):
            scheduleTimer(date: date)

        case .whileAppRunning(let bundleID, _):
            startAppWatcher(bundleID: bundleID)

        case .whileFileDownloads(let path):
            startFileWatcher(path: path)
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
        lastFileSize = -1
        stableChecks = 0
    }

    // MARK: - Timer

    private func scheduleTimer(date: Date) {
        timer?.invalidate()
        timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            self?.onStop?()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    // MARK: - App watcher

    private func startAppWatcher(bundleID: String) {
        let running = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID
        }
        guard running else {
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

    // MARK: - File watcher

    private func startFileWatcher(path: String) {
        filePath = path
        lastFileSize = currentFileSize(at: path)
        stableChecks = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.checkFile(path: path)
        }
    }

    private func checkFile(path: String) {
        let size = currentFileSize(at: path)
        if size == lastFileSize && size > 0 {
            stableChecks += 1
            if stableChecks >= 5 {
                onStop?()
            }
        } else {
            stableChecks = 0
        }
        lastFileSize = size
    }

    private func currentFileSize(at path: String) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return (attrs?[.size] as? Int64) ?? 0
    }

    deinit { stop() }
}
