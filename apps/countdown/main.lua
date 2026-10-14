-- Countdown: days to (or since) a date you choose. Hold B to set it; A switches between days and weeks.
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

local LABELS = { "Holidays", "Exams", "Birthday", "Trip", "Christmas", "Summer", "Party", "Deadline", "The big day" }
local DAYS_IN = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local saved = unidex.data.read("target") or ""
local label, ty, tm, td = saved:match("^(%d+) (%d+) (%d+) (%d+)$")
label, ty, tm, td = tonumber(label), tonumber(ty), tonumber(tm), tonumber(td)
local weeks = unidex.data.read("weeks") == "1"
local editing, field, draft = false, 1, nil

local function monthDays(y, m)
  if m == 2 and (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) then return 29 end
  return DAYS_IN[m]
end

local function ensureTarget(t)
  if ty then return end
  label, ty, tm, td = 5, t.year, 12, 25  -- until set: Christmas
  if dayNumber(ty, tm, td) < dayNumber(t.year, t.month, t.day) then ty = ty + 1 end
end

local function drawEditor(t)
  unidex.header("Set the countdown")
  local rows = {
    { "For", LABELS[draft.label] },
    { "Day", tostring(draft.d) },
    { "Month", MONTHS[draft.m] },
    { "Year", tostring(draft.y) },
  }
  for i, r in ipairs(rows) do
    local y = 32 + (i - 1) * 28
    if i == field then unidex.fill(4, y, 192, 26) end
    local colour = i == field and "white" or "black"
    unidex.text(12, y + 18, r[1], "small", colour)
    unidex.text(80, y + 18, r[2], "bold", colour)
  end
  unidex.centered(156, dateText(dayNumber(draft.y, draft.m, draft.d)), "tiny")
  unidex.hints("change", field < 4 and "next" or "save", "")
end

function draw()
  local today, t = today()
  if not t.valid then
    unidex.header("Countdown")
    unidex.centered(80, "Clock not set", "bold")
    unidex.centered(104, "Set it in Settings first", "small")
    unidex.hints("", "", "")
    return
  end
  ensureTarget(t)
  if editing then return drawEditor(t) end
  local target = dayNumber(ty, tm, td)
  local n = target - today
  unidex.header("Countdown", LABELS[label])
  if n == 0 then
    unidex.centered(92, "Today!", "large")
    unidex.centered(120, "It's here", "small")
  else
    local count = math.abs(n)
    local big1, sub
    if weeks and count >= 7 then
      big1 = tostring(count // 7)
      sub = string.format("week%s %s%s", count // 7 == 1 and "" or "s",
        count % 7 > 0 and string.format("and %d day%s ", count % 7, count % 7 == 1 and "" or "s") or "", n > 0 and "to go" or "ago")
    else
      big1 = tostring(count)
      sub = string.format("day%s %s", count == 1 and "" or "s", n > 0 and "to go" or "ago")
    end
    local k = #big1 <= 3 and 9 or 7
    bigCentered(big1, 40, k)
    unidex.centered(40 + 7 * k + 22, sub, "small")
  end
  unidex.centered(154, dateText(target), "tiny")
  unidex.hints(weeks and "days" or "weeks", "", "set date")
end

function onA()
  if editing then
    if field == 1 then draft.label = draft.label % #LABELS + 1
    elseif field == 2 then draft.d = draft.d % monthDays(draft.y, draft.m) + 1
    elseif field == 3 then draft.m = draft.m % 12 + 1; draft.d = math.min(draft.d, monthDays(draft.y, draft.m))
    else
      local now = unidex.time().year
      draft.y = draft.y + 1
      if draft.y > now + 10 then draft.y = now - 1 end
      draft.d = math.min(draft.d, monthDays(draft.y, draft.m))
    end
    return "partial"
  end
  weeks = not weeks
  unidex.data.write("weeks", weeks and "1" or "0")
  return "partial"
end

function onB()
  if not editing then return end
  if field < 4 then field = field + 1; return "partial" end
  label, ty, tm, td = draft.label, draft.y, draft.m, draft.d
  unidex.data.write("target", string.format("%d %d %d %d", label, ty, tm, td))
  editing = false
  unidex.toast("Saved")
  return "full"
end

function onBHold()
  if editing or not unidex.time().valid then return end
  ensureTarget(unidex.time())
  draft = { label = label, y = ty, m = tm, d = td }
  editing, field = true, 1
  return "full"
end

function onBack()
  if editing then editing = false; return "full" end
  return "exit"
end
