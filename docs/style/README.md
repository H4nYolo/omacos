# Style: themes, backgrounds, fonts

[← Manual](../README.md)

![Style → Theme: the picker in the popup with the palette of the highlighted theme](../images/theme.jpg)

## Themes

Omarchy's themes, switched with one command. `omacos/.config/omacos/themes/<name>/` holds a
`colors.toml` (Omarchy's palette format, ~30 semantic colours), an optional `neovim.lua` and the
names of the theme's wallpapers. `omacos-theme set <name>` renders the templates in
`omacos/.config/omacos/themed/` into `~/.local/state/omacos/theme/` and tells everything:

- Ghostty: new windows read the rendered `ghostty.conf`; running windows get the palette via
  OSC sequences on their ttys, so tmux sessions survive
- sketchybar and JankyBorders reload with the new colours
- the panel and every fzf popup read the colours when they open
- nvim loads the theme's colourscheme at its next start (`lua/plugins/theme.lua`)
- the theme's first wallpaper is downloaded from the Omarchy repo into
  `~/.local/share/omacos/backgrounds/<name>/` and set on every display (the rest follows in the background)
- macOS switches to light or dark appearance to match the theme

`omacos-theme list | current | set <name> | next | menu`. The menu's **Style → Theme** entry opens a
picker with colour swatches. Tokyo Night is the default and stays hard-wired as the fallback in every
config, so nothing breaks before the first `set`. Your own theme: a directory with a `colors.toml`
under `~/.local/share/omacos/themes/<name>/`.

## Backgrounds

**Style → Background** picks one of the theme's wallpapers with an image preview (chafa, kitty
graphics in the popup); `Super + Shift + B` or **Next background** cycles them
(`omacos-background next | prev | set <file> | menu`). Your own pictures go into
`~/.local/share/omacos/backgrounds/<theme>/`.

**Wallpaper packs** are theme-independent sets that join the cycle and the picker:
`omacos-background packs | install <pack> | remove <pack>`, or **Style → Wallpaper packs**. A pack is a
`filename<TAB>url[<TAB>source<TAB>licence]` list in `omacos/.config/omacos/wallpapers/<pack>.txt`, a
private list in `~/.local/share/omacos/wallpapers/<pack>.txt`, or any folder:
`omacos-background install ~/Pictures/walls` links it in. Shipped packs:

| pack | what |
|---|---|
| `omarchy-logos` | the Omarchy logo in every theme's colours |
| `omarchy-all` | every Omarchy background, all themes |
| `cyberpunk` | 14 photos: neon alleys, night skylines, synthwave, circuit boards, old computers |
| `fantasy` | 14 photos and paintings: misty castles, auroras, caves, Friedrich and Bierstadt |

The photos come from Unsplash, Pexels and Wikimedia Commons under their free licences; source
and licence stand next to every line in the pack files.

## Font

**Style → Font** or `omacos-font list | set <family> | menu | install` switches the monospace font
between the installed Nerd Fonts (fontconfig's `fc-list`), with a brew picker for more
`font-*-nerd-font` casks. Ghostty reloads live (SIGUSR2, every window and the popup), the bar reloads,
the panel reads it on its next show; tmux and nvim inherit the terminal's font. Default:
CaskaydiaMono Nerd Font.
