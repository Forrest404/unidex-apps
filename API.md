# The unidex API

Every call an app can make, in one place. Everything is in one table, `unidex`. For how an app runs, laying out a
screen and keeping data through sleep, see [Building apps](APPS.md).

## The functions you write

The device calls these when things happen. Only `draw()` is required.

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
| `unidex.api` | The API level of this firmware, now `1` |

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
