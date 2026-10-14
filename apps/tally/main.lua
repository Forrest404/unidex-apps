-- Tally: up to four counters. B adds one, A moves to the next, hold B for take one off, reset, rename and more.
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

local NAMES = { "Coffee", "Water", "Push-ups", "Squats", "Laps", "Pages", "Snacks", "Steps", "Goals", "Points",
                "Cups of tea", "Bugs fixed" }
local counters, at = {}, 1
for name, n in (unidex.data.read("counters") or ""):gmatch("([^|;]+)|(%d+)") do counters[#counters + 1] = { name = name, n = tonumber(n) } end
if #counters == 0 then counters = { { name = "Coffee", n = 0 } } end
at = math.min(tonumber(unidex.data.read("at") or "1") or 1, #counters)
local menu, sel, naming = nil, 1, false

local function save()
  local parts = {}
  for _, c in ipairs(counters) do parts[#parts + 1] = c.name .. "|" .. c.n end
  unidex.data.write("counters", table.concat(parts, ";"))
  unidex.data.write("at", tostring(at))
end

local function options()
  local o = { "Take one off", "Reset to zero", "Rename" }
  if #counters < 4 then o[#o + 1] = "Add a counter" end
  if #counters > 1 then o[#o + 1] = "Remove this counter" end
  o[#o + 1] = "Done"
  return o
end

local function drawMenu(title, items)
  unidex.header(title)
  local first = math.max(1, sel - 4)
  for i = first, math.min(#items, first + 4) do
    local y = 28 + (i - first) * 26
    if i == sel then unidex.fill(4, y, 192, 24) end
    unidex.text(12, y + 17, items[i], "small", i == sel and "white" or "black")
  end
  unidex.hints("next", "choose", "")
end

function draw()
  if naming then return drawMenu("Rename to", NAMES) end
  if menu then return drawMenu(counters[at].name, menu) end
  local c = counters[at]
  unidex.header("Tally", #counters > 1 and (at .. "/" .. #counters) or nil)
  unidex.centered(52, c.name, "medium")
  local s = tostring(c.n)
  bigCentered(s, 66, #s <= 3 and 9 or (#s == 4 and 7 or 5))
  if #counters > 1 then
    local others = {}
    for i, o in ipairs(counters) do if i ~= at then others[#others + 1] = o.name .. " " .. o.n end end
    unidex.centered(154, table.concat(others, "   "), "tiny")
  end
  unidex.hints(#counters > 1 and "next" or "", "+1", "options")
end

function onA()
  if naming or menu then
    local n = naming and #NAMES or #menu
    sel = sel % n + 1
    return "partial"
  end
  if #counters > 1 then at = at % #counters + 1; save(); return "partial" end
end

function onB()
  if naming then
    counters[at].name = NAMES[sel]; naming = false; save()
    return "full"
  end
  if menu then
    local choice = menu[sel]
    menu = nil
    local c = counters[at]
    if choice == "Take one off" then c.n = math.max(0, c.n - 1)
    elseif choice == "Reset to zero" then c.n = 0; unidex.toast(c.name .. " reset")
    elseif choice == "Rename" then naming, sel = true, 1; return "full"
    elseif choice == "Add a counter" then
      local used = {}
      for _, o in ipairs(counters) do used[o.name] = true end
      local name = "Count"
      for _, n in ipairs(NAMES) do if not used[n] then name = n; break end end
      counters[#counters + 1] = { name = name, n = 0 }; at = #counters
    elseif choice == "Remove this counter" then table.remove(counters, at); at = math.min(at, #counters) end
    save()
    return "full"
  end
  counters[at].n = counters[at].n + 1
  save()
  return "partial"
end

function onBHold()
  if naming or menu then return end
  menu, sel = options(), 1
  return "full"
end

function onBack()
  if naming or menu then naming, menu = false, nil; return "full" end
  return "exit"
end
