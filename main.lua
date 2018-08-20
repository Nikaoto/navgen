local lume = require "lib/lume"
local json = require "lib/json"

local w, h = 1024, 640
local players = {}
local start_time = 0
local time_limit = 15
local knockback_mult = 5
local border_width = 10
local apples = {}
local sound_on = true
local appleSound = love.audio.newSource("apple.wav", "static")
local objects = {}

function newPlayer(x, y)
  return {
    x = x,
    y = y,
    radius = 40,
    ox = 20,
    oy = 20,
    rotation = 0,
    rotspeed = math.pi/30,
    speed = 200,
    score = 0,
    sprite = love.graphics.newImage("player.png"),
    update = function(self, dt)
      -- Controls
      if love.keyboard.isDown("right") then
        self.rotation = self.rotation + self.rotspeed
      elseif love.keyboard.isDown("left") then
        self.rotation = self.rotation - self.rotspeed
      end
      local dx = self.speed * math.cos(self.rotation - math.pi/2) * dt
      local dy = self.speed * math.sin(self.rotation - math.pi/2) * dt
      self.x = self.x + dx
      self.y = self.y + dy

      -- Wall collisions
      --- Right
      if self.x > w - border_width then
        self.x = self.x - self.speed * dt * knockback_mult
      end
      --- Left
      if self.x <= border_width then
        self.x = self.x + self.speed * dt * knockback_mult
      end
      --- Top
      if self.y < border_width then
        self.y = self.y + self.speed * dt * knockback_mult
      end
      --- Bottom
      if self.y > h - border_width then
        self.y = self.y - self.speed * dt * knockback_mult
      end
    end,
    draw = function(self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(self.sprite, self.x, self.y, self.rotation, 1, 1, self.ox, self.oy)
    end
  }
end

function newApple(x, y)
  return {
    x = x, y = y,
    radius = 20,
    ox = 10, oy = 10,
    sprite = love.graphics.newImage("apple.png"),
    draw = function(self)
      love.graphics.draw(self.sprite, self.x, self.y, 0, 1, 1, self.ox, self.oy)
    end
  }
end

function newWin(x, y)
  return {
    x = x, y = y,
    width = 50,
    height = 50,
    draw = function(self)
      love.graphics.setColor(0, 1, 1)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(1, 1, 1)
    end
  }
end

function newBlock(x, y)
  return {
    x = x, y = y,
    width = 100,
    height = 100,
    draw = function(self)
      love.graphics.setColor(0, 0, 1)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(1, 1, 1)
    end
  }
end

function nextGeneration()
  print("DIE")
end

function readFile(path)
  local ret = ""
  local file = io.open(path, "r")
  if file then
    ret = file:read()
    file:close()
    return ret
  end
  print("File at "..path.." not found!")
  return nil
end

function love.load()
  canvas = love.graphics.newCanvas(canvas_width, canvas_height)
  love.window.setMode(w, h)
  math.randomseed(os.time())
  start_time = os.time()

  objects = {}
  level = json.decode(readFile("level.json"))

  -- Blocks
  if level["block"] then
    for _, block in pairs(level["block"]) do
      table.insert(objects, newBlock(block[1], block[2]))
    end
  end
  -- Win
  if level["win"] then
    for _, win in pairs(level["win"]) do
      table.insert(objects, newWin(win[1], win[2]))
    end
  end

  -- Player
  table.insert(players, newPlayer(level["player"][1], level["player"][2]))
end

function love.update(dt)
  for _, p in pairs(players) do
    p:update(dt)

    local rm = {}
    for i, a in pairs(apples) do
      -- Check apple collisions
      if lume.distance(p.x, p.y, a.x, a.y) <= (p.radius + a.radius)/2 then
        playSound()
        table.insert(rm, i)
        p.score = p.score + 1
      end
    end

    for _, ind in pairs(rm) do
      table.remove(apples, ind)
    end

    rm = {}
  end

  if os.time() >= start_time + time_limit then
    nextGeneration()
  end
end

function love.draw()
  --love.graphics.setCanvas(canvas)
  -- Draw blocks
  for _, obj in pairs(objects) do
    obj:draw()
  end

  -- Draw apples
  for _, a in pairs(apples) do
    a:draw()
  end
  for _, p in pairs(players) do
    p:draw()
  end
  love.graphics.setColor(0, 0, 1)
  -- Draw border
  for i=0, border_width, 1 do
    love.graphics.rectangle("line", i, i, w - i*2, h - i*2)
  end
  love.graphics.setColor(1, 1, 1)
  --love.graphics.setCanvas()
  --love.graphics.draw(canvas, 256, 160, 0, 0.5, 0.5)
  -- Draw score
  love.graphics.print("Score: ".. players[1].score, 5, 5, 0, 2, 2)
end

function love.keypressed(k)
  if k == "escape" then
    love.event.quit()
  end

  if k == "a" then
    -- spawnApples()
  end

  if k == "s" then
    sound_on = not sound_on
  end
end

function playSound()
  if sound_on then
    appleSound:play()
  end
end