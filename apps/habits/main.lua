-- Habits: tick off up to five habits each day and keep the streak going.
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

local CHOICES = { "Water", "Exercise", "Read", "Study", "Sleep by 11", "Walk", "Stretch", "Meditate", "Journal",
                  "Fruit & veg", "No phone in bed", "Floss", "Tidy up", "Practise", "Call someone" }
local habits = {}  -- { name, done = { [dayNumber] = true } }
for line in (unidex.data.read("habits") or ""):gmatch("[^\n]+") do
  local name, days = line:match("^([^:]+):(.*)$")
  if name then
    local h = { name = name, done = {} }
    for d in days:gmatch("%d+") do h.done[tonumber(d)] = true end
    habits[#habits + 1] = h
  end
end
if #habits == 0 then habits = { { name = "Water", done = {} }, { name = "Read", done = {} }, { name = "Walk", done = {} } } end
local at, choosing, sel = 1, false, 1

local function save(now)
  local lines = {}
  for _, h in ipairs(habits) do
    local days = {}
    for d in pairs(h.done) do if not now or d > now - 60 then days[#days + 1] = d end end  -- two months is plenty
    table.sort(days)
    lines[#lines + 1] = h.name .. ":" .. table.concat(days, " ")
  end
  unidex.data.write("habits", table.concat(lines, "\n"))
end

local function streak(h, now)
  local n, d = 0, h.done[now] and now or now - 1  -- today not done yet doesn't break it
  while h.done[d] do n, d = n + 1, d - 1 end
  return n
end

local function has(name)
  for i, h in ipairs(habits) do if h.name == name then return i end end
end

local function drawChooser()
  unidex.header("Your habits", #habits .. "/5")
  local first = math.max(1, sel - 4)
  for i = first, math.min(#CHOICES, first + 4) do
    local y = 28 + (i - first) * 26
    local on = has(CHOICES[i])
    if i == sel then unidex.fill(4, y, 192, 24) end
    local colour = i == sel and "white" or "black"
    unidex.rect(12, y + 6, 12, 12, colour)
    if on then unidex.fill(15, y + 9, 6, 6, colour) end
    unidex.text(32, y + 17, CHOICES[i], "small", colour)
  end
  unidex.hints("next", "tick", "")
end

function draw()
  if choosing then return drawChooser() end
  local now, t = today()
  if not t.valid then
    unidex.header("Habits")
    unidex.centered(80, "Clock not set", "bold")
    unidex.centered(104, "Set it in Settings first", "small")
    unidex.hints("", "", "choose habits")
    return
  end
  local s = streak(habits[at], now)
  unidex.header("Habits", s > 0 and (s .. (s == 1 and " day" or " days") .. " in a row") or "start a streak")
  local letters = { "S", "M", "T", "W", "T", "F", "S" }
  for i = 0, 6 do
    local d = now - 6 + i
    unidex.text(98 + i * 14, 37, letters[weekday(d)], "tiny")
  end
  for row, h in ipairs(habits) do
    local y = 42 + (row - 1) * 23
    local selected = row == at
    if selected then unidex.fill(4, y, 90, 20) end
    unidex.text(8, y + 15, h.name, "small", selected and "white" or "black")
    for i = 0, 6 do
      local d, x = now - 6 + i, 96 + i * 14
      unidex.rect(x, y + 4, 11, 11)
      if h.done[d] then unidex.fill(x + 2, y + 6, 7, 7) end
      if i == 6 then unidex.rect(x - 1, y + 3, 13, 13) end  -- today
    end
  end
  unidex.hints(#habits > 1 and "next" or "", habits[at].done[now] and "untick today" or "done today", "choose habits")
end

function onA()
  if choosing then sel = sel % #CHOICES + 1; return "partial" end
  if #habits > 1 then at = at % #habits + 1; return "partial" end
end

function onB()
  if choosing then
    local i = has(CHOICES[sel])
    if i then
      if #habits == 1 then unidex.toast("Keep at least one"); return "partial" end
      table.remove(habits, i)
    elseif #habits >= 5 then unidex.toast("Five at most")
    else habits[#habits + 1] = { name = CHOICES[sel], done = {} } end
    at = math.min(at, #habits)
    save()
    return "partial"
  end
  local now, t = today()
  if not t.valid then return end
  local h = habits[at]
  h.done[now] = not h.done[now] or nil
  save(now)
  if h.done[now] then
    local s = streak(h, now)
    unidex.toast(s > 1 and (s .. " days in a row!") or "Done for today")
  end
  return "partial"
end

function onBHold()
  if not choosing then choosing, sel = true, 1; return "full" end
end

function onBack()
  if choosing then choosing = false; return "full" end
  return "exit"
end
