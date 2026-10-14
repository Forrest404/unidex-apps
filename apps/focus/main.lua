-- Focus: a Pomodoro timer. 25 minutes of focus, then a 5-minute break (or 50 and 10).
-- The time comes from the clock, so it's right whenever you look, even after the device has slept.
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

local LENGTHS = { { 25, 5 }, { 50, 10 }, { 15, 3 } }
local st = { len = 1, phase = "idle", ends = 0, left = 0, sessions = 0, day = 0 }
for k, v in (unidex.data.read("state") or ""):gmatch("(%a+)=(%w+)") do st[k] = tonumber(v) or v end

local function now()
  local d, t = today()
  return d * 86400 + t.hour * 3600 + t.min * 60 + t.sec, d, t
end

local function save()
  unidex.data.write("state", string.format("len=%d phase=%s ends=%d left=%d sessions=%d day=%d",
    st.len, st.phase, st.ends, st.left, st.sessions, st.day))
end

local function remaining(n)
  if st.phase == "focus" or st.phase == "break" then return math.max(0, st.ends - n) end
  if st.phase == "paused" or st.phase == "pausedbreak" then return st.left end
  return LENGTHS[st.len][1] * 60
end

local function settle(n, d)
  if d ~= st.day then st.day, st.sessions = d, 0 end
  if (st.phase == "focus" or st.phase == "break") and n >= st.ends then
    if st.phase == "focus" then st.sessions = st.sessions + 1; st.phase = "focusdone" else st.phase = "idle" end
    save()
  end
end

local shown = -1
function draw()
  local n, d, t = now()
  if not t.valid then
    unidex.header("Focus")
    unidex.centered(80, "Clock not set", "bold")
    unidex.centered(104, "Set it in Settings first", "small")
    unidex.hints("", "", "")
    return
  end
  settle(n, d)
  local f, b = LENGTHS[st.len][1], LENGTHS[st.len][2]
  local titles = { idle = "Ready", focus = "Focus", paused = "Paused", ["break"] = "Break", pausedbreak = "Break paused",
                   focusdone = "Time for a break" }
  unidex.header(titles[st.phase] or "Focus", st.sessions > 0 and (st.sessions .. " done today") or nil)
  local left = remaining(n)
  if st.phase == "focusdone" then
    unidex.centered(80, "Well done.", "large")
    unidex.centered(108, b .. "-minute break next", "small")
    unidex.hints("", "start break", "stop")
    return
  end
  local mins = string.format("%d:%02d", left // 60, left % 60)
  if st.phase == "focus" or st.phase == "break" then mins = tostring((left + 59) // 60) end
  bigCentered(mins, 42, #mins <= 2 and 10 or 6)
  local total = ((st.phase == "break" or st.phase == "pausedbreak") and b or f) * 60
  local done = 1 - left / total
  unidex.rect(20, 124, 160, 12)
  unidex.fill(22, 126, math.floor(156 * done), 8)
  local sub = (st.phase == "focus" or st.phase == "break") and "minutes left" or (f .. " min focus, " .. b .. " min break")
  unidex.centered(152, sub, "tiny")
  shown = left // 60
  if st.phase == "focus" or st.phase == "break" then unidex.wake_in((left % 60 + 1) * 1000) end
  local hints = { idle = { "length", "start" }, focus = { "", "pause" }, paused = { "", "resume" },
                  ["break"] = { "", "pause" }, pausedbreak = { "", "resume" } }
  local h = hints[st.phase] or { "", "" }
  unidex.hints(h[1], h[2], st.phase ~= "idle" and "stop" or "")
end

function tick()
  if st.phase ~= "focus" and st.phase ~= "break" then return end
  local n = now()
  if n >= st.ends or remaining(n) // 60 ~= shown then return "partial" end
end

function onA()
  if st.phase == "idle" then st.len = st.len % #LENGTHS + 1; save(); return "partial" end
end

function onB()
  local n = now()
  local f, b = LENGTHS[st.len][1], LENGTHS[st.len][2]
  if st.phase == "idle" then st.phase, st.ends = "focus", n + f * 60
  elseif st.phase == "focusdone" then st.phase, st.ends = "break", n + b * 60
  elseif st.phase == "focus" then st.phase, st.left = "paused", st.ends - n
  elseif st.phase == "break" then st.phase, st.left = "pausedbreak", st.ends - n
  elseif st.phase == "paused" then st.phase, st.ends = "focus", n + st.left
  elseif st.phase == "pausedbreak" then st.phase, st.ends = "break", n + st.left end
  save()
  return "full"
end

function onBHold()
  if st.phase ~= "idle" then st.phase = "idle"; save(); unidex.toast("Stopped"); return "full" end
end
