package.path = package.path .. ";../?.lua"

lume = require "lib/lume"

-- TODO encapsulate "file" module
require "file"

local utf8 = require "utf8"
local window_settings = require "window_settings"
local OBJ = require "obj"

local canvas
local zoom_x, zoom_y = 1, 1

local level_name = "level"
local last_x, last_y = 0, 0
local grid_enabled = true
local grid_placement_enabled = true
local grid_color = {1, 1, 1, 0.3}

-- View stuff
local w = window_settings.default_width
local h = window_settings.default_height
local MAX_ZOOM = 5
local ZOOM_INTERVAL = 1/13
local canvas_width = window_settings.default_width * MAX_ZOOM
local canvas_height = window_settings.default_height * MAX_ZOOM
local view_x, view_y = canvas_width/2, canvas_height/2
local VIEW_SPEED = 0.07
local ui_font_medium = love.graphics.newFont("res/bpg_arial.ttf", 20)
local ui_font_large = love.graphics.newFont("res/bpg_arial.ttf", 30)

-- Other globals
local inputting_text = true
local input_text = ""
local current_finish_direction = math.pi

-- Index objects
local object_index = {}
do
  local j = 1
  for i, o in pairs(OBJ) do
    if type(o) == "table" and o.id then
      object_index[j] = i
      j = j + 1
    end
  end
end
local current_object_index = 1
local current_object = OBJ[object_index[current_object_index]]

-- Level loaded in here
local level = {}
-- Load level callback (for open / new level)
local loadLevel = function(name) print("Callback not defined!") end

function love.load()
  canvas = love.graphics.newCanvas(canvas_width, canvas_height)
  loadLevel = function(name) level = openLevel(name) end
end

function love.update(dt)
  if not inputting_text then
    -- Move camera
    if love.keyboard.isDown("space") then
      local x, y = love.mouse.getPosition()
      local dist_x, dist_y = w/2 - x, h/2 - y
      view_x = view_x + dist_x * VIEW_SPEED/zoom_x
      view_y = view_y + dist_y * VIEW_SPEED/zoom_y
    end

    -- Editor controls
    local mx, my = love.mouse.getPosition()
    if love.mouse.isDown(1) then
      handleMouse(mx, my, 1)
    elseif love.mouse.isDown(2) then
      handleMouse(mx, my, 2)
    end
  end
end

function getWorldCoords(x, y)
  local offset_x = canvas_width/2 - view_x
  local offset_y = canvas_height/2 - view_y

  local new_x = (x - w/2) / zoom_x
  local new_y = (y - h/2) / zoom_y

  return new_x + offset_x, new_y + offset_y
end

