-- Quote of the Day: B fetches today's quote from ZenQuotes over WiFi (once a day). Until then, and offline, it shows
-- a proverb of the day from its own list.
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

local PROVERBS = {
  { "Little by little, one travels far.", "Spanish proverb" },
  { "Fall seven times, stand up eight.", "Japanese proverb" },
  { "Many hands make light work.", "English proverb" },
  { "The best time to plant a tree was twenty years ago. The second best time is now.", "Proverb" },
  { "A smooth sea never made a skilled sailor.", "English proverb" },
  { "When the wind blows, some build walls and others build windmills.", "Chinese proverb" },
  { "Slow and steady wins the race.", "Proverb" },
  { "If you want to go fast, go alone. If you want to go far, go together.", "African proverb" },
  { "Every day is a school day.", "English saying" },
  { "Rome wasn't built in a day.", "Proverb" },
  { "A journey of a thousand miles begins with a single step.", "Chinese proverb" },
  { "Don't count your chickens before they hatch.", "Proverb" },
  { "Better late than never.", "Proverb" },
  { "Practice makes perfect.", "Proverb" },
  { "Where there's a will, there's a way.", "Proverb" },
  { "The early bird catches the worm.", "Proverb" },
  { "Actions speak louder than words.", "Proverb" },
  { "Two heads are better than one.", "Proverb" },
  { "Every cloud has a silver lining.", "Proverb" },
  { "A watched pot never boils.", "Proverb" },
  { "Still waters run deep.", "Proverb" },
  { "You can't pour from an empty cup.", "Saying" },
  { "Even a small star shines in the darkness.", "Finnish proverb" },
  { "After the rain comes the sun.", "Proverb" },
  { "Don't put all your eggs in one basket.", "Proverb" },
  { "Time and tide wait for no one.", "Proverb" },
  { "Small strokes fell great oaks.", "Proverb" },
  { "Learning is a treasure that follows its owner everywhere.", "Chinese proverb" },
  { "The pen is mightier than the sword.", "Saying" },
  { "Tomorrow is a new day.", "Saying" },
}

local saved = unidex.data.read("quote") or ""
local qday, qtext, qwho = saved:match("^(%d+)\n(.-)\n(.*)$")
qday = tonumber(qday)

-- JSON text to plain ASCII the screen's font can show
local function plain(s)
  s = s:gsub('\\"', '"'):gsub("\\/", "/"):gsub("\\n", " ")
  s = s:gsub("\\u(%x%x%x%x)", function(h)
    local c = tonumber(h, 16)
    if c == 0x2018 or c == 0x2019 then return "'" end
    if c == 0x201C or c == 0x201D then return '"' end
    if c == 0x2013 or c == 0x2014 then return "-" end
    if c == 0x2026 then return "..." end
    if c < 128 then return string.char(c) end
    return ""
  end)
  s = s:gsub("\\\\", "\\")
  return (s:gsub("[\128-\255]", ""))
end

local function lines(text, w, font)
  local out, line = {}, ""
  for word in text:gmatch("%S+") do
    local try = line == "" and word or (line .. " " .. word)
    if unidex.width(try, font) <= w or line == "" then line = try else out[#out + 1] = line; line = word end
  end
  if line ~= "" then out[#out + 1] = line end
  return out
end

local SIZES = { { "medium", 3, 26 }, { "small", 5, 20 }, { "tiny", 7, 15 } }

function draw()
  local dn, t = today()
  local text, who, fetched = nil, nil, false
  if qday and qday == dn then text, who, fetched = qtext, qwho, true
  else local p = PROVERBS[dn % #PROVERBS + 1]; text, who = p[1], p[2] end
  unidex.header(fetched and "Quote" or "Proverb", t.valid and string.format("%d %s", t.day, MONTHS[t.month]) or nil)
  local ls, font, step
  for _, s in ipairs(SIZES) do
    ls, font, step = lines('"' .. text .. '"', 176, s[1]), s[1], s[3]
    if #ls <= s[2] then break end
  end
  local block = #ls * step + 22
  local top = 26 + math.max(8, (132 - block) // 2) + step - 6
  for i, l in ipairs(ls) do unidex.text(12, top + (i - 1) * step, l, font) end
  local who2 = "- " .. who
  unidex.text(188 - unidex.width(who2, "small"), top + (#ls - 1) * step + 24, who2, "small")
  if fetched then unidex.text(12, 158, "via zenquotes.io", "tiny") end
  unidex.hints("", fetched and "" or "today's quote", "")
end

function onB()
  local dn = today()
  if qday == dn then return end
  local status, body = unidex.http.get("https://zenquotes.io/api/today")
  if not status then unidex.toast("No connection"); return "partial" end
  local q, a = body:match('"q"%s*:%s*"(.-)"%s*,%s*"a"%s*:%s*"(.-)"')
  if status ~= 200 or not q then unidex.toast("Couldn't get a quote"); return "partial" end
  qday, qtext, qwho = dn, plain(q), plain(a)
  unidex.data.write("quote", string.format("%d\n%s\n%s", qday, qtext, qwho))
  return "full"
end
