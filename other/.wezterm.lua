local wezterm = require 'wezterm';
return {
  font = wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", italic=false}),
  font_size = 13,
  color_scheme = "Catppuccin Frappe",
  default_prog = {"wsl.exe", "--distribution", "Ubuntu", "--exec", "/bin/zsh", "-l"},
  use_ime=true,
  adjust_window_size_when_changing_font_size = false,
  hide_tab_bar_if_only_one_tab = true,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
  default_cwd = "~"
}
