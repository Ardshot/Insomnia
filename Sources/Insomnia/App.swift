import SwiftUI
import Combine

@main
struct InsomniaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let powerManager = PowerManager()
    let batteryMonitor = BatteryMonitor()
    let watchdog = ProcessWatchdog()
    let sessionManager = SessionManager()
    let sessionTimer = TimerManager()

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()
    private var isPanelShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        setupBindings()
        setupKeyboardShortcuts()
        watchdog.setProcesses(appState.watchedProcesses)
        batteryMonitor.start()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        if let button = statusItem.button {
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName = appState.isActive ? "eye.fill" : "eye.slash"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: appState.isActive ? "Active" : "Inactive")
        image?.isTemplate = !appState.isActive
        button.image = image
        if appState.isActive {
            button.contentTintColor = .systemYellow
        } else {
            button.contentTintColor = nil
        }
    }

    // MARK: - Keyboard Shortcuts

    private var shortcutMonitor: Any?

    private func setupKeyboardShortcuts() {
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let chars = event.charactersIgnoringModifiers?.lowercased()

            if cmd && chars == "i" {
                self.appState.toggle()
                if self.isPanelShown { self.closePanel() }
                return nil
            }

            if cmd && chars == "q" {
                self.cleanQuit()
                return nil
            }

            return event
        }
    }

    // MARK: - Clean Quit

    private func cleanQuit() {
        sessionManager.stop()
        sessionTimer.stop()
        powerManager.releaseAll()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Panel

    private func setupPanel() {
        let contentView = MenuPanelView()
            .environmentObject(appState)

        let hosting = NSHostingView(rootView: contentView)
        let size = hosting.fittingSize

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isOpaque = false
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 16
        panel.contentView?.layer?.masksToBounds = true
    }

    @objc private func togglePanel() {
        if isPanelShown {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = button.window?.convertToScreen(buttonRect) ?? .zero

        let panelSize = panel.contentView?.fittingSize ?? CGSize(width: 320, height: 580)
        let x = screenRect.midX - panelSize.width / 2
        let y = screenRect.minY - panelSize.height - 4

        panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        isPanelShown = true
    }

    private func closePanel() {
        panel.orderOut(nil)
        isPanelShown = false
    }

    // MARK: - Bindings

    private func setupBindings() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
            .store(in: &cancellables)

        appState.onWatchedProcessesChanged = { [weak self] processes in
            self?.watchdog.setProcesses(processes)
        }

        appState.onActivate = { [weak self] mode in
            guard let self = self, let mode = mode else { return }
            switch mode {
            case .indefinite:
                self.sessionManager.start(.indefinite, using: self.powerManager)

            case .timed:
                let duration = self.appState.sessionTimedDuration
                self.appState.activeUntil = Date().addingTimeInterval(duration)
                self.sessionTimer.start(duration: duration)
                self.sessionManager.start(.timed(duration), using: self.powerManager)

            case .untilTime:
                let date = self.appState.sessionUntilTime
                self.appState.activeUntil = date
                self.sessionTimer.start(until: date)
                self.sessionManager.start(.untilTime(date), using: self.powerManager)

            case .whileAppRunning:
                guard let bundleID = self.appState.targetAppBundleID,
                      let name = self.appState.targetAppName else { return }
                self.sessionManager.start(.whileAppRunning(bundleID: bundleID, appName: name),
                                          using: self.powerManager)

            case .whileFileDownloads:
                guard let path = self.appState.downloadFilePath else { return }
                self.sessionManager.start(.whileFileDownloads(path: path),
                                          using: self.powerManager)
            }

            self.updateIcon()
            if self.isPanelShown { self.closePanel() }
        }

        appState.onDeactivate = { [weak self] in
            guard let self = self else { return }
            self.sessionTimer.stop()
            self.sessionManager.stop()
            self.powerManager.releaseAll()
            self.updateIcon()
        }

        sessionTimer.onTimerEnd = { [weak self] in
            self?.appState.deactivate()
        }

        sessionManager.onStop = { [weak self] in
            self?.appState.deactivate()
        }

        batteryMonitor.onBatteryUpdate = { [weak self] level, charging in
            guard let self = self else { return }
            self.appState.batteryLevel = level
            self.appState.isCharging = charging

            guard self.appState.isActive else { return }

            if self.appState.batterySafeguardEnabled && !charging && level <= self.appState.batteryThreshold {
                self.powerManager.displaySleepAllowed = true
            } else if charging || level > self.appState.batteryThreshold {
                self.powerManager.displaySleepAllowed = false
            }
        }

        watchdog.onAllFinished = { [weak self] in
            guard let self = self, self.appState.isActive else { return }
            DispatchQueue.main.async {
                self.appState.deactivate()
            }
        }
    }

    private func tick() {
        appState.allProcessesFinished = watchdog.allFinished
        appState.processStatus = watchdog.status
    }

    // MARK: - NSApplicationDelegate

    func applicationDidResignActive(_ notification: Notification) {
        if isPanelShown { closePanel() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanQuit()
    }
}
