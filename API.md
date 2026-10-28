# The unidex API

Every call an app can make, in one place. Everything is in one table, `unidex`. For how an app runs, laying out a
screen and keeping data through sleep, see [Building apps](APPS.md).

## The functions you write

The device calls these when things happen. Only `draw()` is required. A game has four of its own: see
[Games](#games).

| Function | When it runs | Return |
|---|---|---|
| `draw()` | The screen needs painting. Paint all of it. | nothing |
| `onA()` | A is pressed | a redraw |
| `onB()` | B is pressed | a redraw |
| `onBHold()` | B is held | a redraw |
| `onBack()` | A is held. Without it, holding A leaves the app. | `"exit"`, or a redraw to stay |
| `tick()` | About once a second while awake (on battery, only when you've asked with `unidex.wake_in`) | a redraw, or nothing |
| `onEnter()` | The app starts, and after the device wakes from a deep sleep | nothing |
| `onExit()` | The app closes | nothing |
| `badge()` | Badge plugins only: draw the whole badge ([Writing plugins](PLUGINS.md)) | nothing |

A **redraw** is `"partial"` (a quick refresh), `"full"` (a full refresh, with a flash), or nothing at all (the screen
stays as it is).

## Drawing

The screen is 200 x 200 pixels, black on white, with (0, 0) at the top left. In the text calls, `y` is the
**baseline**, the line the letters sit on.

- **Fonts:** `"tiny"`, `"small"` (the default), `"medium"`, `"bold"`, `"large"`. Plain ASCII only.
- **Colours:** `"black"` (the default) or `"white"`. Use white to draw on top of something black.

| Call | What it does |
|---|---|
| `unidex.header(title, right)` | The title bar along the top. `right` is optional, such as a count or a time. |
| `unidex.hints(a, b, holdB)` | The bottom bar: what A, B and hold B do. Use `""` to leave one out. |
| `unidex.text(x, y, text, font, colour)` | Text, starting at x. |
| `unidex.centered(y, text, font, colour)` | Text centred across the screen. |
| `unidex.wrap(x, y, width, text, lines, font)` | Text wrapped to fit `width`, on up to `lines` lines (6 if left out, 12 at most). Returns how many lines it used. |
| `unidex.width(text, font)` | How wide the text would be, in pixels. Draws nothing. |
| `unidex.rect(x, y, w, h, colour)` | A box outline. |
| `unidex.fill(x, y, w, h, colour)` | A filled box. |
| `unidex.line(x1, y1, x2, y2, colour)` | A line. |
| `unidex.qr(text, x, y, size)` | A QR code, about `size` pixels across (80 if left out). Up to 120 characters. |
| `unidex.icon(rows, x, y, scale)` | A 40 x 40 icon: a table of 40 strings of 40 characters, `#` for ink. `scale` 1 or 2. |
| `unidex.bitmap(file, x, y)` | A 1-bit BMP from your app's folder, up to 200 x 200. Only its black pixels are drawn. |

```lua
function draw()
  unidex.header("Hello", "3/5")
  unidex.centered(90, "Hi there", "large")
  unidex.fill(40, 110, 120, 24)
  unidex.centered(127, "on black", "small", "white")
  unidex.hints("next", "choose", "menu")
end
```

## Saving data

Each app has its own `data/` folder on the SD card. Files hold text. Names use a-z, 0-9, `.`, `_` and `-`.

| Call | What it does |
|---|---|
| `unidex.data.read(name)` | The file's text, or `nil` if there's no such file |
| `unidex.data.write(name, text)` | Saves the whole file. It's either all saved or not at all. Returns `true` or `false`. |
| `unidex.data.append(name, text)` | Adds to the end of the file |
| `unidex.data.list()` | A table of your file names |
| `unidex.data.remove(name)` | Deletes a file |

```lua
local best = tonumber(unidex.data.read("best") or "") or 0  -- 0 the first time
unidex.data.write("best", tostring(best + 1))
```

## The device

| Call | What it does |
|---|---|
| `unidex.time()` | A table: `year`, `month`, `day`, `hour`, `min`, `sec`, `wday` (1 is Sunday), and `valid`, which is false until the clock has been set |
| `unidex.battery()` | Two values: the percent, and whether it's charging |
| `unidex.toast(text)` | A short message over the screen, up to 40 characters |
| `unidex.wake_in(ms)` | Asks to be woken for a `tick()` after this many milliseconds (between 1 second and 24 hours). It only works while the device is awake. |
| `unidex.random(n)` | A random whole number from 1 to `n` |
| `unidex.frame(ms)` | Shows `draw()` now, in the middle of a function, as an animation frame, then waits `ms` (up to 1000) before going on. At most 60 frames in one go; the screen and the wait don't count against your 2 seconds. Needs `"api": 3`; the Chooser spin is an example. |
| `unidex.chime()` | Plays the device's chime, about half a second, for a timer or an alarm. Returns `true`, or `false` if it was skipped: Settings > Alert sound is off, it already chimed less than a second ago (so an app can't chime on and on), or the speaker is busy. At Volume 0 it plays silently. The chime doesn't count against your 2 seconds. Needs `"api": 5`. |
| `unidex.climate()` | The temperature and humidity from the device's own sensor: a table with `temperature_c` (°C) and `humidity_rh` (%), or `nil` and the reason if it can't be read. Takes about 20 ms. The sensor is inside the device, so it reads a few degrees warm, more while charging or on WiFi. Needs `"api": 6`. |
| `unidex.api` | The API level of this firmware: `6` with `unidex.climate` (`5` before it, after v1.10; `4` before `unidex.chime`, `3` before games, `2` before `unidex.frame`, `1` before `unidex.wifi`) |

```lua
local t = unidex.time()
if t.valid then
  unidex.centered(80, string.format("%02d:%02d", t.hour, t.min), "large")
else
  unidex.centered(80, "Clock not set")
end
```

## The internet

Only for apps with `"permissions": ["wifi"]` in `app.json`.

| Call | What it does |
|---|---|
| `unidex.http.get(url)` | Fetches a page over the device's saved WiFi. HTTPS only, up to 32 KB. Returns `status, body`, or `nil` and the reason when it can't connect. The screen waits while it works. |

```lua
local status, body = unidex.http.get("https://example.com/today.txt")
if status == 200 then unidex.data.write("cache", body) end
```

| Call | What it does |
|---|---|
| `unidex.wifi.scan()` | The WiFi networks nearby, up to 64: a list of `{ssid=, rssi=, security=}` (security is `open`, `WEP`, `WPA`, `WPA2`, `WPA2-E` or `WPA3`). Hidden networks are left out, and a name can appear once per access point. Never a network's address. About 2 seconds; returns `nil` and the reason on a low battery or while the radio is busy. Needs `"api": 2`. |

```lua
local nets, why = unidex.wifi.scan()
if nets then unidex.toast(#nets .. " networks nearby") else unidex.toast(why) end
```

## Games

A game plays in Games instead of Apps. In `app.json` it has `"type": "game"`, `"category": "games"` and
`"api": 4`, and optionally `"frame_ms"`: how often `step()` runs, from 48 to 1000 milliseconds (100 if left out).
Instead of the button functions, it defines these four. More in [Making games](GAMES.md).

| Function | When it runs | Return |
|---|---|---|
| `start(seed)` | A new round. Call `math.randomseed(seed)` and use `math.random`, so a seed replays the round. | nothing |
| `step(tapped, held)` | Every frame. `tapped`: B was pressed since the last frame. `held`: B is down now. | `"over"` (the round ends), `"moved"` (redraw) or `"still"` (no redraw). Nothing counts as `"moved"`. |
| `draw()` | The screen needs painting. Paint the whole play screen; there's no header or hints. | nothing |
| `score()` | The Games app wants the score | a whole number |

The Games app keeps the best score in your data file `best`, so don't use that name.

```lua
function step(tapped, held)  -- a ball falls, and each tap lifts it
  if tapped then y = y - 20 end
  y = y + 2
  if y > 190 then return "over" end
  return "moved"
end
```

## Lua itself

- **Available:** `string`, `table`, `math`, `utf8`, `coroutine`, and the basics (`pairs`, `tostring`, `tonumber` and
  the rest).
- **`require "name"`** loads `name.lua` from your own app's folder.
- **`print(...)`** shows in the emulator and with the test firmware. On a normal device it does nothing.
- **Not available:** `io`, `os`, `load`, `loadfile`, `dofile`. Use `unidex.data` for files and `unidex.time()` for the
  time.

## Limits

| | |
|---|---|
| One call (`draw()`, `onB()` and so on) | about 2 seconds |
| Memory | about 512 KB |
| One file | 64 KB |
| Your app's own files | 512 KB |
| Its `data/` folder | 512 KB |

Breaking a limit, or any other error, shows "App error" with the reason, and the rest of the device carries on.
