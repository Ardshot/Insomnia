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
    let sessionTimer = TimerManager()

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()
    private var isPanelShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        setupBindings()
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

        let panelSize = panel.contentView?.fittingSize ?? CGSize(width: 320, height: 480)
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

        appState.onActivate = { [weak self] duration in
            guard let self = self else { return }
            self.powerManager.preventSleep()
            self.updateIcon()
            if let d = duration {
                self.sessionTimer.start(duration: d)
            }
        }

        appState.onDeactivate = { [weak self] in
            guard let self = self else { return }
            self.powerManager.releaseAll()
            self.sessionTimer.stop()
            self.updateIcon()
        }

        batteryMonitor.onBatteryUpdate = { [weak self] level, charging in
            guard let self = self else { return }
            self.appState.batteryLevel = level
            self.appState.isCharging = charging

            if self.appState.batterySafeguardEnabled && !charging && level <= self.appState.batteryThreshold {
                self.powerManager.displaySleepAllowed = true
            } else if charging {
                self.powerManager.displaySleepAllowed = false
            }
        }

        sessionTimer.onTimerEnd = { [weak self] in
            self?.appState.deactivate()
        }

        watchdog.onAllFinished = { [weak self] in
            guard let self = self, self.appState.isActive else { return }
            DispatchQueue.main.async {
                self.appState.deactivate()
            }
        }
    }

    private func tick() {
        // Update the icon and panel when state changes
        if appState.isActive {
            // Force UI refresh for countdown display
        }
    }

    // MARK: - NSApplicationDelegate

    func applicationDidResignActive(_ notification: Notification) {
        if isPanelShown { closePanel() }
    }
}
