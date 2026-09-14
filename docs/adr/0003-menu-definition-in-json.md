---
status: accepted
---

# The menu tree lives in one JSON file shared by both frontends

`~/.config/omacos/menu.json` defines every Menu level: icon, label and exactly one of `menu` (children), `view`, `popup` or `run`, plus optional `state` and `when` shell commands for dynamic labels and visibility. The fzf `omacos-menu` and the native Panel both read it, so an entry is added once and appears in both, and nobody has to touch Swift to change the menu. JSON rather than TOML (the rest of the config is TOML) because Swift's Foundation parses JSON natively and the shell side already depends on jq, while TOML would have needed a Swift package and Python in the shell; comments go into `_` keys. Decided 2026-09-14 (issue #10).
