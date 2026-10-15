---
status: accepted
---

# Notes is a native floating app with tabs, Typora-style rendering and a vendored vim engine

Notes is a scratch pad for meetings, incident numbers and the bits of information you need every now and then, without leaving the screen you work on. The nvim pad in the Popup could not stay on screen next to other work, had one file only, and looked like a terminal. Notes becomes its own resident Swift app, `omacos-notes.app`: a second executable in the `shell/` SwiftPM package (own process and lifecycle, shares theme and matcher code with the Panel through `OmacosCore`). Decided 2026-10-15 in a grilling session.

- **Window**: floats above everything on every workspace, AeroSpace does not tile it. Super+Shift+N: hidden → show and focus · visible without focus → focus · focused → hide; Cmd+Enter hands the focus back and leaves it on screen. It appears top right on the active monitor (the one with the focused window), only when it is shown. Size by mouse, remembered.
- **Look**: Liquid Glass (`NSGlassEffectView`, macOS 26), two opacities — without focus almost only the text, with focus more opaque — each adjustable with Cmd+Plus/Minus and remembered. Theme colours and the omacos font, live.
- **Tabs**: every `*.md` directly in `~/notes/` (`~/.config/omacos/notes-dir`) is a Tab; files, not a database, so nvim, grep and git keep working. Autosave 0.5 s after a change, reload on outside changes. Cmd+P searches Tab names and contents.
- **Editor**: Typora style — the cursor line shows the raw markdown, every other line is rendered with its markers hidden. Basics only (headings, emphasis, code, lists, checkboxes, quotes, links, rules); no tables or images.
- **Vim**: [swift-vim-engine](https://github.com/msjurset/swift-vim-engine) (MIT) vendored into `shell/Sources/VimEngine`, yank/put patched onto the system clipboard. Embedding real nvim was rejected: its UI protocol is a monospace cell grid, so headings could not be larger. A hidden nvim buffer driven over RPC (the vscode-neovim approach) keeps real vim with custom rendering but is an order of magnitude more work — a possible v2. kindaVim was rejected (paid, closed, edits behind the rendering).

## Consequences

- The nvim pad (`omacos-notes` in the Popup, `notes-file`, the automatic timestamp header) is gone; Cmd+Shift+D inserts a timestamp heading, Cmd+E opens the current Tab in nvim in the Popup for bigger edits.
- The vendored engine is ours to maintain; upstream is a one-person project.
- Supersedes the "Notes stays in the Ghostty Popup" consequence of ADR 0001.
