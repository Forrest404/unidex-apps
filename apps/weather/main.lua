-- Weather: today's weather for a city you pick, from Open-Meteo (no account or key). B updates it over WiFi;
-- the last forecast stays on screen when there's no connection. Hold B to pick the city.
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

local CITIES = {
  { "London", 51.51, -0.13 }, { "Manchester", 53.48, -2.24 }, { "Birmingham", 52.49, -1.89 }, { "Leeds", 53.80, -1.55 },
  { "Liverpool", 53.41, -2.98 }, { "Bristol", 51.45, -2.59 }, { "Newcastle", 54.98, -1.61 }, { "Sheffield", 53.38, -1.47 },
  { "Nottingham", 52.95, -1.15 }, { "Oxford", 51.75, -1.26 }, { "Cambridge", 52.21, 0.12 }, { "Brighton", 50.82, -0.14 },
  { "Edinburgh", 55.95, -3.19 }, { "Glasgow", 55.86, -4.25 }, { "Cardiff", 51.48, -3.18 }, { "Belfast", 54.60, -5.93 },
  { "Dublin", 53.35, -6.26 }, { "Paris", 48.86, 2.35 }, { "Berlin", 52.52, 13.40 }, { "Madrid", 40.42, -3.70 },
  { "New York", 40.71, -74.01 }, { "Tokyo", 35.68, 139.69 },
}

local w = {}  -- city, temp, code, hi, lo, rain, at (when it was fetched: "day hh:mm")
for k, v in (unidex.data.read("weather") or ""):gmatch("(%a+)=([^;]*)") do w[k] = v end
local city = tonumber(w.city) or 1
if not CITIES[city] then city = 1 end
local choosing, sel, problem = false, city, nil

local function fit(text, w, font)
  if unidex.width(text, font) <= w then return text end
  while #text > 1 and unidex.width(text .. "...", font) > w do text = text:sub(1, -2) end
  return text .. "..."
end

local function kind(code)
  code = tonumber(code) or -1
  if code == 0 then return "sun", "Clear"
  elseif code <= 2 then return "partly", "Partly cloudy"
  elseif code == 3 then return "cloud", "Cloudy"
  elseif code == 45 or code == 48 then return "fog", "Fog"
  elseif code >= 51 and code <= 57 then return "rain", "Drizzle"
  elseif (code >= 61 and code <= 67) or (code >= 80 and code <= 82) then return "rain", code >= 80 and "Showers" or "Rain"
  elseif (code >= 71 and code <= 77) or code == 85 or code == 86 then return "snow", "Snow"
  elseif code >= 95 then return "storm", "Thunder"
  end
  return "cloud", "Unknown"
end

local function cloud(cx, cy)
  disc(cx - 12, cy + 2, 11); disc(cx + 2, cy - 6, 15); disc(cx + 16, cy + 3, 10)
  unidex.fill(cx - 12, cy + 2, 28, 12)
  disc(cx - 12, cy + 2, 8, "white"); disc(cx + 2, cy - 6, 12, "white"); disc(cx + 16, cy + 3, 7, "white")
  unidex.fill(cx - 12, cy + 2, 28, 9, "white")
end

local function icon(k, cx, cy)
  if k == "sun" or k == "partly" then
    local sx, sy = k == "sun" and cx or cx - 10, k == "sun" and cy or cy - 10
    disc(sx, sy, 11)
    for a = 0, 315, 45 do
      local c, s = math.cos(math.rad(a)), math.sin(math.rad(a))
      unidex.line(sx + math.floor(15 * c), sy + math.floor(15 * s), sx + math.floor(21 * c), sy + math.floor(21 * s))
    end
    if k == "partly" then
      disc(cx + 6, cy + 8, 17, "white")
      cloud(cx + 6, cy + 8)
    end
    return
  end
  if k == "fog" then
    for i = 0, 3 do unidex.fill(cx - 22 + (i % 2) * 6, cy - 12 + i * 8, 40, 3) end
    return
  end
  cloud(cx, cy - 6)
  if k == "rain" then
    for i = 0, 3 do unidex.line(cx - 14 + i * 9, cy + 12, cx - 18 + i * 9, cy + 22) end
  elseif k == "snow" then
    for i = 0, 3 do local x = cx - 14 + i * 9; unidex.fill(x - 1, cy + 14 + (i % 2) * 6, 3, 3) end
  elseif k == "storm" then
    unidex.line(cx + 2, cy + 10, cx - 4, cy + 19); unidex.line(cx - 4, cy + 19, cx + 4, cy + 19); unidex.line(cx + 4, cy + 19, cx - 2, cy + 28)
    unidex.line(cx + 3, cy + 10, cx - 3, cy + 19); unidex.line(cx + 5, cy + 19, cx - 1, cy + 28)
  end
