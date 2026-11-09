-- Rii Mahjong Scoring for unidex
-- Written by mican8saku

-- Fu values ordered by real-game frequency
local FU_VALUES = {30, 40, 20, 25, 50, 60, 70, 80, 90, 100, 110}

local screen  = "menu"
local field   = 1
local player  = 1
local han     = 1
local fu      = 30
local kiriage = false

-- ---------- drawing helpers ----------

local function right_text(x_right, y, text, font, colour)
  unidex.text(x_right - unidex.width(text, font), y, text, font, colour)
end

local function draw_tile(x, y, w, h, pips)
  -- Outer frame (tile edge)
  unidex.rect(x, y, w, h)
  -- Inner frame (tile face)
  unidex.rect(x + 2, y + 2, w - 4, h - 4)
  
  local cx = x + math.floor(w / 2)
  local cy = y + math.floor(h / 2)
  
  if pips == 1 then
    unidex.fill(cx - 4, cy - 4, 8, 8)
  elseif pips == 2 then
    -- 2-pin: two dots, vertical
    unidex.fill(cx - 4, cy - 15, 8, 8)
    unidex.fill(cx - 4, cy + 7, 8, 8)
  elseif pips == 3 then
    -- 3-pin: three dots, diagonal (smaller and spaced out)
    unidex.fill(cx - 12, cy - 13, 6, 6)
    unidex.fill(cx - 3, cy - 3, 6, 6)
    unidex.fill(cx + 6, cy + 7, 6, 6)
  end
end

-- ---------- scoring ----------

local function round100(x)
  return math.ceil(x / 100 - 1e-9) * 100
end

-- 20 fu is only ever pinfu tsumo (a pinfu ron is 30 fu), and 25 fu is chiitoitsu (2 han or more)
local function ron_exists(h, f)
  return f ~= 20 and not (h == 1 and f == 25)
end

-- Tsumo can't be 1 han 20 fu (pinfu tsumo is 2 han), 2 han 25 fu (chiitoitsu tsumo is 3 han),
-- or 1 han 110 fu (as the score tables show it)
local function tsumo_exists(h, f)
  if h == 1 and (f == 20 or f == 25 or f == 110) then return false end
  return not (h == 2 and f == 25)
end

local function is_kiriage_hand(h, f)
  return kiriage and ((h == 4 and f == 30) or (h == 3 and f == 60))
end

local function cycle_fu(dir)
  for i, f in ipairs(FU_VALUES) do
    if f == fu then
      local idx = i + dir
      if idx < 1 then idx = #FU_VALUES end
      if idx > #FU_VALUES then idx = 1 end
      fu = FU_VALUES[idx]
      return
    end
  end
  fu = FU_VALUES[1]
end

local function compute(h, f, p)
  local base
  if h >= 5 then
    -- Limit hands: base value determined entirely by han
    if h == 5 then base = 2000
    elseif h == 6 or h == 7 then base = 3000
    elseif h == 8 or h == 9 or h == 10 then base = 4000
    elseif h == 11 or h == 12 then base = 6000
    else base = 8000 end -- h >= 13 (Kazoe Yakuman)
  else
    -- Normal hands (1-4 han)
    if is_kiriage_hand(h, f) then
      base = 2000
    else
      base = f * (2 ^ (2 + h))
      if base >= 2000 then base = 2000 end
    end
  end
  
  local ron, tn, td
  if p == 2 then
    ron = round100(base * 6)
    tn  = round100(base * 2)
    td  = tn
  else
    ron = round100(base * 4)
    tn  = round100(base)
    td  = round100(base * 2)
  end
  return ron, tn, td
end

-- ---------- screens ----------

