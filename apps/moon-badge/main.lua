-- Moon: a badge plugin. Tonight's moon, drawn from the date, with its phase and the days to the next full moon.
-- Shapes the API doesn't have: filled discs and circle outlines.
local function disc(cx, cy, r, colour)
  for dy = -r, r do
    local w = math.floor(math.sqrt(r * r - dy * dy) + 0.5)
    unidex.fill(cx - w, cy + dy, 2 * w + 1, 1, colour)
  end
end

local function ring(cx, cy, r, colour)
  local px, py
  for a = 0, 360, 6 do
    local x = cx + math.floor(r * math.cos(math.rad(a)) + 0.5)
    local y = cy + math.floor(r * math.sin(math.rad(a)) + 0.5)
    if px then unidex.line(px, py, x, y, colour) end
    px, py = x, y
  end
end
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

local SYNODIC = 29.530588853
local REF = 10957.75972  -- a new moon: 6 January 2000, 18:14 UTC, in days since 1 January 1970

local NAMES = { "New moon", "Waxing crescent", "First quarter", "Waxing gibbous", "Full moon", "Waning gibbous",
                "Last quarter", "Waning crescent" }

function badge()
  local dn, t = today()
  unidex.rect(4, 4, 192, 192)
  unidex.rect(6, 6, 188, 188)
  if not t.valid then
    unidex.centered(96, "Clock not set", "bold")
    unidex.centered(120, "Settings > Date & time", "small")
    return
  end
  local now = dn + (t.hour + t.min / 60) / 24
  local age = (now - REF) % SYNODIC
  local theta = age / SYNODIC * 2 * math.pi
  local cx, cy, r = 100, 86, 56
  -- The dark part is filled; the lit part stays paper-white
  for dy = -r, r do
    local w = math.sqrt(r * r - dy * dy)
    local t2 = w * math.cos(theta)
    local x1, x2
    if theta < math.pi then x1, x2 = -w, t2 else x1, x2 = -t2, w end
    if x2 > x1 then unidex.fill(cx + math.floor(x1 + 0.5), cy + dy, math.floor(x2 - x1 + 0.5), 1) end
  end
  ring(cx, cy, r)
  ring(cx, cy, r + 1)
  local name = NAMES[math.floor(age / SYNODIC * 8 + 0.5) % 8 + 1]
  local lit = math.floor((1 - math.cos(theta)) / 2 * 100 + 0.5)
  unidex.centered(166, name, "bold")
  local toFull = (SYNODIC / 2 - age) % SYNODIC
  local days = math.floor(toFull + 0.5)
  local next = days == 0 and "Full moon tonight" or (days == 1 and "Full moon tomorrow" or ("Full moon in " .. days .. " days"))
  unidex.centered(184, lit .. "% lit   " .. next, "tiny")
end
