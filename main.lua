local lume = require "lib/lume"
local json = require "lib/json"

local w, h = 1300, 720
local players = {}
local start_time = 0
local knockback_mult = 5
local border_width = 10
local apples = {}
local sound_on = true
local appleSound = love.audio.newSource("apple.wav", "static")
local objects = {}
local view_x, view_y = -420, -590
local view_delta = 10

local simulation_started = false

local generation = 0
local OBJST_CHECK = false
local LEVEL_NAME = "level2.json"
local TIME_LIMIT = 10
local POPULATION_SIZE = 100
local GENES = { ["00"] = "l", ["01"] = "r", ["10"] = "f", __index = nil } -- nucleotides
local GENE_LENGTH = 2 -- "l", "f", "r"
local CHROMOSOME_LENGTH = TIME_LIMIT * 10 * GENE_LENGTH
local CROSSOVER_RATE = 0.4
local TARGET_LOCATION = {}
local MUTATION_RATE = 0.02

--[[ SAMPLE CHROMOSOME --
00110000100110000100111100000101001110101100001101010101100000011101000011001100001111000
00010101111111001000001111000010100111111010010011001011111001110001001001101001011111101
0000001110100100011001
]]--


function newPlayer(x, y, chromo)
  local p = {
    x = x,
    y = y,
    radius = 20,
    ox = 20,
    oy = 20,
    chromosome = chromo or randomChromosome(),
    rotation = 0,
    rotspeed = math.pi,
    speed = 250,
    hit = false,
    finished = false,
    fitness = 0,
    sprite = love.graphics.newImage("player.png"),
    update = function(self, dt, time)
      if not self.hit then
        local dt = dt
        if dt >= 0.02 then dt = 0.02 end
        local time = math.floor(time * 10)
        if time > #self.controls then
          time = time % #self.controls
        end
        -- Controls
        if self.controls[time] == "r" then
          self.rotation = self.rotation + self.rotspeed * dt
        elseif self.controls[time] == "l" then
          self.rotation = self.rotation - self.rotspeed * dt
        end

        local dx = self.speed * math.cos(self.rotation - math.pi/2) * dt
        local dy = self.speed * math.sin(self.rotation - math.pi/2) * dt
        self.x = self.x + dx
        self.y = self.y + dy
      end
    end,
    draw = function(self)
      love.graphics.setColor(1, 1, 1, 0.5)
      love.graphics.draw(self.sprite, self.x, self.y, self.rotation, 1, 1, self.ox, self.oy)
    end
  }
  p.controls = toControls(p.chromosome)
  return p
end

function newWin(x, y)
  return {
    x = x, y = y,
    tag = "win",
    width = 30,
    height = 30,
    draw = function(self)
      love.graphics.setColor(1, 1, 0)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(1, 1, 1)
    end
  }
end

function newBlock(x, y)
  return {
    x = x, y = y,
    tag = "block",
    width = 50,
    height = 50,
    draw = function(self)
      love.graphics.setColor(0, 0, 1)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
      love.graphics.setColor(1, 1, 1)
    end
  }
end

function randomChromosome()
  local r = ""
  for i=1, CHROMOSOME_LENGTH do
    r = r .. lume.randomchoice({"0", "1"})
  end
  return r
end

function toControls(chromo)
  local r = {}
  for i=1, CHROMOSOME_LENGTH, GENE_LENGTH do
    local control = GENES[chromo:sub(i, i + GENE_LENGTH-1)]
    if control then
      table.insert(r, control)
    end
  end
  return r
end

function calculateFitness(p, desired_position)
  if p.finished then
    --print("FINISHED")
    return 999
  end
  if lume.distance(p.x, p.y, desired_position[1], desired_position[2], true) <= p.radius then
    --print("FINISHED")
    return 999
  end
  -- Fitness based on distance
  local ret = 1 / lume.distance(p.x, p.y, desired_position[1], desired_position[2], true)
  -- Count obstacles on the way and give points for less obstackles
  if OBJST_CHECK then
    local obstCount = 0
    local k = (p.x - desired_position[1]) / (p.y - desired_position[2])
    local y = p.y
    for x=p.x, desired_position[1] do
      y = k * x + p.x
      for _, obj in pairs(objects) do
        if lume.aabb(x, y, 0, 0, obj.x, obj.y, obj.width, obj.height) then
          obstCount = obstCount + 1
        end
      end
    end
    ret = ret + 1/obstCount
  end
  return ret
end

function roulette(total_fitness, pop)
  local fitSoFar = 0
  local arrow = lume.random(0, total_fitness)
  for _, p in pairs(pop) do
    fitSoFar = fitSoFar + p.fitness
    if fitSoFar >= arrow then
      return p.chromosome
    end
  end
end

function crossover(c1, c2)
  if lume.random() <= CROSSOVER_RATE then
    local crossoverPoint = math.floor(lume.random(1, CHROMOSOME_LENGTH))
    local c1_part_1 = c1:sub(1, crossoverPoint-1)
    local c1_part_2 = c1:sub(crossoverPoint, CHROMOSOME_LENGTH)
    local c2_part_1 = c2:sub(1, crossoverPoint-1)
    local c2_part_2 = c2:sub(crossoverPoint, CHROMOSOME_LENGTH)
    local r1 = c1_part_1 .. c2_part_2
    local r2 = c2_part_1 .. c1_part_2
    return {r1, r2}
  else
    return {c1, c2}
  end
