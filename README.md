# TitleSwitcher

A lean window switcher for macOS: a list of window titles with search.

- **⌥⇥** opens the palette (⌥⇥ again / ⇥ / ↓ moves down, ⇧⇥ / ↑ moves up)
- **1–9** jumps straight to that row (works while still holding ⌥)
- **type** to filter by window title or app name; every word must match
- **↩** focuses the selection, **⎋** closes, clicking a row focuses it

With no query, row 2 (your previous window) is preselected, so ⌥⇥ ↩ toggles between two windows.

Only needs the Accessibility permission (no Screen Recording). Lists windows on the current Space, plus minimized ones.

```sh
swift test               # core logic tests
./scripts/bundle.sh      # builds build/TitleSwitcher.app
open build/TitleSwitcher.app
```
