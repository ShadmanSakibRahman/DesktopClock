# DesktopClock

A minimal, iOS-style desktop clock for Windows. Native C# WPF, ~3 MB working-set RAM.

![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)
![.NET](https://img.shields.io/badge/.NET-Framework%204.x-512BD4)
![License](https://img.shields.io/badge/license-MIT-green)

## What it is

A floating, click-through clock that sits at the upper-center of your desktop. Time on top, day + date below — same typography rules as the iOS lockscreen.

- **12-hour format**, no AM/PM clutter
- **Day name + full date** below
- **Click-through** — never blocks desktop icons
- **No taskbar entry, no Alt-Tab presence** — pure cosmetic widget
- **Auto-positions** to upper-center on any screen resolution and DPI scale
- **Self-trims memory** every 5 minutes

## Why I built it

The Windows 11 Widgets panel uses 250-400 MB of RAM for a clock. Rainmeter is great but adds 30-60 MB plus a runtime. I wanted a desktop clock that's:

- Visually minimal (iOS-style typography, no chrome)
- Memory-efficient enough to leave running 24/7 on a low-RAM laptop
- A single small `.exe` with no dependencies beyond what Windows ships

## Memory footprint

| Stage | Working Set | Method |
|---|---|---|
| PowerShell-hosted WPF (initial prototype) | 112 MB | `Add-Type` + WPF inside `powershell.exe` |
| Native WPF C# (no optimization) | 75 MB | Compiled with `csc.exe`, default GC |
| Native + `EmptyWorkingSet` trim | **3.2 MB** | Final version |

The 3.2 MB working set is achieved by calling `EmptyWorkingSet` on `psapi.dll` after the first paint, paging out everything that isn't actively rendering. A 5-minute timer re-trims to keep it down. Private memory (~50 MB) is committed but mostly resides in standby/pagefile, so it doesn't pressure physical RAM.

## Install

Download from [Releases](../../releases) or build from source.

**Quick install:**

1. Download `DesktopClock-Install.exe`
2. Double-click it
3. SmartScreen may flag the installer (unsigned executable) — click **More info → Run anyway**

The installer:
- Copies `DesktopClock.exe` to `%LocalAppData%\DesktopClock\`
- Adds a Startup-folder shortcut for auto-launch on login
- Registers in **Settings → Apps → Installed apps** for clean removal
- Runs HKCU-only — no admin / UAC prompt

## Uninstall

Either:
- **Settings → Apps → Installed apps → DesktopClock → Uninstall**, or
- Double-click `DesktopClock-Uninstall.exe`

Both remove the binary, the startup shortcut, and the registry entry.

## Build from source

Requires Windows with .NET Framework 4.x (every Windows 10/11 ships with it — no SDK install needed).

```powershell
& '.\Build-DesktopClock.ps1'
```

The build uses `csc.exe` directly from `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\` — no MSBuild, no NuGet, no project file. Output is a single 8 KB `.exe`.

## Tech notes

- **WPF** for transparency + ClearType text rendering
- **Win32 P/Invoke** for `SetWindowLong` / `SetWindowPos` / `EmptyWorkingSet`
- Click-through via `WS_EX_TRANSPARENT` + `WS_EX_LAYERED` + `WS_EX_NOACTIVATE`
- Hidden from Alt-Tab / taskbar via `WS_EX_TOOLWINDOW`
- Sits at z-order bottom (`HWND_BOTTOM`) so it stays on the wallpaper, not over windows
- Manual two-TextBlock shadow (white behind, black in front) instead of `DropShadowEffect` — avoids loading the GPU shader pipeline

## Customization

Open `DesktopClock.cs` and tweak:

- `FontSize = 92` → bigger/smaller time
- `FontWeight = FontWeights.Medium` → `Light`, `Normal`, `SemiBold`, `Bold`
- `Foreground = ...Color.FromRgb(0x1A, 0x1A, 0x1A)` → any color
- `Top = 24` in `OnLoaded` → vertical position from top of screen

Then re-run `Build-DesktopClock.ps1` and the install script.

## License

MIT — see [LICENSE](LICENSE).
