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
    let sessionTimer = TimerManager()
    let sessionManager = SessionManager()

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()
    private var isPanelShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        setupBindings()
        setupKeyboardShortcuts()
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
        if let monitor = shortcutMonitor {
            NSEvent.removeMonitor(monitor)
            shortcutMonitor = nil
        }
        sessionTimer.stop()
        sessionManager.stop()
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

        let panelSize = panel.contentView?.fittingSize ?? CGSize(width: 300, height: 420)
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
        appState.onActivate = { [weak self] mode in
            guard let self = self, let mode = mode else { return }

            switch mode {
            case .indefinite:
                self.sessionManager.startIndefinite(using: self.powerManager)
                self.appState.activeUntil = nil

            case .timed:
                let d = self.appState.timedDuration
                self.sessionManager.startTimed(duration: d, using: self.powerManager)
                self.appState.activeUntil = Date().addingTimeInterval(d)

                self.sessionTimer.start(duration: d)

            case .untilTime:
                self.sessionManager.startUntil(date: self.appState.untilTime, using: self.powerManager)
                self.appState.activeUntil = self.appState.untilTime

                let d = self.appState.untilTime.timeIntervalSinceNow
                if d > 0 {
                    self.sessionTimer.start(duration: d)
                }

            case .whileAppRunning:
                guard let bundleID = self.appState.targetBundleID else {
                    self.appState.deactivate()
                    return
                }
                self.appState.activeUntil = nil
                self.sessionManager.startAppWatch(bundleID: bundleID, using: self.powerManager)

            case .whileFileDownloads:
                guard let path = self.appState.downloadPath else {
                    self.appState.deactivate()
                    return
                }
                self.appState.activeUntil = nil
                self.sessionManager.startFileWatch(path: path, using: self.powerManager)
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
            DispatchQueue.main.async {
                self?.appState.deactivate()
            }
        }
    }

    // MARK: - NSApplicationDelegate

    func applicationWillTerminate(_ notification: Notification) {
        cleanQuit()
    }
}
