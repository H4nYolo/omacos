-- Ctrl + h/j/k/l moves between nvim splits and, at the edge, on to the neighbouring tmux pane.
-- Counterpart of the is_vim binding in tmux/.config/tmux/tmux.conf: tmux hands Ctrl-hjkl to nvim,
-- this plugin hands them back (via `tmux select-pane`) when there is no split left in that direction.
-- LazyVim skips its own <C-h/j/k/l> window mappings when a lazy `keys` handler exists for them.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Go to Left Window / tmux pane" },
      { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Go to Lower Window / tmux pane" },
      { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Go to Upper Window / tmux pane" },
      { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Go to Right Window / tmux pane" },
      { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Go to Previous Window / tmux pane" },
    },
  },
}
