# Insomnia

A premium, native macOS menu bar application that intelligently prevents your Mac from sleeping — the modern successor to Amphetamine.

![](https://img.shields.io/badge/macOS-13%2B-blue) ![](https://img.shields.io/badge/Swift-5.9-orange) ![](https://img.shields.io/badge/license-MIT-green)

## Overview

Insomnia lives quietly in your menu bar. Click the eye icon to keep your Mac awake indefinitely, or use a quick timer. What sets it apart is its **intelligent automation** — it watches your battery level and running terminal processes, so your Mac stays awake when you need it and sleeps when you don't.

No dock icon. No cluttered preferences window. Just a beautiful glass dropdown panel with everything you need.

## Features

**Smart Sleep Prevention** — Uses native IOKit assertions (`NoIdleSleep` + `NoDisplaySleep`) to keep your Mac awake reliably. The same technology used by Amphetamine and Caffiene.

**Dynamic Menu Bar Icon** — The eye icon changes states:
- `eye.slash` (dimmed) — Mac can sleep normally
- `eye.fill` (bright) — Mac is being kept awake

**Quick Timers** — 15m, 30m, 1h, 2h, or ∞. Select one and Insomnia handles the rest.

**Battery Safeguard** — When running on battery, if the charge drops below your threshold, Insomnia gracefully releases the display sleep assertion while keeping the system awake — saving power without interrupting your work.

**Terminal Process Watchdog** — Add process names like `npm`, `python`, `xcodebuild`, or `cargo`. Insomnia monitors them, and when they finish, it automatically releases the sleep assertion. Perfect for long builds, data processing, or downloads.

**Pure Menu Bar Architecture** — `LSUIElement = YES`. No dock icon, no window management — just a status item and an elegant dropdown panel.

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

1. Download the latest release from the [Releases](https://github.com/Ardshot/Insomnia/releases) page.
2. Move `Insomnia.app` to your Applications folder.
3. Open it. The eye icon appears in your menu bar.
4. Click the eye to activate. Click the timer buttons for timed sessions.

### Build from Source

```bash
git clone https://github.com/Ardshot/Insomnia.git
cd Insomnia
./build.sh
```

Then open `Insomnia.app` from the project directory.

## How It Works

### Sleep Assertions
Insomnia uses IOKit power management assertions to prevent the Mac from sleeping:
- `kIOPMAssertionTypeNoIdleSleep` — Prevents idle sleep (system stays awake)
- `kIOPMAssertionTypeNoDisplaySleep` — Prevents display sleep (screen stays on)

When battery safeguard kicks in, only the display assertion is released — the system keeps running but the screen can dim.

### Process Watchdog
Insomnia runs `pgrep -x <process>` every 2 seconds for each watched process. When all watched processes exit, Insomnia automatically ends its session and lets the Mac sleep. Add build tools, data processing scripts, or any CLI tool you want to wait for.

## Project Structure

```
Insomnia/
├── Package.swift
├── Sources/
│   └── Insomnia/
│       ├── App.swift              # @main + AppDelegate (status bar, panel, bindings)
│       ├── Info.plist             # LSUIElement = YES config
│       ├── Models/
│       │   └── AppState.swift     # Observable app state
│       ├── Services/
│       │   ├── PowerManager.swift     # IOKit assertion management
│       │   ├── BatteryMonitor.swift   # Power source monitoring
│       │   ├── ProcessWatchdog.swift  # pgrep-based process watcher
│       │   └── TimerManager.swift     # Session timer
│       └── Views/
│           ├── MenuPanelView.swift    # Main dropdown panel
│           ├── ToggleSection.swift    # Big activate/deactivate button
│           ├── TimerGrid.swift        # Quick timer buttons
│           ├── AutomationSection.swift # Battery + process status
│           └── Theme.swift            # Colors, glass styles
└── build.sh
```

## License

MIT
