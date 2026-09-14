# Templates

`omacos-theme set <name>` renders every `*.tpl` here with the theme's resolved palette
(`omacos-theme-colors`) into `~/.local/state/omacos/theme/<file>`. Placeholders:
`{{ key }}` = `#rrggbb`, `{{ key_strip }}` = `rrggbb`, `{{ key_argb }}` = `0xffrrggbb`,
plus `{{ name }}` and `{{ mode }}`. A file the theme ships itself (e.g. `neovim.lua`)
wins over the rendered template.
