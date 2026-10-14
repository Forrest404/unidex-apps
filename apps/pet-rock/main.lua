-- Pet Rock: the lowest-maintenance pet there is. Pat it now and then (B), give it a new coat of paint (hold B),
-- and listen to what it has to say (A).
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

local PATTERNS = { "Plain", "Stripes", "Dots", "Zigzag", "Stars", "Speckles" }
local SAYINGS = {
  "...", "I'm a rock.", "Still here.", "Nice day for sitting.", "I've been thinking. Not much.",
  "Rocks don't need charging.", "Tell me about your day.", "Erosion is a long game.", "Gravity keeps me grounded.",
  "I was here before it was cool.", "Patience is my thing.", "Have you tried sitting still?", "I like your lanyard.",
  "Ten million years and still rolling.", "Solid advice: drink water.", "I'm not lazy. I'm igneous.",
}
local st = { born = 0, pat = 0, paint = 1, pats = 0 }
for k, v in (unidex.data.read("rock") or ""):gmatch("(%a+)=(%d+)") do st[k] = tonumber(v) end
local saying, hearts = nil, false

local function now()
  local d, t = today()
  return d * 1440 + t.hour * 60 + t.min, d, t  -- minutes
end

local function save()
  unidex.data.write("rock", string.format("born=%d pat=%d paint=%d pats=%d", st.born, st.pat, st.paint, st.pats))
end

local function mood(mins)
  local h = (mins - st.pat) / 60
  if h < 3 then return "happy" elseif h < 24 then return "content" elseif h < 72 then return "bored" end
  return "sleepy"
end

local CX, CY, RX, RY = 100, 112, 68, 40
local function edge(a)  -- a lumpy oval: not quite round, like a real stone
  local r = 1 + 0.05 * math.sin(a * 3 + 1) + 0.035 * math.cos(a * 5)
  return CX + math.floor(RX * r * math.cos(a) + 0.5), CY + math.floor(RY * r * math.sin(a) + 0.5)
end
local function inside(x, y)  -- comfortably inside the outline (for the paint)
  local dx, dy = (x - CX) / (RX * 0.86), (y - CY) / (RY * 0.82)
  return dx * dx + dy * dy < 1
end
local function inFace(x, y) return math.abs(x - CX) < 32 and y > CY - 20 and y < CY + 20 end

local function rock()
  local px, py = edge(0)
  for i = 1, 90 do
    local x, y = edge(i / 90 * 2 * math.pi)
    unidex.line(px, py, x, y); unidex.line(px + 1, py, x + 1, y); unidex.line(px, py + 1, x, y + 1)
    px, py = x, y
  end
  local p = PATTERNS[st.paint]
  local function spot(x, y, w, h)
    if inside(x, y) and inside(x + w, y + h) and not inFace(x, y) and not inFace(x + w, y + h) then unidex.fill(x, y, w, h) end
  end
  for y = CY - RY, CY + RY do
    local dy = y - CY
    if p == "Stripes" and dy % 10 == 0 then
      for x = CX - RX, CX + RX, 2 do spot(x, y, 2, 2) end
    elseif p == "Dots" and dy % 12 == 0 then
      for x = CX - RX + ((dy // 12) % 2) * 6, CX + RX, 12 do spot(x, y, 4, 4) end
    elseif p == "Zigzag" and dy % 14 == 0 then
      for x = CX - RX, CX + RX, 8 do spot(x, y + ((x // 8) % 2) * 4, 5, 2) end
    elseif p == "Stars" and dy % 18 == 0 then
      for x = CX - RX + ((dy // 18) % 2) * 9, CX + RX, 18 do spot(x - 1, y - 4, 3, 9); spot(x - 4, y - 1, 9, 3) end
    elseif p == "Speckles" and dy % 5 == 0 then
      for x = CX - RX, CX + RX, 7 do if (x * 7 + dy * 13) % 11 < 3 then spot(x, y, 2, 2) end end
    end
  end
end

local function face(m)
  local ly, lx, rx = CY - 8, CX - 16, CX + 16
  if m == "happy" then
    for _, x in ipairs({ lx, rx }) do unidex.line(x - 5, ly + 3, x, ly - 2); unidex.line(x, ly - 2, x + 5, ly + 3) end
  elseif m == "sleepy" then
    for _, x in ipairs({ lx, rx }) do unidex.fill(x - 5, ly + 1, 11, 2) end
    unidex.text(CX + 40, CY - 34, "z", "small"); unidex.text(CX + 50, CY - 46, "Z", "bold")
  else
    for _, x in ipairs({ lx, rx }) do disc(x, ly, 3) end
    if m == "bored" then for _, x in ipairs({ lx, rx }) do unidex.fill(x - 4, ly - 3, 9, 3, "white") end end
  end
  local my = CY + 10
  if m == "happy" then
    for i = -8, 8 do unidex.fill(CX + i, my + math.floor((64 - i * i) / 18), 1, 2) end
  elseif m == "content" then
    for i = -6, 6 do unidex.fill(CX + i, my + math.floor((36 - i * i) / 30), 1, 2) end
  elseif m == "bored" then unidex.fill(CX - 6, my + 2, 12, 2)
  else unidex.fill(CX - 3, my + 1, 6, 4) end
end

local function heart(x, y)
  disc(x - 4, y, 4); disc(x + 4, y, 4)
  for i = 0, 8 do unidex.fill(x - 8 + i, y + 1 + i, 17 - 2 * i, 1) end
end

function draw()
  local mins, d, t = now()
  if st.born == 0 and t.valid then st.born, st.pat = d, mins; save() end
  local m = t.valid and mood(mins) or "content"
  local days = t.valid and (d - st.born + 1) or 1
  unidex.header("Pet Rock", "day " .. days)
  if saying then
    local ls, line = {}, ""
    for word in saying:gmatch("%S+") do
      local try = line == "" and word or (line .. " " .. word)
      if unidex.width(try, "small") <= 172 or line == "" then line = try else ls[#ls + 1] = line; line = word end
    end
    ls[#ls + 1] = line
    unidex.rect(8, 28, 184, 6 + 17 * #ls)
    for i, l in ipairs(ls) do unidex.centered(28 + 17 * i - 2, l, "small") end
  end
  rock()
  face(m)
  if hearts then heart(CX - 60, CY - 36); heart(CX + 62, CY - 30) end
  local MOODS = { happy = "Happy", content = "Content", bored = "A bit bored", sleepy = "Fast asleep" }
  unidex.text(10, 158, MOODS[m] .. (st.pats > 0 and ("   " .. st.pats .. (st.pats == 1 and " pat" or " pats")) or ""), "tiny")
  unidex.hints("listen", "pat", "paint")
end

function onB()
  local mins, _, t = now()
  if not t.valid then return end
  st.pat, st.pats = mins, st.pats + 1
  save()
  hearts, saying = true, nil
  return "partial"
end

function onA()
  local pick
  repeat pick = SAYINGS[unidex.random(#SAYINGS)] until pick ~= saying
  saying, hearts = pick, false
  return "partial"
end

function onBHold()
  st.paint = st.paint % #PATTERNS + 1
  save()
  unidex.toast(PATTERNS[st.paint])
  hearts = false
  return "full"
end
