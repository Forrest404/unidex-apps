-- Flash Cards: three decks to learn from. B flips a card; then B if you knew it, A if not (it comes back later).
local DECKS = {
  { name = "European capitals", cards = {
    { "France", "Paris" }, { "Germany", "Berlin" }, { "Spain", "Madrid" }, { "Italy", "Rome" }, { "Portugal", "Lisbon" },
    { "Ireland", "Dublin" }, { "Netherlands", "Amsterdam" }, { "Belgium", "Brussels" }, { "Austria", "Vienna" },
    { "Switzerland", "Bern" }, { "Poland", "Warsaw" }, { "Czechia", "Prague" }, { "Hungary", "Budapest" },
    { "Greece", "Athens" }, { "Sweden", "Stockholm" }, { "Norway", "Oslo" }, { "Denmark", "Copenhagen" },
    { "Finland", "Helsinki" }, { "Iceland", "Reykjavik" }, { "Croatia", "Zagreb" }, { "Romania", "Bucharest" },
    { "Bulgaria", "Sofia" }, { "Slovakia", "Bratislava" }, { "Slovenia", "Ljubljana" }, { "Estonia", "Tallinn" },
    { "Latvia", "Riga" }, { "Lithuania", "Vilnius" }, { "Ukraine", "Kyiv" }, { "Serbia", "Belgrade" }, { "Malta", "Valletta" } } },
  { name = "Times tables", cards = {} },
  { name = "Chemical symbols", cards = {
    { "Hydrogen", "H" }, { "Helium", "He" }, { "Carbon", "C" }, { "Nitrogen", "N" }, { "Oxygen", "O" }, { "Sodium", "Na" },
    { "Magnesium", "Mg" }, { "Aluminium", "Al" }, { "Silicon", "Si" }, { "Phosphorus", "P" }, { "Sulfur", "S" },
    { "Chlorine", "Cl" }, { "Potassium", "K" }, { "Calcium", "Ca" }, { "Iron", "Fe" }, { "Copper", "Cu" }, { "Zinc", "Zn" },
    { "Silver", "Ag" }, { "Tin", "Sn" }, { "Gold", "Au" }, { "Mercury", "Hg" }, { "Lead", "Pb" }, { "Uranium", "U" },
    { "Neon", "Ne" }, { "Argon", "Ar" }, { "Nickel", "Ni" }, { "Platinum", "Pt" }, { "Iodine", "I" }, { "Lithium", "Li" },
    { "Titanium", "Ti" } } },
}
for a = 2, 12 do for b = 2, 12 do
  local c = DECKS[2].cards
  c[#c + 1] = { a .. " x " .. b, tostring(a * b) }
end end

local deck = tonumber(unidex.data.read("deck") or "1") or 1
if not DECKS[deck] then deck = 1 end
local best = {}
for i, v in (unidex.data.read("best") or ""):gmatch("(%d+)=(%d+)") do best[tonumber(i)] = tonumber(v) end
local queue, card, flipped, right, seen, round = nil, nil, false, 0, 0, 20

local function start()
  local all = DECKS[deck].cards
  local idx = {}
  for i = 1, #all do idx[i] = i end
  for i = #idx, 2, -1 do local j = unidex.random(i); idx[i], idx[j] = idx[j], idx[i] end
  queue = {}
  for i = 1, math.min(round, #idx) do queue[i] = all[idx[i]] end
  card, flipped, right, seen = table.remove(queue, 1), false, 0, 0
end

local function fit(text, w)
  for _, f in ipairs({ "large", "medium", "bold", "small" }) do
    if unidex.width(text, f) <= w then return f end
  end
  return "small"
end

function draw()
  if not queue then
    local d = DECKS[deck]
    unidex.header("Flash Cards", deck .. "/" .. #DECKS)
    unidex.rect(14, 34, 172, 104); unidex.rect(18, 38, 172, 104); unidex.fill(15, 35, 170, 102, "white")
    unidex.rect(14, 34, 172, 104)
    unidex.centered(80, d.name, fit(d.name, 160))
    unidex.centered(108, math.min(round, #d.cards) .. " cards, shuffled", "small")
    if best[deck] then unidex.centered(126, "Best: " .. best[deck] .. "/" .. math.min(round, #d.cards), "tiny") end
    unidex.hints("deck", "start", "")
    return
  end
  if not card then
    unidex.header("Flash Cards", "done")
    unidex.centered(78, right .. " / " .. seen, "large")
    unidex.centered(106, right == seen and "Perfect!" or "right first time", "small")
    unidex.hints("decks", "again", "")
    return
  end
  unidex.header(DECKS[deck].name, (#queue + 1) .. " left")
  unidex.rect(10, 32, 180, 120)
  local text = flipped and card[2] or card[1]
  unidex.centered(flipped and 82 or 98, text, fit(text, 168))
  if flipped then unidex.centered(116, card[1], "tiny") end
  if flipped then unidex.hints("missed", "got it", "") else unidex.hints("", "flip", "") end
end

function onB()
  if not queue then start(); return "full" end
  if not card then start(); return "full" end
  if not flipped then flipped = true; return "full" end
  right, seen = right + 1, seen + 1
  card, flipped = table.remove(queue, 1), false
  if not card then
    if not best[deck] or right > best[deck] then
      best[deck] = right
      local parts = {}
      for i, v in pairs(best) do parts[#parts + 1] = i .. "=" .. v end
      unidex.data.write("best", table.concat(parts, " "))
    end
  end
  return "full"
end

function onA()
  if not queue then deck = deck % #DECKS + 1; unidex.data.write("deck", tostring(deck)); return "partial" end
  if not card then queue = nil; return "full" end
  if flipped then  -- missed: it goes back in, a few cards later
    seen = seen + 1
    table.insert(queue, math.min(#queue + 1, 3), card)
    card, flipped = table.remove(queue, 1), false
    return "full"
  end
end

function onBack()
  if queue then queue = nil; return "full" end
  return "exit"
end
