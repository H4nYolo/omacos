---
status: accepted
---

# The Panel is a view layer; all behaviour stays in the omacos-* scripts

Everything the Panel shows or triggers — app list and launch history, menu entries, emoji table, clipboard history, keybindings, capture, package install — already exists as shell scripts and plain files. The Panel reads those and calls those; it owns no logic of its own. That keeps one implementation for two frontends (native Panel and fzf Popup), keeps the terminal fallback working over SSH, and lets menu entries be edited without touching Swift. The price is that the Panel is only as fast as the scripts it calls; long-running ones therefore run detached or in the Popup.
