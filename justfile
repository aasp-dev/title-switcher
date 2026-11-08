# List available recipes
default:
    @just --list

# Run the core logic tests
test:
    swift test

# Debug build
build:
    swift build

# Build the release app bundle at build/TitleSwitcher.app
bundle:
    ./scripts/bundle.sh

# Regenerate Resources/AppIcon.icns from scripts/make-icon.swift
icon:
    mkdir -p .build
    xcrun swiftc -O scripts/make-icon.swift -o .build/make-icon
    .build/make-icon Resources/AppIcon.icns

# Bundle, move it to /Applications (so app search finds only one copy), and launch it.
# Ad-hoc builds get a new signature each time, so the stale Accessibility grant is reset first.
install: bundle
    -pkill -x TitleSwitcher
    rm -rf /Applications/TitleSwitcher.app
    mv build/TitleSwitcher.app /Applications/
    [ -n "${SIGN_IDENTITY:-}" ] || tccutil reset Accessibility dev.local.TitleSwitcher
    open /Applications/TitleSwitcher.app

# Tag and push a release, e.g. `just release 0.2.0`
release version:
    git tag -m "v{{version}}" v{{version}}
    git push origin v{{version}}
