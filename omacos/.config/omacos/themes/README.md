# Themes

Every directory is one theme, taken from [Omarchy](https://github.com/basecamp/omarchy)
(MIT, © Basecamp and the theme authors). Files:

- `colors.toml` — the palette; everything else is rendered from it by `omacos-theme set`
  using the templates in `../themed/`.
- `neovim.lua` — optional lazy.nvim spec when a real colourscheme plugin exists. Without it
  the aether template is used.
- `backgrounds.txt` — names of the wallpapers in Omarchy's `themes/<name>/backgrounds/`.
  They are downloaded on first use into `~/.local/share/omacos/backgrounds/<name>/`.

Your own theme: add a directory here or under `~/.local/share/omacos/themes/<name>/` with at
least a `colors.toml` (`background`, `foreground`, `accent`, `red`… as in the others).
