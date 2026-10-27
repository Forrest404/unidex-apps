-- Hop, a one-button game for Games. Blocks come from the right, and B hops over them.
-- A tap clears a low block; hold B on the way up to hop higher, over a tall one.
-- Guide: https://github.com/Forrest404/unidex-apps/blob/main/GAMES.md

local GROUND = 160                         -- the y of the ground line
local RUNNER_X, RUNNER_W, RUNNER_H = 30, 12, 16
local BLOCK_W, LOW, TALL = 10, 14, 28      -- block width, and the two heights
local FORGIVE = 2                          -- near misses count as a clear: kinder on a slow screen

local height, rise   -- the runner: pixels above the ground, and how fast it's going up
local blocks         -- the blocks on the way: { x = left edge, h = height }
local speed          -- how many pixels the blocks move each frame
local cleared        -- blocks hopped over: the score
local waiting        -- true until the first press
local moved          -- how far the ground has scrolled, for the pebbles

-- Adds a block somewhere to the right of x. Faster means further apart, so a hop always fits.
local function addBlock(x)
  local h = LOW
  if math.random(3) == 1 then h = TALL end  -- about one in three is tall
  table.insert(blocks, { x = x + speed * 20 + math.random(0, 60), h = h })
end

-- A new round. Set everything here: a game plays many rounds without starting again.
function start(seed)
  math.randomseed(seed)  -- the same seed gives the same blocks
  height, rise = 0, 0
  speed, cleared, moved = 5, 0, 0
  waiting = true
  blocks = {}
  addBlock(200)
  addBlock(blocks[1].x)
  addBlock(blocks[2].x)
end

-- One frame. tapped: B was pressed since the last frame. held: B is down now.
function step(tapped, held)
  if waiting then
    if not tapped then return "still" end  -- nothing moves until the first press
    waiting = false
  end

  -- Hop. A press on the ground starts one; holding B on the way up pulls less, so it goes higher.
  if tapped and height == 0 then rise = 9 end
  if height > 0 or rise > 0 then
    height = height + rise
    if held and rise > 0 then rise = rise - 1 else rise = rise - 2 end
    if height <= 0 then height, rise = 0, 0 end  -- landed
  end

  moved = moved + speed
  for _, b in ipairs(blocks) do
    b.x = b.x - speed
    local beside = b.x < RUNNER_X + RUNNER_W - FORGIVE and b.x + BLOCK_W > RUNNER_X + FORGIVE
    if beside and height < b.h - FORGIVE then
      return "over"  -- touched it
    end
    if not b.passed and b.x + BLOCK_W < RUNNER_X then
      b.passed = true
      cleared = cleared + 1
      speed = math.min(10, 5 + cleared // 5)  -- a little faster every 5 blocks
    end
  end

  -- A block gone off the left: a new one comes after the last.
  if blocks[1].x + BLOCK_W < 0 then
    table.remove(blocks, 1)
    addBlock(blocks[#blocks].x)
  end
  return "moved"
end

-- The whole play screen. No header or hints: the Games app shows none while you play.
function draw()
  unidex.fill(0, GROUND, 200, 2)  -- the ground
  for i = 0, 3 do                 -- pebbles scrolling past, so you can see it moving
    local x = (i * 53 - moved) % 200
    unidex.fill(x, GROUND + 8, 5, 2)
  end

  for _, b in ipairs(blocks) do
    if b.x < 200 then unidex.fill(b.x, GROUND - b.h, BLOCK_W, b.h) end
  end

  local top = GROUND - height - RUNNER_H
  unidex.fill(RUNNER_X, top, RUNNER_W, RUNNER_H)
  unidex.fill(RUNNER_X + 7, top + 3, 3, 3, "white")  -- an eye

  local text = tostring(cleared)
  unidex.text(192 - unidex.width(text, "medium"), 20, text, "medium")

  if waiting then
    unidex.centered(80, "B to hop", "bold")
    unidex.centered(100, "hold B to hop higher")
  end
end

function score()
  return cleared
end
