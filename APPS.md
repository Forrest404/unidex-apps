# Building apps for unidex

An app is a small folder of Lua that runs on the unidex: its own screen, opened from Apps on the device. This page
is the practical side: how an app runs, how to lay out a screen, how to keep its data through sleep, the patterns
that work on a two-button e-ink device, and how to try it and send it in.

Every call, with its arguments, is in one short list: [The unidex API](API.md). To add to a built-in app
instead, see [Writing plugins](PLUGINS.md). For a one-button game that plays in Games, see
[Making games](GAMES.md).

## Start from the template

`template/my-app/` is a working app: a counter that keeps its count when the device sleeps, with an options screen
behind hold B. To start your own:

1. Copy `template/my-app/` to `apps/<your-id>/`. The id is lower case letters, numbers and `-`, up to 24
   characters, and it must match the folder name.
2. In `app.json`, change `id`, `name`, `author`, `description`, `category` and `license`.
3. Change `main.lua`.
4. Write the README: what it does, which button does what, and what it keeps in its data files.

## The folder

```
apps/my-app/
  app.json     who it is and what it needs
  main.lua     the code; more .lua files are fine (load them with require "name")
  README.md    for people reading the store; it isn't sent to the device
```

On the device the app also gets a `data/` folder for its own files. That's where everything it saves goes, and
it's what a delete loses.

### app.json

```json
{
  "id": "my-app",
  "name": "My App",
  "version": "1.0.0",
  "author": "your name",
  "description": "One sentence: what it does.",
  "category": "tools",
  "api": 1,
  "type": "app",
  "permissions": [],
  "license": "MIT"
}
```

- `name` is up to 20 characters, `author` up to 40, `description` up to 140.
- `category` puts it under one of the store's filters: `games`, `tools`, `time`, `badges`, `learning`, `fun` or
  `other`. On the device, an app in `games` is listed in Games instead of Apps (from the firmware after v1.9).
- `permissions` is empty unless it needs the internet: then `["wifi"]`. The store shows it before anyone installs.
- `icon` is optional: 40 strings of 40 characters, where `#` is ink and anything else is blank. The store shows it
  beside the app. Without one, the store uses the device's Apps icon.
- `version` is `major.minor.patch`. Raise it for every update, or the store won't offer the update.

## How an app runs

You define global functions, and the device calls them. Only `draw()` is required.

