-- A starting point: a screen with a title, a line of text, and the button hints.
-- Guide: https://github.com/Forrest404/unidex/blob/main/docs/APPS.md

local message = "Hello from my app"

function draw()
  unidex.header("My App")
  unidex.centered(90, message, "medium")
  unidex.hints("", "change", "")
end

function onB()
  message = message == "Hello from my app" and "B was pressed" or "Hello from my app"
  return "partial"
end