end

local function drawChooser()
  unidex.header("Pick your city")
  local first = math.max(1, sel - 4)
  for i = first, math.min(#CITIES, first + 4) do
    local y = 28 + (i - first) * 26
    if i == sel then unidex.fill(4, y, 192, 24) end
    unidex.text(12, y + 17, CITIES[i][1], "small", i == sel and "white" or "black")
    if i == city then unidex.text(170, y + 17, "*", "small", i == sel and "white" or "black") end
  end
  unidex.hints("next", "choose", "")
end

function draw()
  if choosing then return drawChooser() end
  unidex.header("Weather", CITIES[city][1])
  if not w.temp or tonumber(w.city) ~= city then
    unidex.centered(70, "No forecast yet", "bold")
    unidex.centered(96, "Press B to get it", "small")
    unidex.centered(116, "(needs WiFi, set up on the", "tiny")
    unidex.centered(130, "website's Setup page)", "tiny")
    if problem then unidex.centered(152, fit(problem, 184, "tiny"), "tiny") end
    unidex.hints("", "update", "city")
    return
  end
  local k, label = kind(w.code)
  icon(k, 46, 74)
  local t = tostring(math.floor(tonumber(w.temp) + 0.5))
  big(t, 96, 46, 6)
  local x = 96 + #t * 36 + 2
  ring(x + 4, 50, 3)
  unidex.text(x + 10, 60, "C", "bold")
  unidex.text(96, 112, label, "bold")
  local hi, lo = math.floor(tonumber(w.hi) + 0.5), math.floor(tonumber(w.lo) + 0.5)
  local line = string.format("High %d  Low %d", hi, lo) .. (w.rain ~= "" and ("  Rain " .. w.rain .. "%") or "")
  local font = unidex.width(line, "small") <= 184 and "small" or "tiny"  -- the small font fits only short lines
  unidex.centered(136, line, font)
  local dn = today()
  local day, at = (w.at or ""):match("^(%d+) (.*)$")
  local when = tonumber(day) == dn and ("today " .. at) or ("on " .. (day and dateText(tonumber(day)) or "?"))
  unidex.text(14, 156, fit(problem or ("Updated " .. when), 176, "tiny"), "tiny")
  unidex.hints("", "update", "city")
end

local function fetch()
  local c = CITIES[city]
  local url = string.format("https://api.open-meteo.com/v1/forecast?latitude=%.2f&longitude=%.2f" ..
    "&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max" ..
    "&timezone=auto&forecast_days=1", c[2], c[3])
  local status, body = unidex.http.get(url)
  if not status then problem = "No update: " .. tostring(body); return end
  if status ~= 200 then problem = "Couldn't update (error " .. status .. ")"; return end
  local cur = body:match('"current"%s*:%s*(%b{})') or ""
  local daily = body:match('"daily"%s*:%s*(%b{})') or ""
  local function first(src, key) return src:match('"' .. key .. '"%s*:%s*%[%s*(-?[%d%.]+)') end
  local temp = cur:match('"temperature_2m"%s*:%s*(-?[%d%.]+)')
  if not temp then problem = "Couldn't read the forecast"; return end
  local dn, t = today()
  w = { city = tostring(city), temp = temp, code = cur:match('"weather_code"%s*:%s*(%d+)') or "3",
        hi = first(daily, "temperature_2m_max") or temp, lo = first(daily, "temperature_2m_min") or temp,
        rain = first(daily, "precipitation_probability_max") or "", at = string.format("%d %02d:%02d", dn, t.hour, t.min) }
  local parts = {}
  for key, v in pairs(w) do parts[#parts + 1] = key .. "=" .. v end
  unidex.data.write("weather", table.concat(parts, ";"))
  problem = nil
end

function onB()
  if choosing then
    city, choosing = sel, false
    fetch()
    return "full"
  end
  fetch()
  if not problem then unidex.toast("Updated") end
  return "full"
end

function onA()
  if choosing then sel = sel % #CITIES + 1; return "partial" end
end

function onBHold()
  if not choosing then choosing, sel = true, city; return "full" end
end

function onBack()
  if choosing then choosing = false; return "full" end
  return "exit"
end
