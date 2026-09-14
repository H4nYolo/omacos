---
status: accepted
---

# The native Panel is written in Swift, not Rust

The fzf popups start a Ghostty surface, a shell and fzf on every keypress and render in a terminal; Omarchy's menus are native, resident processes and feel faster and cleaner. We considered Rust (the user's preference as a language) but Rust has no native macOS GUI toolkit — the realistic option was Tauri, i.e. a webview. Swift/SwiftUI gives a non-activating NSPanel, system app icons and global hotkeys directly and matches "macOS-native" as the project's identity. Decided 2026-09-14 (issue #10).

## Consequences

- Built with SwiftPM and the Command Line Tools only; no Xcode project, no developer account (ad-hoc signed).
- The Panel replaces the Popup only for views that need no terminal; brew install with preview, brew upgrade, weather, audio and Notes stay in the Ghostty Popup.
