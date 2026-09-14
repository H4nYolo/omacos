-- Colourscheme from the current omacos theme (rendered by `omacos-theme set` into
-- ~/.local/state/omacos/theme/neovim.lua, a lazy.nvim spec). Tokyo Night until a theme is set.
-- Running instances keep their colours; the next start picks the new theme up.
local spec = vim.fn.expand("~/.local/state/omacos/theme/neovim.lua")
if (vim.uv or vim.loop).fs_stat(spec) then
  local ok, result = pcall(dofile, spec)
  if ok and type(result) == "table" then
    return result
  end
end
return {
  { "folke/tokyonight.nvim", priority = 1000 },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