function love.draw()
  -- Draw background
  love.graphics.clear(0.5, 0.5, 0.5, 1)

  -- Start canvas drawing
  love.graphics.setCanvas(canvas)
  do
    love.graphics.clear(0, 0, 0, 1)
    --love.graphics.setBlendMode("alpha", "premultiplied") -- makes world brighter

    -- View
    love.graphics.translate(view_x, view_y)

    -- Level objects
    for _, O in pairs(OBJ) do
      if type(O) == "table" then
        if level[O.id] then
          for _, obj in pairs(level[O.id]) do
            O:draw(obj)
          end
        end
      end
    end

    -- Draw pointer
    love.graphics.setColor(1, 0, 0, 1)
    local mx, my = getWorldCoords(love.mouse.getPosition())
    love.graphics.circle("fill", mx, my, 3)

    -- Draw grid
    love.graphics.setColor(grid_color)
    if grid_enabled then
      local start_x = math.floor(-view_x)
      local start_y = math.floor(-view_y)
      local end_x = math.floor(start_x + canvas_width)
      local end_y = math.floor(start_y + canvas_height)
      for gx=start_x, end_x, 1 do
        if gx % current_object.width == 0 then
          love.graphics.line(gx, start_y, gx, end_y)
        end
      end
      for gy=start_y, end_y, 1 do
        if gy % current_object.height == 0 then
          love.graphics.line(start_x, gy, end_x, gy)
        end
      end
    end
  end
  love.graphics.setCanvas()
  -- End canvas drawing

  love.graphics.setColor(1, 1, 1, 1)

  -- Draw canvas
  local camera_x = w/2 - view_x
  local camera_y = h/2 - view_y
  love.graphics.draw(canvas, camera_x, camera_y, 0, zoom_x, zoom_y, canvas_width/2, canvas_height/2)

  love.graphics.setBlendMode("alpha")

  local text_margin = 25
  -- UI
  love.graphics.setFont(ui_font_medium)
  --- Level name
  love.graphics.setColor(1, 1, 1, 1)
  local text_x, text_y = 10 - view_x, 10 - view_y
  love.graphics.print(level_name..level_extension, text_x, text_y)
  love.graphics.circle("fill", w/2 - view_x, h/2 - view_y, 5)
  --- Grid text
  text_y = text_y + text_margin
  if grid_enabled then
    love.graphics.print("Grid Lines ON", text_x, text_y)
  end
  --- Grid placement text
  text_y = text_y + text_margin
  if grid_placement_enabled then
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("Grid Placement ON", text_x, text_y)
  else
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Grid Placement OFF", text_x, text_y)
  end
  --- Current Object View
  ---- Object view background
  local bg_width, bg_height = 110, 150
  local bg_x = -view_x + w - bg_width
  local bg_y = -view_y
  love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
  love.graphics.rectangle("fill", bg_x, bg_y, bg_width, bg_height)
  ---- Object name
  love.graphics.setFont(ui_font_large)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(current_object.id, bg_x, bg_y, bg_width, "center")
  ---- Object draw
  love.graphics.setBlendMode("alpha", "premultiplied")
  current_object:draw({ bg_x + bg_width/2 - current_object.width/2, bg_y + bg_height - current_object.height*1.3 })
  love.graphics.setBlendMode("alpha")

  -- Text input
  if inputting_text then
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", -view_x, -view_y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(ui_font_large)
    love.graphics.print("Level name:", -view_x + 20, -view_y)
    love.graphics.print("\n\t"..input_text, -view_x + 20, -view_y)
  end
end

function love.wheelmoved(x, y)
  -- Check if lower limit reached
  if y < 0 and (zoom_x <= 1/MAX_ZOOM or zoom_y <= 1/MAX_ZOOM) then
    return
  end

  -- Check if upper limit reached
  if y > 0 and (zoom_x >= MAX_ZOOM or zoom_y >= MAX_ZOOM) then
    return
  end

  -- Zoom with interval per scroll
  zoom_x = zoom_x + y * ZOOM_INTERVAL
  zoom_y = zoom_y + y * ZOOM_INTERVAL
end

function love.resize(newWidth, newHeight)
  w, h = newWidth, newHeight
end

function handleMouse(x, y, b)
  if b == 1 then
    if not grid_placement_enabled then
      -- Place object
      uniquePlaceObject(current_object.id, getWorldCoords(x, y))
    else
      -- Align to grid
      local x, y = getWorldCoords(x, y)
      x, y = math.floor(x), math.floor(y)
      while x % current_object.width ~= 0 do
        x = x - 1
      end
      while y % current_object.height ~= 0 do
        y = y - 1
      end
      -- Place object
      uniquePlaceObject(current_object.id, x, y)
    end
  elseif b == 2 then
    -- Delete objet
    local wx, wy = getWorldCoords(x, y)
    local rem = {}
    for i, obj_group in pairs(level) do
      if obj_group and type(obj_group) == "table" then
        for j, obj in pairs(obj_group) do
          if lume.distance(wx, wy, obj[1], obj[2]) < current_object.erase_distance then
            table.insert(rem, {i, j})
            last_x, last_y = level[i][j][1], level[i][j][2]
          end
        end
      end
    end

    for i=#rem, 1, -1 do
      local id = rem[i][1]
      local obj_index = rem[i][2]
      table.remove(level[id], obj_index)
    end
  end
end

function placeObject(obj_id, x, y)
  local x, y = x, y
  if not level[obj_id] then
    level[obj_id] = {}
  end

  table.insert(level[obj_id], newObject(obj_id, x, y))
  last_x, last_y = x, y
end