end

function mutate(chromo)
  local ret = ""
  for i=1, CHROMOSOME_LENGTH do
    if lume.random() <= MUTATION_RATE then
      if chromo:sub(i, i) == "0" then
        ret = ret .. "1"
      else
        ret = ret .. "0"
      end
    else
      ret = ret .. chromo:sub(i, i)
    end
  end
  return ret
end

function nextGeneration()
  start_time = love.timer.getTime()
  -- Rate every player
  local totalFitness = 0
  for _, p in pairs(players) do
    p.fitness = calculateFitness(p, TARGET_LOCATION)
    totalFitness = totalFitness + p.fitness
  end
  -- Repopulate
  local new_players = {}
  for i=1, POPULATION_SIZE, 2 do
    -- Breed with roulette
    local parent1 = roulette(totalFitness, players)
    local parent2 = roulette(totalFitness, players)
    -- Crossover
    local childChromos = crossover(parent1, parent2)
    --print(childChromo.. "\n\n")
    -- Mutate
    local child1 = mutate(childChromos[1])
    local child2 = mutate(childChromos[2])
    -- Birth
    table.insert(new_players, newPlayer(level["player"][1][1], level["player"][1][2], child1))
    table.insert(new_players, newPlayer(level["player"][1][1], level["player"][1][2], child2))
  end
  players = new_players
  generation = generation + 1
end

function love.load()
  --canvas = love.graphics.newCanvas(canvas_width, canvas_height)
  love.window.setMode(w, h)
  math.randomseed(os.time())
  start_time = love.timer.getTime()

  objects = {}
  level = json.decode(readFile(LEVEL_NAME))

  -- Blocks
  if level["block"] then
    for _, block in pairs(level["block"]) do
      table.insert(objects, newBlock(block[1], block[2]))
    end
  end

  -- Win
  local w = newWin(level["win"][1][1], level["win"][1][2])
  table.insert(objects, w)
  TARGET_LOCATION = {w.x + w.width/2, w.y + w.height/2}

  -- Player(s)
  for i=1, POPULATION_SIZE do
    table.insert(players, newPlayer(level["player"][1][1], level["player"][1][2]))
  end
end

function love.update(dt)
  cameraControls()
  if simulation_started then
    local all_hit = true
    for _, p in pairs(players) do
      p:update(dt, love.timer.getTime() - start_time)

      -- Check wall collisions
      for _, obj in pairs(objects) do
        if isColliding(p, obj) then
          if obj.tag == "block" then
            p.hit = true
          elseif obj.tag == "win" then
            p.finished = true
          end
        end
      end

      -- For checking if every player got hit
      if not p.hit then
        all_hit = false
      end
    end

    -- Check if all hit or time limit ran out
    if all_hit or love.timer.getTime() >= start_time + TIME_LIMIT then
      nextGeneration()
    end
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Generation: ".. generation)
  local tm = math.floor(love.timer.getTime() - start_time)
  love.graphics.print("\nTime: ".. tostring(tm) .. "/" .. tostring(TIME_LIMIT))
  love.graphics.translate(-view_x, -view_y)

  -- Draw level
  for _, obj in pairs(objects) do
    obj:draw()
  end
  -- Draw Players
  for _, p in pairs(players) do
    p:draw()
  end
end

function love.keypressed(k)
  if k == "escape" then
    love.event.quit()
  end

  if k == "return" then
    simulation_started = true
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

function cameraControls()
  if love.keyboard.isDown("up") then
    view_y = view_y - view_delta
  end

  if love.keyboard.isDown("down") then
    view_y = view_y + view_delta
  end

  if love.keyboard.isDown("left") then
    view_x = view_x - view_delta
  end

  if love.keyboard.isDown("right") then
    view_x = view_x + view_delta
  end
end

function isColliding(p, obj)
  local rectpoint = {0, 0}
  -- Get closest point on rect to player
  if p.y <= obj.y then --[[ Top ]]--
    if p.x < obj.x then -- Left
      rectpoint = {obj.x, obj.y}
    elseif p.x > obj.x and p.x < obj.x + obj.width then -- Center
      rectpoint = {p.x, obj.y}
    elseif p.x > obj.x + obj.width then-- Right
      rectpoint = {obj.x + obj.width, obj.y}
    end
  elseif p.y >= obj.y and p.y <= obj.y + obj.height then --[[ Middle ]]
    if p.x < obj.x then -- Left
      rectpoint = {obj.x, p.y}
    elseif p.x > obj.x and p.x < obj.x + obj.width then -- Center
      rectpoint = {p.x, p.y}
    elseif p.x > obj.x + obj.width then -- Right
      rectpoint = {obj.x + obj.width, p.y}
    end
  elseif p.y >= obj.y + obj.height then --[[ Bottom ]]
    if p.x < obj.x then -- Left
      rectpoint = {obj.x, obj.y + obj.height}
    elseif p.x > obj.x and p.x < obj.x + obj.width then -- Center
      rectpoint = {p.x, obj.y + obj.height}
    elseif p.x > obj.x + obj.width then -- Right
      rectpoint = {obj.x + obj.width, obj.y + obj.height}
    end
  end

  -- Check distance from closest point
  if lume.distance(p.x, p.y, rectpoint[1], rectpoint[2], true) <= p.radius * p.radius then
    return true
  end

  return false
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
