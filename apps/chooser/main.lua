-- Chooser: pick 2-9 squares, spin, land on a random winner. A = more squares, B = spin, hold B = the tally (wins
-- per square number over every spin; hold B there to clear it), hold A = back. The spin is drawn frame by frame
-- with unidex.frame, slowing down as it goes.
local MIN_N, MAX_N, MIN_HOPS = 2, 9, 6
local GAP, GRID_TOP, TEXT_Y = 4, 30, 149  -- TEXT_Y: the middle of the line under the grid
local SAYINGS = { "It's #%d.", "#%d it is.", "#%d wins." }

local n = math.min(MAX_N, math.max(MIN_N, tonumber(unidex.data.read("n") or "") or MIN_N))
local tally = {}
local saved = unidex.data.read("tally") or ""
for i = 1, MAX_N do tally[i] = tonumber(saved:match("^" .. string.rep("[^,]*,", i - 1) .. "(%d+)")) or 0 end

local screen, returnTo = "count", "count"
local winner, highlight = nil, nil  -- the last result (1..n), and the square lit during the spin

local function saveTally()
  unidex.data.write("tally", table.concat(tally, ","))
end

-- `count` squares in reading order, centred between the header and the line of text.
local function drawGrid(count, inverted, showTally)
  local cols = math.ceil(math.sqrt(count))
  local rows = (count + cols - 1) // cols
  local areaW, areaH = 184, TEXT_Y - 16 - GRID_TOP
  local cell = math.min((areaW + GAP) // cols, (areaH + GAP) // rows) - GAP
  local x0 = (200 - (cols * (cell + GAP) - GAP)) // 2
  local y0 = GRID_TOP + (areaH - (rows * (cell + GAP) - GAP)) // 2
  for i = 1, count do
    local x, y = x0 + ((i - 1) % cols) * (cell + GAP), y0 + ((i - 1) // cols) * (cell + GAP)
    local ink = "black"
    if i == inverted then
      unidex.fill(x, y, cell, cell)
      ink = "white"
    else
      unidex.rect(x, y, cell, cell)
      unidex.rect(x + 1, y + 1, cell - 2, cell - 2)
    end
    local label, top = tostring(i), y
    if showTally then  -- the square's number small in the top corner, its wins in the space below
      unidex.text(x + 4, y + 11, "#" .. i, "tiny", ink)
      label, top = tostring(tally[i]), y + 12
    end
    unidex.text(x + (cell - unidex.width(label)) // 2, top + (y + cell - top) // 2 + 5, label, "small", ink)
  end
end

local function line(text) unidex.centered(TEXT_Y + 5, text) end  -- (centered takes the baseline)

function draw()
  if screen == "tally" or screen == "clear" then
    unidex.header("Tally")
    drawGrid(MAX_N, nil, true)
    line("wins over every spin")
  elseif screen == "spin" then
    unidex.header("Chooser")
    drawGrid(n, highlight, false)
    line("...")
  elseif screen == "result" then
    unidex.header("Chooser")
    drawGrid(n, winner, false)
    line(string.format(SAYINGS[(winner - 1 + n) % 3 + 1], winner))
  else
    unidex.header("Chooser")
    drawGrid(n, nil, false)
    line(n .. " squares")
  end
  if screen == "clear" then  -- the question on a sheet over the tally
    unidex.fill(8, 38, 184, 115, "white")
    unidex.rect(8, 38, 184, 115)
    unidex.rect(9, 39, 182, 113)
    unidex.centered(79, "Clear the tally?", "bold")
    unidex.centered(106, "Wins go back to 0.")
    unidex.centered(128, "Can't be undone.")
    unidex.hints("keep", "clear", "")
  elseif screen == "tally" then
    unidex.hints("", "", "clear")
  elseif screen == "result" then
    unidex.hints("change", "again", "tally")
  elseif screen == "count" then
    unidex.hints("+1", "spin", "tally")
  end
end

-- Hops along the squares, each a little slower, and stops on the winner.
local function spin()
  winner = unidex.random(n)
  local hops = MIN_HOPS + unidex.random(n) - 1
  highlight = (winner - 1 - (hops - 1)) % n + 1  -- worked backwards, so the walk ends on the winner
  screen = "spin"
  for k = 1, hops do
    local t = k / hops
    unidex.frame(40 + math.floor(560 * t * t * t))  -- ease-out
    highlight = highlight % n + 1
  end
  tally[winner] = tally[winner] + 1
  saveTally()
  screen = "result"
end

function onA()
  if screen == "clear" then
    screen = "tally"
  elseif screen == "count" or screen == "result" then
    if screen == "count" then
      n = n >= MAX_N and MIN_N or n + 1
      unidex.data.write("n", tostring(n))
    end
    screen = "count"
  else
    return
  end
  return "partial"
end

function onB()
  if screen == "clear" then
    for i = 1, MAX_N do tally[i] = 0 end
    saveTally()
    unidex.toast("Tally cleared")
    screen = "tally"
    return "partial"
  elseif screen == "count" or screen == "result" then
    spin()
    return "full"  -- the reveal: also clears the spin's ghosting
  end
end

function onBHold()
  if screen == "count" or screen == "result" then
    returnTo, screen = screen, "tally"
  elseif screen == "tally" then
    screen = "clear"
  else
    return
  end
  return "partial"
end

function onBack()
  if screen == "count" then return "exit" end
  if screen == "tally" then screen = returnTo
  elseif screen == "clear" then screen = "tally"
  else screen = "count" end
  return "partial"
end
