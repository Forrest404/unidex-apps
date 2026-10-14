-- Magic 8-Ball: ask it something, press B, get an answer. Hold B for another set of answers.
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

local SETS = {
  { name = "Classic", answers = {
    "Yes", "Without a doubt", "Count on it", "Most likely", "The signs say yes", "Looks good",
    "Ask again later", "Hard to say", "Not right now", "Try again", "Can't tell yet",
    "No", "Very doubtful", "Don't count on it", "Unlikely", "The signs say no" } },
  { name = "Yes or no", answers = { "Yes", "No", "Yes!", "Nope", "Definitely", "No way", "Maybe", "Probably" } },
  { name = "Silly", answers = {
    "Ask a cat", "After a snack", "The pigeons say yes", "Only on Tuesdays", "In your dreams",
    "Absolutely, sort of", "The fridge knows", "Flip a coin", "Not before coffee", "Yes, but quietly",
    "Ask me tomorrow", "It is written in crumbs" } },
}

local set = tonumber(unidex.data.read("set") or "1") or 1
if not SETS[set] then set = 1 end
local answer, last

-- Splits text into lines no wider than w in the given font.
local function lines(text, w, font)
  local out, line = {}, ""
  for word in text:gmatch("%S+") do
    local try = line == "" and word or (line .. " " .. word)
    if unidex.width(try, font) <= w or line == "" then line = try else out[#out + 1] = line; line = word end
  end
  if line ~= "" then out[#out + 1] = line end
  return out
end

function draw()
  unidex.header("Magic 8-Ball", SETS[set].name)
  disc(100, 93, 62)
  if not answer then
    disc(100, 93, 26, "white")
    unidex.centered(106, "8", "large")
    unidex.hints("", "shake", "answers")
    return
  end
  -- The window: a round hole in the ball, with the answer floating in it
  disc(100, 93, 44, "white")
  local font, ls = "bold", lines(answer, 72, "bold")
  if #ls > 3 then font, ls = "small", lines(answer, 72, "small") end
  local step = 17
  local top = 93 - (#ls * step) // 2 + 12
  for i, l in ipairs(ls) do unidex.centered(top + (i - 1) * step, l, font) end
  unidex.hints("", "again", "answers")
end

function onB()
  local list = SETS[set].answers
  repeat answer = list[unidex.random(#list)] until answer ~= last or #list < 2
  last = answer
  return "full"
end

function onBHold()
  set = set % #SETS + 1
  unidex.data.write("set", tostring(set))
  answer = nil
  unidex.toast(SETS[set].name .. " answers")
  return "partial"
end
