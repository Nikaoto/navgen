json = require "lib/json"

level_directory = "levels"
level_extension = ".json"

-- Returns location of level from its name
function getLevelPath(level_name)
  return level_directory.."/"..level_name..level_extension
end

-- Checks if file exists at path
function fileExists(path)
  local f = io.open(path, "rb")
  if f then f:close() end
  return f ~= nil
end

-- Reads file at path and returns its content
function readFile(path)
  if fileExists(path) then
    local file = io.open(path, "r")
    local data = file:read()
    file:close()
    return data
  else
    print("File at "..path.." not found!")
    return nil
  end
end

-- Creates new level with given name (asks if it should overwrite)
function newLevel(name, overwrite)
  local filePath = getLevelPath(name)
  if fileExists(filePath) and not overwrite then
    print("Did not overwrite level")
    print("Opening level at '"..filePath.."'")
    return openLevel(name)
  else
    local file = io.open(filePath, "w+")
    -- TODO change default data
    local default_data = { info = "graviton editor empty level"}
    --
    file:write(json.encode(default_data))
    file:close()
    return default_data
  end
end

-- Gets level data if level with name exists || creates new level otherwise
function openLevel(name)
  local filePath = getLevelPath(name)
  if fileExists(filePath) then
    local data = readFile(filePath)
    return json.decode(data)
  else
    print("Level with name '"..name.."' not found!")
    print("Creating new level at '".. filePath.."'")
    return newLevel(name, true)
  end
end

-- Saves data to level file with given name
function saveLevel(name, data)
  local filePath = getLevelPath(name)
  -- Overwrite all data in file
  local file = io.open(filePath, "w+")
  file:write(json.encode(data))
  file:close()
end