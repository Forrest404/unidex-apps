-- Water: one press per glass. The glass fills toward today's goal and starts again at midnight.
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
-- Dates without os: day numbers (days since 1 Jan 1970) and back.
local function dayNumber(y, m, d)
  y = m <= 2 and y - 1 or y
  local era = (y >= 0 and y or y - 399) // 400
  local yoe = y - era * 400
  local doy = (153 * (m + (m > 2 and -3 or 9)) + 2) // 5 + d - 1
  local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
  return era * 146097 + doe - 719468
end

local function fromDayNumber(z)
  z = z + 719468
  local era = (z >= 0 and z or z - 146096) // 146097
  local doe = z - era * 146097
  local yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
  local y = yoe + era * 400
  local doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
  local mp = (5 * doy + 2) // 153
  local d = doy - (153 * mp + 2) // 5 + 1
  local m = mp + (mp < 10 and 3 or -9)
  return m <= 2 and y + 1 or y, m, d
end

local function today()
  local t = unidex.time()
  return dayNumber(t.year, t.month, t.day), t
end

local WEEKDAYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local function weekday(dn) return (dn + 4) % 7 + 1 end  -- 1 = Sunday (1 Jan 1970 was a Thursday)
local function dateText(dn)
  local y, m, d = fromDayNumber(dn)
  return string.format("%s %d %s %d", WEEKDAYS[weekday(dn)], d, MONTHS[m], y)
end

local goal = tonumber(unidex.data.read("goal") or "8") or 8
local day, count, past = nil, 0, {}  -- past: the last 7 days' counts, most recent first
do
  local d, c, p = (unidex.data.read("today") or ""):match("^(%d+) (%d+) ?(.*)$")
  day, count = tonumber(d), tonumber(c) or 0
  for v in (p or ""):gmatch("%d+") do past[#past + 1] = tonumber(v) end
end
local settingGoal = false

local function rollOver(now)
  if not day then day = now; return end
  while day < now do  -- one entry per day that went by
    table.insert(past, 1, count)
    count, day = 0, day + 1
  end
  while #past > 7 do table.remove(past) end
end

local function save()
  unidex.data.write("today", string.format("%d %d %s", day, count, table.concat(past, " ")))
end

local function glass(x, y, w, h, fullness)
  local inset = 8  -- narrower at the bottom
  for row = 0, h - 1 do
    local cut = math.floor(inset * row / h)
    if row >= h - math.floor(h * fullness) then unidex.fill(x + cut + 3, y + row, w - 2 * cut - 6, 1) end
  end
  unidex.line(x, y, x + inset, y + h); unidex.line(x + 1, y, x + inset + 1, y + h)
  unidex.line(x + w, y, x + w - inset, y + h); unidex.line(x + w - 1, y, x + w - inset - 1, y + h)
  unidex.line(x + inset, y + h, x + w - inset, y + h); unidex.line(x + inset, y + h - 1, x + w - inset, y + h - 1)
end

function draw()
  local now, t = today()
  if settingGoal then
    unidex.header("Daily goal")
    bigCentered(tostring(goal), 52, 9)
    unidex.centered(134, "glasses a day", "small")
    unidex.hints("change", "done", "")
    return
  end
  if t.valid then rollOver(now) end
  unidex.header("Water", t.valid and string.format("%d %s", t.day, MONTHS[t.month]) or nil)
  glass(14, 34, 64, 104, math.min(1, count / goal))
  local s = tostring(count)
  big(s, 92, 42, 6)
  unidex.text(92 + #s * 36 + 2, 84, "/" .. goal, "medium")
  local left = goal - count
  unidex.text(94, 112, left > 0 and (left .. " to go") or "Goal met!", "bold")
  -- The week: one bar per day, today on the right
  local days = { count }
  for i = 1, 6 do days[#days + 1] = past[i] or 0 end
  for i = 1, 7 do
    local v, x = days[i], 182 - (i - 1) * 13
    local h = math.min(20, math.floor(20 * v / goal + 0.5))
    unidex.rect(x, 126, 9, 22)
    if h > 0 then unidex.fill(x + 1, 147 - h, 7, h) end
  end
  unidex.text(96, 158, "7 days", "tiny")
  unidex.hints("undo", "+1 glass", "goal")
end

function onB()
  if settingGoal then settingGoal = false; unidex.data.write("goal", tostring(goal)); return "full" end
  count = count + 1
  save()
  if count == goal then unidex.toast("Goal reached!") end
  return "partial"
end

function onA()
  if settingGoal then goal = goal >= 12 and 4 or goal + 1; return "partial" end
  if count > 0 then count = count - 1; save(); return "partial" end
end

function onBHold()
  if not settingGoal then settingGoal = true; return "full" end
end

function onBack()
  if settingGoal then settingGoal = false; unidex.data.write("goal", tostring(goal)); return "full" end
  return "exit"
end
