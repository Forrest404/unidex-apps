-- A badge plugin. Badge calls badge() to draw this badge each time it shows it (and once for its thumbnail),
-- and closes the plugin straight after, so nothing stays in memory: anything to remember goes in a data file.
-- This one counts the days since it was first shown.

-- Days since a fixed date, so two dates can be subtracted.
local function dayNumber(y, m, d)
  if m < 3 then y, m = y - 1, m + 12 end
  return 365 * y + y // 4 - y // 100 + y // 400 + (153 * (m - 3) + 2) // 5 + d
end

function badge()
  local t = unidex.time()
  if not t.valid then  -- the clock isn't set yet: say so instead of counting from a wrong date
    unidex.centered(96, "Clock not set", "bold")
    unidex.centered(120, "Settings > Date & time")
    return
  end

  local today = dayNumber(t.year, t.month, t.day)
  local first = tonumber(unidex.data.read("first") or "")
  if not first then
    first = today
    unidex.data.write("first", tostring(first))
  end

  unidex.rect(6, 6, 188, 188)
  unidex.rect(8, 8, 184, 184)
  unidex.centered(58, "Day", "medium")
  unidex.centered(120, tostring(today - first + 1), "large")
  unidex.centered(156, "with this badge", "medium")
end
