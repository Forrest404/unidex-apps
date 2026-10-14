-- Word of the Day: a new word every day, with what it means. A looks back at the last few days.
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

local WORDS = {
  { "serendipity", "noun", "Finding something good without looking for it." },
  { "ephemeral", "adjective", "Lasting a very short time." },
  { "petrichor", "noun", "The smell of rain on dry ground." },
  { "sonder", "noun", "Realising that every passer-by has a life as full as yours." },
  { "mellifluous", "adjective", "Sweet and smooth to hear." },
  { "quixotic", "adjective", "Hopeful and idealistic, but not very practical." },
  { "luminous", "adjective", "Giving off light; bright or glowing." },
  { "ineffable", "adjective", "Too great to be put into words." },
  { "halcyon", "adjective", "Calm, happy and peaceful, often of the past." },
  { "sanguine", "adjective", "Cheerful and confident, even when things look bad." },
  { "ebullient", "adjective", "Full of energy and excitement." },
  { "laconic", "adjective", "Using very few words." },
  { "gregarious", "adjective", "Fond of company; sociable." },
  { "ubiquitous", "adjective", "Seeming to be everywhere at once." },
  { "candour", "noun", "Being open and honest." },
  { "resilient", "adjective", "Able to recover quickly from difficulty." },
  { "wanderlust", "noun", "A strong wish to travel." },
  { "nostalgia", "noun", "A fond longing for the past." },
  { "eloquent", "adjective", "Speaking or writing clearly and movingly." },
  { "tenacious", "adjective", "Holding on firmly; not giving up." },
  { "whimsical", "adjective", "Playful and a little unusual." },
  { "zenith", "noun", "The highest point of something." },
  { "nadir", "noun", "The lowest point of something." },
  { "benevolent", "adjective", "Kind and wanting to do good." },
  { "cacophony", "noun", "A harsh mix of loud sounds." },
  { "euphoria", "noun", "A feeling of intense happiness." },
  { "frugal", "adjective", "Careful not to waste money or food." },
  { "hiatus", "noun", "A pause or break in something." },
  { "idyllic", "adjective", "Peaceful and perfect, like a picture." },
  { "jubilant", "adjective", "Joyful because of a success." },
  { "kinetic", "adjective", "To do with movement." },
  { "labyrinth", "noun", "A maze; something very complicated." },
  { "meander", "verb", "To wander slowly, without a fixed route." },
  { "nebulous", "adjective", "Vague and hard to pin down." },
  { "oblivious", "adjective", "Not aware of what is happening around you." },
  { "panacea", "noun", "A cure for every problem." },
  { "quintessential", "adjective", "The perfect example of its kind." },
  { "reverie", "noun", "A pleasant daydream." },
  { "solace", "noun", "Comfort in a sad time." },
  { "tranquil", "adjective", "Calm and quiet." },
  { "umbrage", "noun", "A feeling of offence." },
  { "vivacious", "adjective", "Lively and full of spirit." },
  { "wistful", "adjective", "Gently sad and longing for something." },
  { "zealous", "adjective", "Full of eager enthusiasm." },
  { "aplomb", "noun", "Calm confidence under pressure." },
  { "bucolic", "adjective", "To do with pleasant country life." },
  { "cogent", "adjective", "Clear, logical and convincing." },
  { "debonair", "adjective", "Confident, stylish and charming." },
  { "effervescent", "adjective", "Bubbly; lively and enthusiastic." },
  { "fastidious", "adjective", "Very careful about detail and tidiness." },
  { "garrulous", "adjective", "Talking a lot, often about small things." },
  { "hubris", "noun", "Too much pride or self-confidence." },
  { "insouciant", "adjective", "Relaxed and carefree." },
  { "juxtapose", "verb", "To place side by side to compare." },
  { "kerfuffle", "noun", "A fuss or commotion." },
  { "lethargic", "adjective", "Sleepy and slow, without energy." },
  { "magnanimous", "adjective", "Generous and forgiving, especially to a rival." },
  { "nonchalant", "adjective", "Calm and unbothered." },
  { "obfuscate", "verb", "To make something unclear on purpose." },
  { "paradigm", "noun", "A typical model or way of thinking." },
  { "quandary", "noun", "A state of not knowing what to do." },
  { "raconteur", "noun", "Someone who tells stories well." },
  { "sycophant", "noun", "Someone who flatters to get ahead." },
  { "taciturn", "adjective", "Quiet and saying little." },
  { "unfathomable", "adjective", "Impossible to understand fully." },
  { "verbose", "adjective", "Using more words than needed." },
  { "wherewithal", "noun", "The means or skill to do something." },
  { "yearn", "verb", "To long for something deeply." },
  { "acquiesce", "verb", "To accept something without protest." },
  { "belligerent", "adjective", "Ready to argue or fight." },
  { "capricious", "adjective", "Changing mood or mind suddenly." },
  { "diligent", "adjective", "Careful and hard-working." },
  { "enigma", "noun", "A mystery or puzzle." },
  { "facetious", "adjective", "Joking at the wrong moment." },
  { "gumption", "noun", "Common sense and initiative." },
  { "hapless", "adjective", "Unlucky." },
  { "impeccable", "adjective", "Without any faults." },
  { "jovial", "adjective", "Cheerful and friendly." },
  { "knack", "noun", "A natural skill at something." },
  { "lucid", "adjective", "Clear and easy to understand." },
  { "mirth", "noun", "Laughter and amusement." },
  { "novice", "noun", "A beginner." },
  { "opulent", "adjective", "Rich and luxurious." },
  { "pensive", "adjective", "Deep in thought." },
  { "quell", "verb", "To calm or put an end to." },
  { "rambunctious", "adjective", "Noisy, lively and hard to control." },
  { "serene", "adjective", "Calm and untroubled." },
  { "trepidation", "noun", "Nervousness about what might happen." },
  { "unwieldy", "adjective", "Awkward to carry or manage." },
  { "vestige", "noun", "A small trace of something that is gone." },
  { "wry", "adjective", "Dry and gently mocking." },
  { "zest", "noun", "Great enthusiasm; also the outer peel of a citrus fruit." },
  { "ambivalent", "adjective", "Having mixed feelings." },
  { "brevity", "noun", "Using few words; shortness." },
  { "conundrum", "noun", "A confusing problem." },
  { "dapper", "adjective", "Neat and smartly dressed." },
  { "epiphany", "noun", "A sudden moment of understanding." },
  { "flummox", "verb", "To confuse completely." },
  { "glimmer", "noun", "A faint, wavering light; a small sign of hope." },
  { "hullabaloo", "noun", "A noisy fuss." },
  { "inkling", "noun", "A slight suspicion or hint." },
  { "jocular", "adjective", "Fond of joking." }
}

