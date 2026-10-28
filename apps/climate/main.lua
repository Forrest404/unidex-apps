-- Climate: the temperature and humidity from the board's SHTC3 sensor (unidex.climate, API 6).
-- First written by candour (Forrest404/unidex#25).
local reading, problem
local readAt  -- seconds into the day of the last reading

local function now()
  local t = unidex.time()
  return t.hour * 3600 + t.min * 60 + t.sec
end

local function refresh()
  reading, problem = unidex.climate()
  readAt = now()
  unidex.wake_in(60000)
end

function onEnter()
  refresh()
end

function draw()
  unidex.header("Climate")
  if not reading then
    unidex.centered(80, "Sensor unavailable")
    unidex.centered(100, problem or "Read failed")
  else
    unidex.centered(70, string.format("%.1f C", reading.temperature_c), "large")
    unidex.centered(115, string.format("%.0f%% humidity", reading.humidity_rh), "medium")
    unidex.centered(150, "Inside the case: reads warm", "tiny")
  end
  unidex.hints("", "refresh")
end

function onB()
  refresh()
  return "partial"
end

function tick()
  local d = (now() - readAt) % 86400
  if d >= 60 then
    refresh()
    return "partial"
  end
end