local function draw_menu()
  unidex.header("Rii Mahjong Scoring", "")
  
  -- Draw three tiles: 1-pin, 2-pin, 3-pin
  local tw, th = 40, 54
  local gap = 2
  local total_w = (tw * 3) + (gap * 2)
  local start_x = math.floor((200 - total_w) / 2)
  local start_y = 42
  
  draw_tile(start_x, start_y, tw, th, 1)
  draw_tile(start_x + tw + gap, start_y, tw, th, 2)
  draw_tile(start_x + tw + gap + tw + gap, start_y, tw, th, 3)

  -- Kiriage toggle box
  local label = "Kiriage: " .. (kiriage and "ON" or "OFF")
  local w = unidex.width(label, "small") + 20
  local x = math.floor((200 - w) / 2)
  if kiriage then
    unidex.fill(x, 116, w, 26)
    unidex.centered(133, label, "small", "white")
  else
    unidex.rect(x, 116, w, 26)
    unidex.centered(133, label, "small")
  end

  unidex.hints("start", "toggle", "")
end

local function draw_input()
  unidex.header("Input", field .. "/3")

  local labels = {"Player", "Han", "Fu"}
  local han_str = (han == 13) and "13+ han" or (han .. " han")
  
  local values = {
    player == 2 and "Dealer" or "Non-dealer",
    han_str,
    fu  .. " fu",
  }

  for i = 1, 3 do
    local y = 62 + (i - 1) * 38
    if i == field then
      unidex.fill(8, y - 16, 184, 26)
      unidex.text(12, y, labels[i], "small", "white")
      right_text(188, y, values[i], "small", "white")
    else
      unidex.text(12, y, labels[i], "small")
      right_text(188, y, values[i], "small")
    end
  end

  unidex.hints("next", "cycle", "back")
end

local function draw_result()
  unidex.header("Result", player == 2 and "Dealer" or "Non-dealer")

  local ron_ok   = ron_exists(han, fu)
  local tsumo_ok = tsumo_exists(han, fu)
  local ron, tn, td = compute(han, fu, player)

  local han_str = (han == 13) and "13+" or tostring(han)
  unidex.centered(46, han_str .. " han  " .. fu .. " fu", "small")

  -- Big Ron value (or "-" if hand doesn't exist)
  unidex.centered(86, ron_ok and tostring(ron) or "-", "large")
  unidex.centered(102, "ron", "small")

  -- Tsumo value (or "-" if tsumo doesn't exist)
  if not tsumo_ok then
    unidex.centered(132, "-", "medium")
  elseif player == 2 then
    unidex.centered(132, tn .. " ALL", "medium")
  else
    unidex.centered(132, tn .. " / " .. td, "medium")
  end
  unidex.centered(148, "tsumo", "small")

  unidex.hints("", "new", "")
end

function draw()
  if     screen == "menu"  then draw_menu()
  elseif screen == "input" then draw_input()
  else                          draw_result()
  end
end

-- ---------- buttons ----------

function onA()
  if screen == "menu" then
    field  = 1
    screen = "input"
    return "full"
  elseif screen == "input" then
    if field < 3 then
      field = field + 1
      return "partial"
    end
    screen = "result"
    return "full"
  else
    -- Score screen: press A does nothing
    return nil
  end
end

function onB()
  if screen == "menu" then
    kiriage = not kiriage
    return "partial"
  elseif screen == "input" then
    if field == 1 then
      player = player % 2 + 1
    elseif field == 2 then
      han = han % 13 + 1
    else
      cycle_fu(1)
    end
    return "partial"
  else
    -- Score screen: back to input and reset values to defaults
    screen = "input"
    field  = 1
    player = 1
    han    = 1
    fu     = 30
    return "full"
  end
end

local function step_back()
  if field > 1 then
    field = field - 1
    return "partial"
  end
  screen = "menu"
  return "partial"
end

function onBHold()
  if screen == "input" then return step_back() end
  return nil
end

function onBack()
  if screen == "menu" then return "exit" end
  -- Input: hold A goes back, like hold B
  if screen == "input" then return step_back() end

  -- Score screen: hold A exits the app entirely, back to the OS homescreen
  return "exit"
end