-- Checks for duplicates and calls placeObject
function uniquePlaceObject(obj_id, x, y)
  if not isObjectSame(x, y, obj_id) then
    placeObject(obj_id, x, y)
  end
    last_x, last_y = x, y
end

-- Returns lua table from object id
function newObject(id, x, y)
  if id == "finish" then
    local tpx, tpy = 0, 0
    if current_finish_direction == math.pi/2 then
      tpx, tpy = -1, 0
    elseif current_finish_direction == math.pi then
      tpx, tpy = 0, -1
    elseif current_finish_direction == math.pi*3/2 then
      tpx, tpy = 1, 0
    elseif current_finish_direction == math.pi*2 then
      tpx, tpy = 0, 1
    end
    return {x, y, tpx, tpy}
  end
  return OBJ:getObjectById(id):getArray({x = x, y = y})
end

-- Checks if object with id already exists at coordinates (for reducing duplicates)
function isObjectSame(x, y, id)
  if not level[id] then
    return false
  end

  for _, obj in pairs(level[id]) do
    if obj[1] == x and obj[2] == y then
      return true
    end
  end

  return false
end

-- Controls
function love.keypressed(k)
  -- Textinput
  if inputting_text then
    -- Cancel textinput
    if k == "escape" then
      inputting_text = false
      input_text = ""
      return
    end

    -- Finish textinput
    if k == "return" then
      -- Trim text
      input_text = lume.trim(input_text)
      if string.len(input_text) > 0 then
        -- Clear text and set level name
        inputting_text = false
        level_name = input_text
        input_text = ""
        loadLevel(level_name)
      else
        print("Invalid file name")
      end
    end

    -- Delete char
    if k == "backspace" then
      if string.len(input_text) > 0 then
        input_text = input_text:sub(1, utf8.offset(input_text, -1) - 1)
      end
    end

    return
  end

  -- Quit
  if k == "escape" then
    love.event.quit()
  end

  -- Shortcuts
  if love.keyboard.isDown("lctrl") or love.keyboard.isDown("lgui") then
    -- Save level
    if k == "s" then
      saveLevel(level_name, level)
    end

    -- Enable grid lines
    if k == "g" then
      grid_enabled = not grid_enabled
    end

    -- Open level
    if k == "o" then
      inputting_text = true
      loadLevel = function(name) level = openLevel(name) end
    end

    -- Create new level
    if k == "n" then
      inputting_text = true
      loadLevel = function(name) level = newLevel(name) end
    end

    -- Create new level and overwrite
    if love.keyboard.isDown("lshift") then
      if k == "n" then
        inputting_text = true
        loadLevel = function(name) level = newLevel(name, true) end
      end
    end

    return
  end

  -- Modify object
  if k == "tab" then
    if current_object.id == "finish" then
      current_object = OBJ.FINISH
      current_finish_direction = current_finish_direction + math.pi/2
      if current_finish_direction > math.pi*2 then
        current_finish_direction = math.pi/2
      end
    end
  end

  -- Previous object
  if k == "q" then
    current_object_index = current_object_index - 1
    if current_object_index <= 0 then
      current_object_index = #object_index
    end
    current_object = OBJ[object_index[current_object_index]]
  end

  -- Next object
  if k == "e" then
    current_object_index = current_object_index + 1
    if current_object_index >= #object_index + 1 then
      current_object_index = 1
    end
    current_object = OBJ[object_index[current_object_index]]
  end

  -- Grid mode
  if k == "g" then
    grid_placement_enabled = not grid_placement_enabled
  end

  -- Clone block in direction
  if k == "left" then
    uniquePlaceObject(current_object.id, last_x - current_object.width, last_y)
  end

  if k == "right" then
    uniquePlaceObject(current_object.id, last_x + current_object.width, last_y)
  end

  if k == "up" then
    uniquePlaceObject(current_object.id, last_x, last_y - current_object.height)
  end

  if k == "down" then
    uniquePlaceObject(current_object.id, last_x, last_y + current_object.height)
  end
end

function love.textinput(text)
  if inputting_text then
    input_text = string.gsub(input_text .. text, "^%s+", "")
  end
end

function love.quit()
  -- Quit
  return false
end