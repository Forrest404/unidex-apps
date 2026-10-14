-- Coin & RPS: flip a coin, or play rock-paper-scissors against your unidex. Hold B switches game.
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

local game = unidex.data.read("game") == "rps" and "rps" or "coin"
local score = { heads = 0, tails = 0, you = 0, me = 0 }
for k, v in (unidex.data.read("score") or ""):gmatch("(%a+)=(%d+)") do score[k] = tonumber(v) end
local MOVES = { "Rock", "Paper", "Scissors" }
local pick, coin, mine, result = 1, nil, nil, nil

local function save()
  unidex.data.write("score", string.format("heads=%d tails=%d you=%d me=%d", score.heads, score.tails, score.you, score.me))
end

local function drawMove(move, cx, cy)
  if move == 1 then  -- a rock: a lumpy filled shape
    disc(cx, cy + 2, 18); disc(cx - 10, cy + 6, 12); disc(cx + 11, cy + 5, 13)
  elseif move == 2 then  -- a sheet of paper with lines
    unidex.rect(cx - 16, cy - 20, 32, 42); unidex.rect(cx - 15, cy - 19, 30, 40)
    for i = 0, 4 do unidex.line(cx - 10, cy - 11 + i * 7, cx + 10, cy - 11 + i * 7) end
  else  -- scissors: two rings and crossed blades
    ring(cx - 9, cy + 13, 7); ring(cx + 9, cy + 13, 7)
    unidex.line(cx - 4, cy + 7, cx + 12, cy - 20); unidex.line(cx - 3, cy + 8, cx + 13, cy - 19)
    unidex.line(cx + 4, cy + 7, cx - 12, cy - 20); unidex.line(cx + 3, cy + 8, cx - 13, cy - 19)
  end
end

function draw()
  if game == "coin" then
    unidex.header("Coin", score.heads .. " H / " .. score.tails .. " T")
    ring(100, 86, 48); ring(100, 86, 47); ring(100, 86, 41)
    if coin then
      unidex.centered(100, coin == 1 and "H" or "T", "large")
      unidex.centered(152, coin == 1 and "Heads" or "Tails", "bold")
    else
      unidex.centered(100, "?", "large")
      unidex.centered(152, "Press B to flip", "small")
    end
    unidex.hints("", coin and "again" or "flip", "rock paper scissors")
  else
    unidex.header("Rock paper scissors")
    unidex.text(22, 44, "You  " .. score.you, "tiny")
    local them = score.me .. "  unidex"
    unidex.text(186 - unidex.width(them, "tiny"), 44, them, "tiny")
    drawMove(pick, 45, 84)
    unidex.centered(90, "vs", "small")
    if mine then drawMove(mine, 155, 84) else unidex.text(148, 94, "?", "large") end
    unidex.centered(130, MOVES[pick] .. (mine and (" - " .. MOVES[mine]) or ""), "small")
    if result then unidex.centered(152, result, "bold") end
    unidex.hints("pick", "throw", "coin")
  end
end

function onA()
  if game == "rps" then pick = pick % 3 + 1; mine, result = nil, nil; return "partial" end
end

function onB()
  if game == "coin" then
    coin = unidex.random(2)
    if coin == 1 then score.heads = score.heads + 1 else score.tails = score.tails + 1 end
  else
    mine = unidex.random(3)
    local diff = (pick - mine) % 3
    if diff == 0 then result = "A draw"
    elseif diff == 1 then result = "You win!"; score.you = score.you + 1
    else result = "unidex wins"; score.me = score.me + 1 end
  end
  save()
  return "full"
end

function onBHold()
  game = game == "coin" and "rps" or "coin"
  unidex.data.write("game", game)
  coin, mine, result = nil, nil, nil
  return "full"
end
