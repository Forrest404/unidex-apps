-- A starting point: a counter that keeps its count when the device sleeps, with an options screen.
-- Guide: https://github.com/Forrest404/unidex-apps/blob/main/APPS.md

local STEPS = { 1, 5, 10 }
local count, step = 0, 1  -- step: which of STEPS B adds
local screen = "main"     -- "main" or "options"

-- The device forgets everything in memory when it sleeps, and the app starts again from onEnter().
-- So what matters lives in data files: read here, written whenever it changes.
function onEnter()
  count = tonumber(unidex.data.read("count") or "") or 0
  step = tonumber(unidex.data.read("step") or "") or 1
  if not STEPS[step] then step = 1 end
end

local function save()
  unidex.data.write("count", tostring(count))
  unidex.data.write("step", tostring(step))
end

function draw()
  if screen == "options" then
    unidex.header("Options")
    unidex.centered(70, "B adds " .. STEPS[step], "medium")
    unidex.centered(100, "A changes how much.")
    unidex.centered(118, "B resets the count to 0.")
    unidex.hints("step", "reset", "")
  else
    unidex.header("My App", "+" .. STEPS[step])
    unidex.centered(110, tostring(count), "large")
    unidex.hints("", "add", "options")
  end
end

function onA()
  if screen == "options" then
    step = step % #STEPS + 1
    save()
    return "partial"
  end
end

function onB()
  if screen == "options" then
    count = 0
    save()
    screen = "main"
    unidex.toast("Count reset")
  else
    count = count + STEPS[step]
    save()
  end
  return "partial"
end

function onBHold()
  if screen == "main" then
    screen = "options"
    return "partial"
  end
end

-- Hold A: from the options screen, back to the counter; from the counter, out of the app.
function onBack()
  if screen == "options" then
    screen = "main"
    return "partial"
  end
  return "exit"
end
