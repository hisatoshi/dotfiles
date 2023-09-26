local wezterm = require 'wezterm';
return {
  font = wezterm.font("0xProto"),
  font_size = 13,
  color_scheme = "Catppuccin Frappe",
  default_prog = {"wsl.exe", "--distribution", "Ubuntu", "--exec", "/bin/zsh", "-l"},
  use_ime=true,
  adjust_window_size_when_changing_font_size = false,
  hide_tab_bar_if_only_one_tab = true,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
  default_cwd = "~",
  leader = { key = 'q', mods = 'CTRL', timeout_milliseconds = 1000 },
  keys = {
    {
      key = '|',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = '-',
      mods = 'LEADER',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'h',
      mods = 'LEADER',
      action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
      key = 'l',
      mods = 'LEADER',
      action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
      key = 'k',
      mods = 'LEADER',
      action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
      key = 'j',
      mods = 'LEADER',
      action = wezterm.action.ActivatePaneDirection 'Down',
    },
    {
      key = 'h',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.AdjustPaneSize { 'Left', 20 },
    },
    {
      key = 'j',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.AdjustPaneSize { 'Down', 20 },
    },
    {
      key = 'k',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.AdjustPaneSize { 'Up', 20 }
    },
    {
      key = 'l',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.AdjustPaneSize { 'Right', 20 },
    },

  }
}

