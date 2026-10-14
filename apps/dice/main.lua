-- Dice: a d6, two d6 or a d20. B rolls, A changes the dice, hold B clears the history.
-- Big pixel digits: a 5x7 font drawn with filled boxes, k pixels per dot.
local GLYPHS = {
  ["0"] = { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
  ["1"] = { "00100", "01100", "00100", "00100", "00100", "00100", "01110" },
  ["2"] = { "01110", "10001", "00001", "00010", "00100", "01000", "11111" },
  ["3"] = { "11111", "00010", "00100", "00010", "00001", "10001", "01110" },
  ["4"] = { "00010", "00110", "01010", "10010", "11111", "00010", "00010" },
  ["5"] = { "11111", "10000", "11110", "00001", "00001", "10001", "01110" },
  ["6"] = { "00110", "01000", "10000", "11110", "10001", "10001", "01110" },
  ["7"] = { "11111", "00001", "00010", "00100", "01000", "01000", "01000" },
  ["8"] = { "01110", "10001", "10001", "01110", "10001", "10001", "01110" },
  ["9"] = { "01110", "10001", "10001", "01111", "00001", "00010", "01100" },
  [":"] = { "00000", "01100", "01100", "00000", "01100", "01100", "00000" },
  ["-"] = { "00000", "00000", "00000", "11111", "00000", "00000", "00000" },
  ["/"] = { "00001", "00010", "00010", "00100", "01000", "01000", "10000" },
  ["%"] = { "11001", "11010", "00010", "00100", "01000", "01011", "10011" },
  [" "] = { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
}

local function bigWidth(s, k) return #s * 6 * k - k end

local function big(s, x, y, k, colour)
  for i = 1, #s do
    local g = GLYPHS[s:sub(i, i)]
    if g then
      local gx = x + (i - 1) * 6 * k
      for r = 1, 7 do
        local row, c = g[r], 1
        while c <= 5 do
          if row:sub(c, c) == "1" then
            local e = c
            while e < 5 and row:sub(e + 1, e + 1) == "1" do e = e + 1 end
            unidex.fill(gx + (c - 1) * k, y + (r - 1) * k, (e - c + 1) * k, k, colour)
            c = e + 1
          else
            c = c + 1
          end
        end
      end
    end
  end
end

local function bigCentered(s, y, k, colour) big(s, (200 - bigWidth(s, k)) // 2, y, k, colour) end

local MODES = { "d6", "2d6", "d20" }
local mode = tonumber(unidex.data.read("mode") or "1") or 1
if not MODES[mode] then mode = 1 end
local history, roll = {}, nil
for v in (unidex.data.read("history") or ""):gmatch("%d+") do history[#history + 1] = tonumber(v) end

local PIPS = {  -- positions on a 3x3 grid (1 = top left ... 9 = bottom right)
  { 5 }, { 3, 7 }, { 3, 5, 7 }, { 1, 3, 7, 9 }, { 1, 3, 5, 7, 9 }, { 1, 3, 4, 6, 7, 9 },
}

local function die(x, y, size, value)
  unidex.rect(x, y, size, size)
  unidex.rect(x + 1, y + 1, size - 2, size - 2)
  for _, c in ipairs({ { x, y }, { x + size - 1, y }, { x, y + size - 1 }, { x + size - 1, y + size - 1 } }) do
    unidex.fill(c[1], c[2], 1, 1, "white")  -- rounded corners
  end
  local step, r = size // 4, math.max(3, size // 12)
  for _, p in ipairs(PIPS[value]) do
    local col, row = (p - 1) % 3, (p - 1) // 3
    unidex.fill(x + step * (col + 1) - r, y + step * (row + 1) - r, 2 * r + 1, 2 * r + 1)
  end
end

local function d20(cx, cy, value)
  local pts = {}
  for i = 0, 5 do
    local a = math.rad(60 * i - 90)
    pts[#pts + 1] = { cx + math.floor(46 * math.cos(a) + 0.5), cy + math.floor(46 * math.sin(a) + 0.5) }
  end
  for i = 1, 6 do local a, b = pts[i], pts[i % 6 + 1]; unidex.line(a[1], a[2], b[1], b[2]) end
  for i = 1, 6, 2 do local a, b = pts[i], pts[(i + 1) % 6 + 1]; unidex.line(a[1], a[2], b[1], b[2]) end
  local s = tostring(value)
  local k = 5
  unidex.fill(cx - (#s * 6 * k - k) // 2 - 4, cy - 2 * k - 2, #s * 6 * k - k + 8, 7 * k + 4, "white")
  big(s, cx - (#s * 6 * k - k) // 2, cy - 2 * k, k)
end

function draw()
  unidex.header("Dice", MODES[mode])
  if not roll then
    if mode == 3 then d20(100, 80, 20) elseif mode == 2 then die(30, 58, 60, 6); die(110, 58, 60, 6) else die(66, 52, 68, 6) end
    unidex.centered(150, "Press B to roll", "small")
  elseif mode == 1 then
    die(62, 46, 76, roll[1])
  elseif mode == 2 then
    die(26, 44, 66, roll[1]); die(108, 44, 66, roll[2])
    unidex.centered(134, "Total " .. (roll[1] + roll[2]), "bold")
  else
    d20(100, 82, roll[1])
  end
  if roll and #history > 1 then
    local past = {}
    for i = 2, math.min(#history, 6) do past[#past + 1] = tostring(history[i]) end
    unidex.centered(155, "Before: " .. table.concat(past, "  "), "tiny")
  end
  unidex.hints("dice", "roll", "clear")
end

function onB()
  roll = {}
  local n = mode == 2 and 2 or 1
  local sides = mode == 3 and 20 or 6
  local total = 0
  for i = 1, n do roll[i] = unidex.random(sides); total = total + roll[i] end
  table.insert(history, 1, total)
  while #history > 6 do table.remove(history) end
  unidex.data.write("history", table.concat(history, " "))
  return "full"
end

function onA()
  mode = mode % #MODES + 1
  unidex.data.write("mode", tostring(mode))
  roll = nil
  return "partial"
end

function onBHold()
  history, roll = {}, nil
  unidex.data.write("history", "")
  unidex.toast("History cleared")
  return "partial"
end
