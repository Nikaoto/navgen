local window_settings = require "window_settings"

function love.conf(t)
  t.window.title = window_settings.title
  t.window.icon = window_settings.icon_path
  t.window.width = window_settings.default_width
  t.window.height = window_settings.default_height
  t.window.borderless = window_settings.borderless
  t.window.resizable = window_settings.resizable
  t.window.minwidth = window_settings.min_width
  t.window.minheight = window_settings.min_height
  t.window.fullscreen = window_settings.fullscreen
  --t.window.fullscreentype = 
  --t.window.vsync = 1                  -- Vertical sync mode (number)
  --t.window.msaa = 0                   -- The number of samples to use with multi-sampled antialiasing (number)
  --t.window.display = 1                -- Index of the monitor to show the window in (number)
  --t.window.highdpi = false            -- Enable high-dpi mode for the window on a Retina display (boolean)
  --t.window.x = nil                    -- The x-coordinate of the window's position in the specified display (number)
  --t.window.y = nil                    -- The y-coordinate of the window's position in the specified display (number)
  end