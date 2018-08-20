-- Settings for access
local window_settings = {
  fullscreen = false,
  resizable = true,
  borderless = false,
  centered = true,
  min_width = 800,
  min_height = 600,
  default_width = 1366,
  default_height = 768,
  title = "Graviton Editor",
  icon_path = "res/icon.png"
}

-- Flags for window setMode
window_settings.flags = {
  fullscreen = window_settings.fullscreen,
  resizable = window_settings.resizable,
  borderless = window_settings.borderless,
  minwidth = window_settings.min_width,
  minheight = window_settings.min_height,
  centered = window_settings.centered
}

return window_settings