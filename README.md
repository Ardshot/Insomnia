# Insomnia

A premium, ultra-minimalist macOS Menu Bar utility designed to keep your Mac awake on your own terms.

![](https://img.shields.io/badge/macOS-13%2B-blue) ![](https://img.shields.io/badge/Swift-5.9-orange) ![](https://img.shields.io/badge/license-MIT-green)

## Overview

Insomnia is a premium, ultra-minimalist macOS Menu Bar utility designed to keep your Mac awake on your own terms.

## Features

**Pure Menu Bar Experience** — Runs invisibly in the status bar with zero Dock clutter.

**Intuitive Visual UX** — Features a gorgeous central Hero Card with an animated Eye icon that opens (`eye.fill`) when active and closes (`eye.slash`) when inactive.

**Versatile Session Controls** — Easily trigger Indefinite sessions, custom Timed countdowns, or set specific 'Until Time' parameters using beautiful native glassmorphic selectors.

**Live Countdown** — A fully reactive, ticking countdown timer shows exactly how much awake time is remaining before your Mac safely returns to its default sleep cycle.

**Smart Sleep Prevention** — Uses native IOKit assertions (`NoIdleSleep` + `NoDisplaySleep`) to keep your Mac awake reliably. The same technology used by Amphetamine and Caffeine.

**Dynamic Menu Bar Icon** — The eye icon changes states:
- `eye.slash` (dimmed) — Mac can sleep normally
- `eye.fill` (bright yellow) — Mac is being kept awake

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

1. Download the latest release from the [Releases](https://github.com/Ardshot/Insomnia/releases) page.
2. Move `Insomnia.app` to your Applications folder.
3. Open it. The eye icon appears in your menu bar.
4. Click the eye to open the panel. Tap the hero card to activate.

### Build from Source

```bash
git clone https://github.com/Ardshot/Insomnia.git
cd Insomnia
./build.sh
```

Then open `Insomnia.app` from the project directory.

## How It Works

Insomnia uses IOKit power management assertions to prevent the Mac from sleeping:
- `kIOPMAssertionTypeNoIdleSleep` — Prevents idle sleep (system stays awake)
- `kIOPMAssertionTypeNoDisplaySleep` — Prevents display sleep (screen stays on)

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
│       │   ├── SessionManager.swift   # Session orchestration (app/file timers)
│       │   └── TimerManager.swift     # Background session timer
│       └── Views/
│           ├── MenuPanelView.swift    # Main dropdown panel
│           └── Theme.swift            # Colors, glass styles
└── build.sh
```

## License

MIT
