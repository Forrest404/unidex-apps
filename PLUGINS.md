# Writing plugins for unidex

A plugin adds something to one of the apps already built into unidex, instead of being an app of its own. It's the
same kind of folder as an app (an `app.json`, a `main.lua`, a README), written in the same Lua, with the same
`unidex.*` calls. The differences are that the built-in app decides when your code runs, and your plugin
never gets the buttons.

This page covers what's different about plugins. For everything they share with apps (the drawing calls, data
files, fonts, limits), see [Building apps](APPS.md) and the reference,
[Writing apps for unidex](https://github.com/Forrest404/unidex/blob/main/docs/APPS.md).

## Which apps take plugins

| Built-in app | `"extends"` | Your code defines | Where it shows up |
|---|---|---|---|
| Badge | `"badge"` | `badge()`, which draws the whole badge | In Badge, after the image badges, with its own thumbnail in the picker |

Only Badge takes plugins for now. Each new one will be added to this table, with the function it calls. If you'd
like to extend another app, [open an issue](https://github.com/Forrest404/unidex-apps/issues) saying which app and
what your plugin would add.

## Start from the template

`template/my-badge/` is a working badge plugin. It counts the days since it was first shown. To start your own:

1. Copy `template/my-badge/` to `apps/<your-id>/`. The id is lower case letters, numbers and `-`, and it must
   match the folder name.
2. In `app.json`, change `id`, `name`, `author`, `description` and `license`.
3. Change `badge()` in `main.lua` to draw your badge.
4. Write the README: what the badge shows and what it keeps in its data files.

## app.json for a plugin

```json
{
  "id": "my-badge",
  "name": "My Badge",
  "version": "1.0.0",
  "author": "your name",
  "description": "One sentence: what the badge shows. Say it's a badge plugin, found in Badge.",
  "category": "badges",
  "api": 1,
  "type": "plugin",
  "extends": "badge",
  "permissions": [],
  "license": "MIT"
}
```

- `"type": "plugin"` and `"extends"` are what make it a plugin. `"extends"` must be one of the names in the table
  above, or the device refuses to run it (it says "can't extend that app") and the store's checks fail.
- `"category"` is usually `"badges"` for a badge plugin.
- `"icon"` is optional, as it is for apps. The store shows it. In Badge's picker, the thumbnail is drawn by your
  `badge()` instead.
- Put the person who uses it first in the description. "Find it in Badge" helps, because a plugin isn't opened
  from Apps like an app is.

## Badge plugins: `badge()`

```lua
function badge()
  unidex.rect(6, 6, 188, 188)
  unidex.centered(110, "Hello", "large")
end
```

`badge()` draws the whole badge. It gets the full 200 x 200 screen, already cleared to white. A badge has no header
or hints, so don't call `unidex.header()` or `unidex.hints()`. For a moment after Badge opens, it shows its own hints
over the bottom of the screen (from about y = 160 down), so the bottom strip is briefly covered.

### When it runs

Badge calls `badge()` whenever it draws your badge:

- when you flip to it with A or hold B, pick it in the picker, or open Badge while it's the current badge
- if Badge has just opened on it, again about 2.5 seconds later, when Badge's hints go away
- once to make its 40 x 40 thumbnail for the picker

The plugin is started fresh for each call and closed straight after. Three things follow from that:

- **Nothing stays in memory.** A variable you set in one call is gone in the next. Anything to remember goes in a
  data file (`unidex.data.read` and `unidex.data.write`). The template saves the first day it was shown this way.
- **Draw the same thing every time.** The same badge can be drawn three times in a few seconds, so it shouldn't
  change between those calls. If you want something random (a quote, a pattern), pick it once a day, save it in a
  data file, and draw what you saved.
- **Be quick.** Each call can run for about 2 seconds before it's stopped. The screen waits for `badge()`, so the
  quicker the better.

Between draws the screen keeps the last picture. E-ink holds an image without power, and nothing redraws a badge
while the device sleeps. A date badge left showing overnight still shows yesterday's date until Badge draws it again.

### No buttons, no settings

A, B and hold B belong to Badge (next, the picker, previous), so a plugin can't respond to buttons or have a
settings screen. It can only draw. If what you want to make needs choices, make an app instead. An app and a plugin
can't share data files, because each has its own `data/` folder.

### What it can and can't call

- **All the drawing calls** work: `text`, `centered`, `wrap`, `rect`, `fill`, `line`, `qr`, `icon`, and `bitmap` for
  a 1-bit BMP in your folder.
- **`unidex.data`, `unidex.time()`, `unidex.battery()` and `unidex.random()`** work as they do in apps.
- **Check `unidex.time().valid`** before you use the date. A new device has no time until it's set, so show
  something like "Clock not set" rather than a wrong date. The template and `apps/today-badge` both do this.
- **`unidex.toast()` and `unidex.wake_in()`** aren't useful in a badge, so leave them out.
- **`unidex.http.get()`** works if the plugin asks for the `"wifi"` permission, but it's a poor fit. `badge()` runs
  several times each time the badge is shown, including for the thumbnail, and the screen waits for every fetch. If
  you really need it, keep the result in a data file, fetch only when that is out of date, and always draw
  something without a connection. The README must say what it connects to and why (see
  [what gets checked by hand](README.md#what-gets-checked-by-hand)).

### Designing for the badge

- It's 1-bit: black or white, no greys. Fonts are `"tiny"`, `"small"`, `"medium"`, `"bold"` and `"large"`, ASCII
  only.
- People see a badge from a few steps away, so use big text and few words.
- The picker's thumbnail takes every fifth pixel of your badge, so 1-pixel lines and small text can disappear in it.
  A bold shape or a thick frame keeps the thumbnail recognisable.
- Badge shows up to 32 badges, image badges first. If someone already has 32 images, plugins don't appear.

## When it goes wrong

If `badge()` fails, Badge shows "This plugin failed" in place of the badge, with the reason, and A still flips to
the next badge. The device itself never crashes. The usual reasons:

| What it says | Why |
|---|---|
| main.lua has no badge() function | The function is missing or misspelled (a badge plugin needs `badge`, not `draw`). |
| took too long (over 2 s) | `badge()` ran for more than about 2 seconds: a loop that doesn't end, or too much work in one call. |
| main.lua:12: ... | A Lua error on that line, such as calling something that's `nil`. |
| can't extend that app | `"extends"` isn't one of the names in the table above. |
| needs newer firmware | `"api"` is higher than this device supports. It needs a firmware update. |

## Trying it

- **In the emulator:** build it and open `emu/web/try.html` as the
  [guide](https://github.com/Forrest404/unidex/blob/main/docs/APPS.md#trying-it) describes, and choose your plugin's
  folder under "Try your app". Then open Badge on the simulated screen and press A until your badge comes up.
- **Automatically:** `node emu/test/app_smoke.mjs path/to/your-plugin`, from a copy of the
  [unidex](https://github.com/Forrest404/unidex) repository. It finds your badge in Badge, fails if it shows "This
  plugin failed", and saves a screenshot with `--shots <folder>`. The store runs the same check on every submission.
- **On your unidex:** plug it in, press a button, and run
  `python3 tools/appinstall.py install path/to/your-plugin`. It shows up in Badge.

## On the device and in the store

- **In Apps,** a plugin is listed with the tag "plugin". Pressing B on it says where it shows ("It shows in Badge")
  instead of opening it.
- **Offload and delete** work as they do for apps. Offloading keeps its data files. Deleting removes them for good,
  and the store asks first.
- **In the store,** it's marked "Plugin for Badge" and can be found with the Type and "Works with" filters.

## Sending it in

Exactly as for an app: add your folder as `apps/<id>/` in a pull request. The [README](README.md#sending-it-in)
explains the steps and what gets checked by hand. `apps/today-badge`, `apps/day-of-year` and `apps/moon-badge` are
badge plugins already in the store, if you want to see how they're made.
