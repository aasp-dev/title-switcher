# TitleSwitcher

A lean, keyboard-driven window switcher for macOS: press a shortcut, get a list of window titles, type to search, hit return.

![TitleSwitcher palette](docs/screenshot.png)

## Features

- Lists every window by title in front-to-back order (most recent first), not grouped by app
- Predictable search: every word you type must appear in the window title or app name
- Number keys jump straight to a row
- Only needs the Accessibility permission (no Screen Recording, no Input Monitoring)
- Lives in the menu bar and has no Dock icon

## Usage

| Key | Action |
| --- | --- |
| **⌥⇥** | Open the palette |
| **⌥⇥** again, **⇥**, **↓** | Move down |
| **⇧⇥**, **↑** | Move up |
| **1–9** | Focus that row (works while still holding ⌥) |
| *type* | Filter by window title or app name |
| **↩** | Focus the selected window |
| **⎋** | Close the palette |

With no query, row 2 (your previous window) is preselected, so **⌥⇥ ↩** toggles between your two most recent windows.

TitleSwitcher lists the windows on the current Space, plus minimized ones.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+ (Xcode 15 or the Command Line Tools)

## Install

With [Homebrew](https://brew.sh):

```sh
brew install --cask aasp-dev/tap/title-switcher
open /Applications/TitleSwitcher.app
```

Upgrade with `brew upgrade --cask title-switcher`.

The app is not notarized. The cask clears the quarantine flag so macOS doesn't block it; if you install from the [latest release](https://github.com/aasp-dev/title-switcher/releases/latest) zip by hand, do that yourself:

```sh
xattr -dr com.apple.quarantine /Applications/TitleSwitcher.app
```

### Build from source

```sh
git clone https://github.com/aasp-dev/title-switcher.git
cd title-switcher
./scripts/bundle.sh                         # builds build/TitleSwitcher.app
cp -R build/TitleSwitcher.app /Applications/
open /Applications/TitleSwitcher.app
```

On first launch, macOS asks you to grant Accessibility access in **System Settings → Privacy & Security → Accessibility**. TitleSwitcher needs it to read window titles and focus windows.

The bundle is ad-hoc signed by default, so macOS treats every rebuild as a new app and asks for Accessibility again. To avoid that, sign with a stable certificate:

```sh
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./scripts/bundle.sh
```

To start TitleSwitcher at login, choose **Open at Login** from its menu bar icon.

## Development

Common commands are in the [justfile](justfile) (run `just` to list them):

```sh
just test       # run the core logic tests
just build      # debug build
just bundle     # release .app bundle
just install    # bundle, move to /Applications, and launch
just icon       # regenerate Resources/AppIcon.icns from scripts/make-icon.swift
```

To publish a release, push a version tag. CI runs the tests, builds the app, attaches `TitleSwitcher.zip` to a GitHub Release, and updates the cask in [aasp-dev/homebrew-tap](https://github.com/aasp-dev/homebrew-tap) (this needs a `HOMEBREW_TAP_TOKEN` secret with write access to that repo):

```sh
just release 0.1.0      # tags v0.1.0 and pushes it
```

The code is split into two targets:

- `SwitcherCore`: pure, tested logic (filtering, ordering, initial selection, digit keys)
- `TitleSwitcher`: the AppKit app (hotkey, palette UI, Accessibility window source)

## License

[MIT](LICENSE)
