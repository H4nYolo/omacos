-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Diese Datei wird von LazyVim automatisch geladen.

-- Eine Funktion, die Checkboxen in der aktuellen Zeile umschaltet
local function toggle_markdown_task()
  local line = vim.api.nvim_get_current_line()
  local new_line

  -- Sucht nach Mustern wie "- [ ]" oder "* [ ]"
  if line:match("^%s*[-*]%s*%[ %]") then
    new_line = line:gsub("%[ %]", "[x]", 1)
  -- Sucht nach Mustern wie "- [x]"
  elseif line:match("^%s*[-*]%s*%[x%]") then
    new_line = line:gsub("%[x%]", "[ ]", 1)
  else
    -- Wenn kein Aufgaben-Muster gefunden wird, passiert nichts.
    return
  end
  vim.api.nvim_set_current_line(new_line)
end

-- Erstellt eine Gruppe für unsere Automatisierung, damit sie sauber bleibt
local augroup = vim.api.nvim_create_augroup("CustomMarkdownKeymaps", { clear = true })

-- Erstellt die eigentliche Regel:
-- "Wenn eine Markdown-Datei geöffnet wird, erstelle dieses Tastenkürzel"
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "markdown",
  desc = "Set keymap for markdown task toggle",
  callback = function()
    vim.keymap.set("n", "<leader>cx", toggle_markdown_task, {
      buffer = true, -- Kürzel gilt nur für diese Datei
      silent = true,
      desc = "Toggle Markdown Checkbox",
    })
  end,
})
