-- Dex: collect the WiFi networks around you. B looks (a few seconds), A shows every find, hold B the rarity
-- counts (hold B there to clear). One find per network name; hidden networks are left out. Only a network's name,
-- signal, security and the day it was found are kept: never its address.
local RARITY = { "common", "uncommon", "starter", "rare" }  -- worst to best
local RANK = { common = 1, uncommon = 2, starter = 3, rare = 4 }
local MAX, PER_FILE, PAGE = 2000, 500, 5  -- finds-1.csv ... finds-4.csv: one file has to stay under 64 KB

local names, ranks, known, counts = {}, {}, {}, { 0, 0, 0, 0 }
local view, page = "main", 0
local looking, result = false, nil  -- result: what the last scan found (new, nearby, best)

-- Commas would break the file, and the font is ASCII only.
local function clean(s) return (s:gsub(",", " "):gsub("[^\32-\126]", "?")) end

-- First match wins: eduroam is the starter; a faint signal is rare; open is common.
local function rarityOf(name, rssi, security)
  if name == "eduroam" then return 3 end
  if rssi < -80 then return 4 end
  if security == "open" then return 1 end
  return 2
end

local function remember(name, rank)
  names[#names + 1], ranks[#ranks + 1], known[name] = name, rank, true
  counts[rank] = counts[rank] + 1
end

-- Rows: name,rssi,security,rarity,date
for f = 1, MAX // PER_FILE do
  local text = unidex.data.read("finds-" .. f .. ".csv")
  if not text then break end
  for line in text:gmatch("[^\n]+") do
    local name, rarity = line:match("^([^,]+),[^,]*,[^,]*,([^,]*)")
    if name and RANK[rarity] and not known[name] then remember(name, RANK[rarity]) end
  end
end

-- Cut to fit `w` pixels, ending in "..." if it had to be cut.
local function fit(s, w, font)
  if unidex.width(s, font) <= w then return s end
  while #s > 0 and unidex.width(s .. "...", font) > w do s = s:sub(1, -2) end
  return s .. "..."
end

local function scan()
  local nets, why = unidex.wifi.scan()
  if not nets then
    unidex.toast(why)
    return
  end
  local seen, nearby, found = {}, 0, {}
  for _, n in ipairs(nets) do
    local name = clean(n.ssid)
    if not seen[name] then
      seen[name], nearby = true, nearby + 1
      if not known[name] and #names + #found < MAX then
        found[#found + 1] = { name = name, rssi = n.rssi, security = n.security,
                              rank = rarityOf(name, n.rssi, n.security) }
      end
    end
  end
  local t = unidex.time()
  local date = t.valid and string.format("%04d-%02d-%02d", t.year, t.month, t.day) or ""
  -- New rows go on the end of the file they belong in (500 a file).
  local rows, best = {}, nil
  for i, n in ipairs(found) do
    local file = (#names + i - 1) // PER_FILE + 1
    rows[file] = (rows[file] or "") .. string.format("%s,%d,%s,%s,%s\n", n.name, n.rssi, n.security,
                                                     RARITY[n.rank], date)
  end
  for file, text in pairs(rows) do
    if not unidex.data.append("finds-" .. file .. ".csv", text) then
      unidex.toast("Card full: not saved")
      return
    end
  end
  for _, n in ipairs(found) do
    remember(n.name, n.rank)
    if not best or n.rank > best.rank then best = n end
  end
  result = { new = #found, nearby = nearby, best = best }
  if #names >= MAX then unidex.toast("The Dex is full") end
end

local function drawEmpty(headline, line1, line2)
  unidex.centered(80, headline, "bold")  -- (centered takes the baseline)
  unidex.centered(104, line1)
  unidex.centered(124, line2)
end

local function drawMain()
  unidex.header("Dex")
  if looking then
    drawEmpty("Looking for networks", "a few seconds...", "")
    unidex.hints("", "", "")
    return
  end
  if #names == 0 then
    drawEmpty("No networks yet", "Press B to look for", "WiFi networks nearby")
  elseif result and result.new > 0 then
    unidex.fill(74, 34, 52, 20)  -- a small NEW! tag over the best new find
    unidex.centered(49, "NEW!", "small", "white")
    local name = result.best.name
    if unidex.width(name, "large") <= 184 then unidex.centered(95, name, "large")
    else unidex.centered(90, fit(name, 184)) end
    local line = string.format("%s, %d new of %d", RARITY[result.best.rank], result.new, result.nearby)
    unidex.centered(121, fit(line:sub(1, 1):upper() .. line:sub(2), 184))  -- "Rare, 3 new of 12"
  elseif result then
    drawEmpty("Nothing new here", result.nearby == 1 and "1 network nearby," or result.nearby .. " networks nearby,",
              "all found before")
  else
    unidex.centered(95, tostring(#names), "large")
    unidex.centered(119, #names == 1 and "network found" or "networks found")
  end
  unidex.hints("list", "scan", "rarity")
end

-- Every find, newest first, five a page.
local function drawList()
  unidex.header("All finds")
  if #names == 0 then drawEmpty("Nothing yet", "Go back and scan", "to find networks") end
  for i = 0, PAGE - 1 do
    local at = #names - page * PAGE - i
    if at < 1 then break end
    local y, rarity = 46 + i * 26, RARITY[ranks[at]]
    local w = unidex.width(rarity, "tiny")
    unidex.text(192 - w, y, rarity, "tiny")
    unidex.text(8, y, fit(names[at], 184 - w - 6))
  end
  unidex.hints(#names > PAGE and "more" or "", "", "")
end

local function drawCounts()
  unidex.header("Rarity")
  for i, rank in ipairs({ 4, 3, 2, 1 }) do
    local y, n = 24 + i * 30, tostring(counts[rank])
    unidex.text(8, y, RARITY[rank])
    unidex.text(192 - unidex.width(n), y, n)
  end
end

local function drawConfirm()
  drawCounts()
  unidex.fill(8, 38, 184, 115, "white")  -- the question on a sheet over the counts
  unidex.rect(8, 38, 184, 115)
  unidex.rect(9, 39, 182, 113)
  unidex.centered(79, "Clear the Dex?", "bold")
  unidex.centered(106, #names == 1 and "Your 1 find goes." or "All " .. #names .. " finds go.")
  unidex.centered(128, "Can't be undone.")
  unidex.hints("keep", "clear", "")
end

function draw()
  if view == "list" then drawList()
  elseif view == "counts" then
    drawCounts()
    unidex.hints("", "", #names > 0 and "clear" or "")
  elseif view == "confirm" then drawConfirm()
  else drawMain() end
end

function onA()
  if view == "main" then
    view, page = "list", 0
  elseif view == "list" and #names > PAGE then
    page = (page + 1) % ((#names + PAGE - 1) // PAGE)
  elseif view == "confirm" then
    view = "counts"
  else
    return
  end
  return "partial"
end

function onB()
  if view == "main" and not looking then
    looking = true  -- "Looking for networks" first; the scan runs in the next tick
    unidex.wake_in(1000)
    return "partial"
  elseif view == "confirm" then
    for f = 1, MAX // PER_FILE do unidex.data.remove("finds-" .. f .. ".csv") end
    names, ranks, known, counts, result = {}, {}, {}, { 0, 0, 0, 0 }, nil
    unidex.toast("Dex cleared")
    view = "main"
    return "partial"
  end
end

function onBHold()
  if view == "main" then view = "counts"
  elseif view == "counts" and #names > 0 then view = "confirm"
  else return end
  return "partial"
end

function onBack()
  if view == "main" then return "exit" end
  view = view == "confirm" and "counts" or "main"
  return "partial"
end

function tick()
  if not looking then return end
  scan()
  looking = false
  return "partial"
end
