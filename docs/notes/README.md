# Notes: the floating scratch pad

[← Manual](../README.md)

Notes is for the things you write down while something else has your attention: a meeting, an
incident number, the RM ticket you need twice a day. It floats above every window, so you never
leave the screen you work on. `Super + Shift + N` is all you need to remember. It replaces Raycast
Notes; why it looks the way it does is in [ADR 0004](../adr/0004-notes-as-native-floating-app.md).

## Showing and hiding

`Super + Shift + N` does what the moment needs:

| Notes is … | `Super + Shift + N` |
|---|---|
| hidden | shows it top right on the active monitor and puts the cursor in it |
| on screen, you work elsewhere | gives it the keyboard |
| on screen with the keyboard | hides it |

`Cmd + Enter` gives the keyboard back to the app you came from and leaves Notes on screen. Clicking
another window does the same. Notes is its own app (`omacos-notes`), started hidden at login, so it
appears instantly.

**The look.** Notes always opens top right on the monitor with the focused window, below the bar.
Drag its edges to resize it; the size is remembered. With the keyboard it is a dark pane of glass.
Without it, it fades until little more than the letters is left. Both levels are yours:
`Cmd + Plus` / `Cmd + Minus` change the focused one, `Cmd + Option + Plus` / `Minus` the
unfocused one (shown for a moment while you change it). Colours and font follow the omacos
[theme and font](../style/README.md).

## Tabs

Every `*.md` file directly in `~/notes/` is a Tab, named after the file. They are plain files:
open them in nvim, grep them, put the folder in git. Another folder goes into
`~/.config/omacos/notes-dir`.

| | |
|---|---|
| `Cmd + T` | new Tab: type a name, `Enter`, start writing (creates `~/notes/<name>.md`) |
| `Cmd + 1` … `Cmd + 9` | go to Tab 1 … 9 |
| `Ctrl + Tab` / `Ctrl + Shift + Tab` | next / previous Tab |
| `Cmd + P` | search Tab names and every line of every Tab; `Enter` jumps to the line |
| `Cmd + W` | close the Tab. The file stays; `Cmd + P` opens it again |
| double-click a Tab | rename it (renames the file) |
| drag a Tab | change the order (remembered) |
| right-click a Tab | rename, close, move to the Trash (asks first) |
| `Cmd + E` | edit the Tab in real nvim in the popup, for bigger rework |

Everything is saved half a second after you stop typing. If a file changes outside Notes (nvim,
git), the Tab reloads by itself.

## Writing

Notes shows markdown the way [Typora](https://typora.io) does: you type `## Incident`, and as soon
as the cursor leaves the line it is a heading and the `##` is gone. Go back to the line and the
markdown is there again to edit.

What it renders: headings, `**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, fenced code blocks,
`- ` lists, `- [ ]` tasks, `> ` quotes, `[links](https://…)` and `---`. No tables, no images: it is
a scratch pad.

**Shortcuts while typing:**

| type | becomes |
|---|---|
| `/t` + space at the start of a line | `- [ ] ` — a task |
| `/h` + space | `## ` — a heading |
| `/d` + space | `## Thu 15 Oct 2026 09:05` — a timestamp heading |
| `Enter` on a task, bullet or numbered line | the next line starts with `- [ ] `, `- ` or the next number |
| `Enter` on a line with only the marker | the marker goes, the list ends |

**Tasks:** click the box to tick it, or press `Cmd + Shift + X` on the line: it ticks and unticks
a task and turns any other line into one. Ticked tasks are struck through.

**Links:** `Cmd`-click opens them. `Cmd + Shift + D` inserts a timestamp heading anywhere.

## Vim

Notes speaks vim. Every Tab starts in normal mode; the mode is shown bottom right.

- `i` `a` `o` `O` `I` `A` insert, `Esc` (or a tap on Caps Lock) back to normal
- motions `h j k l` `w b e` `0 $` `gg G` `f t` `%` `{ }`, with counts
- `d` `c` `y` with a motion or text object (`diw`, `ci"` …), `dd` `yy` `p` `P`, `x`, `r`, `.`
- `y` and `p` use the system clipboard, so a yanked line pastes into Teams
- `v` `V` visual, `/` `n` `N` search in the Tab, `u` / `Ctrl + R` undo and redo
- `:w` saves right away (it saves anyway), `:q` hides Notes

Not there: named registers, macros, `:s`. For those, `Cmd + E` opens the Tab in your real nvim.

All keys, searchable: `Super + K` and type `notes`, or Menu → Learn → Notes keybindings.
