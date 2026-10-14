-- Day of the Year: a badge plugin. Today's day number, the date, and how much of the year has gone.
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

function badge()
  local dn, t = today()
  unidex.rect(4, 4, 192, 192)
  unidex.rect(6, 6, 188, 188)
  if not t.valid then
    unidex.centered(96, "Clock not set", "bold")
    unidex.centered(120, "Settings > Date & time", "small")
    return
  end
  local first = dayNumber(t.year, 1, 1)
  local length = dayNumber(t.year + 1, 1, 1) - first
  local n = dn - first + 1
  unidex.centered(38, "DAY", "bold")
  bigCentered(tostring(n), 50, 10)
  unidex.centered(144, dateText(dn), "small")
  unidex.rect(20, 156, 160, 12)
  unidex.fill(22, 158, math.floor(156 * n / length + 0.5), 8)
  unidex.centered(186, string.format("%d%% of %d, %d days to go", math.floor(100 * n / length), t.year, length - n), "tiny")
end
