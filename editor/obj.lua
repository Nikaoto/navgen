local Object = {}

-- Default values
Object.id = "null"
Object.x = 0
Object.y = 0
Object.width = 1
Object.height = 1
Object.color = {1, 1, 1, 1}
Object.fill_style = "line"
Object.erase_distance = 18

-- Constructor
function Object.new(t)
  return setmetatable(t, Object)
end

-- Get array representation of object (for writing to json)
function Object.getArray(self, data)
  return {data.x, data.y}
end

-- Get lua table from json array
function Object.getTable(self, array)
  local t = {
    x = array[1],
    y = array[2]
  }
  setmetatable(t, {__index = self})
  return t
end

-- Draw in editor (using data from json array)
function Object.draw(self, array)
  local inst = self:getTable(array)
  love.graphics.setColor(inst.color)
  love.graphics.rectangle(inst.fill_style, inst.x, inst.y, inst.width, inst.height)
  inst:drawEraseDistance()
end

-- Draw circle showing erase distance for object
function Object.drawEraseDistance(self)
  love.graphics.setColor(1, 1, 0)
  love.graphics.circle("line", self.x, self.y, self.erase_distance)
end

Object.__index = Object
--------------------

-- Returned table, stores object descriptions and util functions
local objects = {}

function objects.getObjectById(self, id)
  for i, O in pairs(self) do
    if type(O) == "table" and O.id == id then
      return self[i]
    end
  end
end


--[[ Object Descriptions ]]

-- Apple
objects.APPLE = setmetatable({
  id = "apple",
  width = 30,
  height = 30,
  color = {0.2, 0.8, 0.2},
  fill_style = "fill"
}, Object)

-- Box
objects.BOX = setmetatable({
  id = "box",
  width = 50,
  height = 50,
  color = {0.647, 0.408, 0.165}
}, Object)

-- Player
objects.PLAYER = setmetatable({
  id = "player",
  width = 40,
  height = 60,
  color = {1, 1, 1}
}, Object)

-- Block
objects.BLOCK = setmetatable({
  id = "block",
  width = 50,
  height = 50,
  color = {0, 0, 1}
}, Object)

-- Finish (TODO: change)
objects.FINISH = setmetatable({
  id = "finish",
  width = 25,
  height = 25,
  color = {0, 1, 0},
  tpx = 0,
  tpy = 0,
  getArray = function(self, data)
    return {data.x , data.y, data.tpx, data.tpy}
  end,
  getTable = function(self, array)
    local t = {
      x = array[1],
      y = array[2],
      tpx = array[3],
      tpy = array[4]
    }
    setmetatable(t, {__index = self})
    return t
  end,
  draw = function(self, array)
    local inst = self:getTable(array)
    love.graphics.setColor(inst.color)
    love.graphics.rectangle(inst.fill_style, inst.x, inst.y, inst.width, inst.height)
    -- Draw tp direction
    love.graphics.setColor(0, 1, 1)
    local w, h = self.width/2, self.height/2
    love.graphics.circle("fill", inst.x + w + w * inst.tpx, inst.y + h + h * inst.tpy, 3)
    --
    inst:drawEraseDistance()
  end
}, Object)

-- Death
objects.DEATH = setmetatable({
  id = "death",
  width = 25,
  height = 25,
  color = {1, 0, 0}
}, Object)

-- Win
objects.WIN = setmetatable({
  id = "win",
  width = 30,
  height = 30,
  color = {1, 1, 0.5},
  fill_style = "fill"
}, Object)

------------------

return objects