| Function | When the device calls it | What to return |
|---|---|---|
| `onEnter()` | The app starts: when it's opened, and again after the device wakes from a deep sleep | nothing |
| `draw()` | Whenever the screen needs painting. Paint the whole screen each time. | nothing |
| `onA()` | A is pressed | a redraw |
| `onB()` | B is pressed | a redraw |
| `onBHold()` | B is held | a redraw |
| `onBack()` | A is held. Without it, holding A leaves the app. | `"exit"` to leave, or a redraw to stay |
| `tick()` | About once a second while the device is awake (see [sleep](#sleep-and-saving)) | a redraw, or nothing |
| `onExit()` | The app is closing | nothing |

A **redraw** is one of these:

- `"partial"`: a quick refresh without the flash. Use it for almost everything.
- `"full"`: the whole screen flashes black and white, which clears any ghosting. Use it when the whole picture
  changes, such as moving to a different screen with a big image.
- `nil` (return nothing): nothing changed, and the screen isn't touched.

You don't draw inside `onA()` and the other button handlers. Change your variables, return `"partial"`, and the
device calls `draw()`. Keeping all the drawing in `draw()` means the screen always matches your state, including
after a wake.

E-ink ghosts a little with each partial refresh, so after ten of them the device does a full one by itself. The
screen also refreshes at most once a second.

## Laying out a screen

The screen is 200 x 200 pixels, black on white, with the origin at the top left. Most screens use three parts:

| Part | Where | How |
|---|---|---|
| Header | the top 24 px (title baseline at 16, a rule at 23) | `unidex.header("Title", "right")`. The right side is optional: a count, a time. |
| Content | y = 24 to 162 | your drawing |
| Hints | from y = 163 (a rule, A and B on one line, hold B below) | `unidex.hints("next", "add", "options")` |

- **Every screen should have hints**, so people know what the buttons do. An empty string leaves one out:
  `unidex.hints("", "add", "")`. Hold A always goes back, so it isn't listed.
- **`y` in the text calls is the baseline**, the line the letters sit on, not the top. `unidex.centered(110, "Hi",
  "large")` puts the bottom of the letters at y = 110.
- **Fonts:** `"tiny"`, `"small"` (the default), `"medium"`, `"bold"` and `"large"`. Use `unidex.width(text, font)`
  to measure text before you place it, and `unidex.wrap()` for text that might not fit on one line.
- **Plain ASCII only.** Letters like é, curly quotes and emoji aren't in the fonts and won't show. `text()` and
  `centered()` draw up to 200 characters, `wrap()` up to 12 lines, and a toast up to 40 characters.
- **Black and white only,** no greys. For white text, draw a black box with `unidex.fill()` and pass `"white"` as
  the text's colour.
- **Keep a margin.** The device's own screens keep about 8 px from the edges.

## Sleep and saving

This matters more than anything else on this page.

The device naps between presses to save battery. After the "Sleep after" time in Settings (10 seconds unless it's
been changed) with no press, it goes into a deep sleep. **A deep sleep forgets everything in memory.** The screen
keeps showing your app, because e-ink holds its picture without power, but your Lua variables are gone. The next
press wakes the device, your app starts again from the top and `onEnter()` runs. Then that press is passed to
your app as usual.

So:

- **Keep anything that matters in data files.** Read it in `onEnter()` and write it whenever it changes. The
  template saves its count on every press.
- **Don't keep a timer running in memory.** Save the time it started (from `unidex.time()`), and work out what's
  left in `draw()`. Then the timer is right whenever someone looks, however long the device slept.
- **Expect to start on your first screen.** Which screen you're on is usually fine to lose, but save it too if
  losing it would annoy people. A quiz could save which question it's on.

`tick()` runs about once a second while the device is awake and plugged in. On battery the device naps between
presses, so `tick()` only runs when your app asks: `unidex.wake_in(ms)` wakes it for the next tick after that many
milliseconds. Ask again in each `tick()` to keep going. Nothing wakes the device from a deep sleep except a button,
so an app can't alert anyone or update the screen while it's asleep.

```lua
function tick()
  unidex.wake_in(60000)  -- come back in a minute, if the device is still awake
  return "partial"       -- draw() shows the new minutes left
end
```

### Your data files

| Call | What it does |
|---|---|
| `unidex.data.read(name)` | The file's text, or `nil` if there isn't one |
| `unidex.data.write(name, text)` | Saves the whole file, or nothing at all; returns `true` or `false` |
| `unidex.data.append(name, text)` | Adds to the end (good for a log) |
| `unidex.data.list()` | A table of the names |
| `unidex.data.remove(name)` | Deletes one |

Names use a-z, 0-9, `.`, `_` and `-`. Files hold text: save numbers with `tostring()` and read them back with
`tonumber()`. Always allow for a missing file (a first run, or the data was deleted):
`tonumber(unidex.data.read("count") or "") or 0`.

Updates keep `data/`. If a new version stores things differently, have it read the old format too, or people
lose what they had.

## Patterns that work

**Moving through a list.** A moves to the next item and B picks it. Show where you are ("3 of 8") in the header's
right side.

**No typing.** There's no keyboard, so offer choices instead: a list of names, cities or labels to pick from with
A and B. Numbers are set with A to change and B to move to the next field. `apps/countdown`, `apps/tally` and
`apps/weather` all work this way.

**A second screen.** Keep a variable that says which screen is showing, draw that one in `draw()`, and use
`onBack()` to step back to the main screen before leaving. The template does this for its options.

**Something random.** `unidex.random(n)` gives a number from 1 to `n`. If it should stay the same all day (a word
of the day, a daily quote), pick it from the date instead, or pick it once and save it.

**Dates.** `unidex.time()` gives `year month day hour min sec wday` and `valid`. Until the clock has been set,
`valid` is false. Check it and say "Clock not set" rather than showing a wrong date.

**Splitting the code.** Put helpers in another file in the folder, such as `util.lua` ending in `return { ... }`,
and load them with `local util = require "util"`. Only files inside your own folder can be loaded.

## Going online

With `"permissions": ["wifi"]`, `unidex.http.get(url)` fetches a page over the device's saved WiFi:

```lua
local status, body = unidex.http.get("https://api.example.com/today")
if status == 200 then
  unidex.data.write("cache", body)
elseif status == nil then
  unidex.toast(body)  -- why it couldn't connect: no WiFi saved, no connection, ...
end
```

`unidex.wifi.scan()` lists the networks nearby instead (name, signal, security) and needs `"api": 2` in `app.json`;
see [API.md](API.md). The Dex app is an example.

- HTTPS only, up to 32 KB of reply, and up to 15 seconds. The screen waits while it works, so fetch when someone
  presses a button, not in `draw()`. The wait doesn't count against your 2 seconds.
- It returns `nil` and a reason when it can't connect, and it's refused on a low battery. Show that clearly and
  keep working with what you saved last time.
- **Keep the last result in a data file** and show it with when it was fetched. Then the app is still useful with
  no WiFi around.
- There's no JSON library. Pull out the values you need with Lua's string patterns, such as
  `body:match('"temperature":%s*(-?[%d.]+)')`.
- Apps never see the WiFi password or any keys. Only use services that need no account or key, and say in your
  README which addresses the app connects to and why. That's one of the
  [things checked by hand](README.md#what-gets-checked-by-hand).

## Limits

The device enforces these, so one app can't hang it or fill the card:

| Limit | Value |
|---|---|
| One call (`draw()`, `onB()`, ...) | about 2 seconds |
| Memory | about 512 KB |
| One file | 64 KB |
| The app's own files | 512 KB in all |
| Its `data/` folder | 512 KB in all |
| Apps and plugins on one device | 24 |

There's no `io`, `os` or `load`. The `string`, `table`, `math`, `utf8` and `coroutine` libraries work as normal.

## When it goes wrong

If your app hits an error or breaks a limit, the device shows "App error" with the reason, and B goes back to
the Apps list. The device itself never crashes. The usual reasons:

| What it says | Why |
|---|---|
| main.lua:12: attempt to ... | A Lua error on that line: often a `nil` (a missing file read as a number, or a misspelled name) |
| took too long (over 2 s) | One call ran for more than about 2 seconds: a loop that doesn't end, or too much work at once |
| not enough memory | The app used more than about 512 KB: big tables or very long strings |
| http: the app needs the "wifi" permission | `unidex.http.get()` without `"wifi"` in `permissions` |
| needs newer firmware | `"api"` is higher than this device supports; it needs an update from the website |

`print()` doesn't draw anything. In the emulator its output shows beside the screen, and with the test firmware
it comes out over USB.

## Trying it

- **In the emulator:** open [Try unidex](https://tools.unidex.shop/try.html) and choose your app's folder under
  "Try your app", then open it from Apps on the simulated screen. Choose the folder again after each change. The
  emulator has no WiFi, so an online app should show its "no connection" screen there.
- **Automatically:** `node emu/test/app_smoke.mjs path/to/your-app --shots <folder>` opens your app in the
  emulator, presses every button, fails if it ever shows "App error", and saves a screenshot after each press. The
  store runs the same check on every submission.
- **On your unidex:** plug it in, press a button, and run
  `python3 tools/appinstall.py install path/to/your-app`. It shows up in Apps.

Before you send it in, look through the screenshots: nothing cut off at the edges, nothing under the hints, and a
hint for every button that does something.

## Sending it in

Add your folder as `apps/<id>/` in a pull request. The [README](README.md#sending-it-in) explains the steps and
what gets checked by hand. Every app in `apps/` is a working example, from the very small (`apps/hello`) to ones
that go online (`apps/weather`).
