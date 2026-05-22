import Foundation

class ProcessWatchdog {
    @Published var watched: [String] = []
    @Published var status: [String: Bool] = [:]
    @Published var allFinished = true

    var onAllFinished: (() -> Void)?

    private var timer: Timer?

    func setProcesses(_ names: [String]) {
        watched = names
        status = Dictionary(uniqueKeysWithValues: names.map { ($0, true) })
        if names.isEmpty {
            timer?.invalidate()
            timer = nil
            allFinished = true
        } else {
            start()
        }
    }

    func start() {
        timer?.invalidate()
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        var anyRunning = false
        for name in watched {
            let running = processExists(name)
            status[name] = running
            if running { anyRunning = true }
        }
        let done = !anyRunning
        if done && !allFinished {
            onAllFinished?()
        }
        allFinished = done
    }

    private func processExists(_ name: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-x", name]

        let out = Pipe()
        let err = Pipe()
        task.standardOutput = out
        task.standardError = err

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    deinit { stop() }
}