local back = 0  -- days back from today

local function wordFor(dn)
  -- Every word once before any repeats: step through the list by a number that shares no factor with its length
  local function gcd(a, b) while b > 0 do a, b = b, a % b end return a end
  local n, step = #WORDS, 37
  while gcd(n, step) ~= 1 do step = step + 2 end
  return WORDS[(dn * step) % n + 1]
end

local function fit(text, w)
  for _, f in ipairs({ "large", "medium", "bold" }) do
    if unidex.width(text, f) <= w then return f end
  end
  return "small"
end

function draw()
  local dn, t = today()
  if not t.valid then dn = 0 end
  local day = dn - back
  local w = wordFor(day)
  local y, m, d = fromDayNumber(day)
  unidex.header(back == 0 and "Today's word" or (back == 1 and "Yesterday" or (back .. " days ago")),
    t.valid and string.format("%d %s", d, MONTHS[m]) or nil)
  unidex.centered(60, w[1], fit(w[1], 184))
  unidex.centered(80, w[2], "tiny")
  unidex.line(70, 88, 130, 88)
  unidex.wrap(12, 110, 176, w[3], 3, "small")
  unidex.hints(back < 6 and "earlier" or "", back > 0 and "today" or "", "")
end

function onA()
  if back < 6 then back = back + 1; return "partial" end
end

function onB()
  if back > 0 then back = 0; return "partial" end
end
