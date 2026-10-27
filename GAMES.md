# Making games for unidex

A game is an app that plays in Games, next to Flappy, Dino, Stack and Jetpack. It's the same kind of folder as an
app, written in the same Lua with the same `unidex.*` calls, but you only write the game itself. The Games app does
the rest: the list, the frames, the button, the game-over screen and the best score.

Games need firmware newer than v1.9 (API level 4). For the rest of what an app can do, see
[Building apps](APPS.md) and [The unidex API](API.md).

## Start from the template

`template/my-game/` is a working game, Hop: blocks come from the right and B hops over them. It's also in the store
as `apps/hop`. To start your own:

1. Copy `template/my-game/` to `apps/<your-id>/`. The id is lower case letters, numbers and `-`, up to 24
   characters, and it must match the folder name.
2. In `app.json`, change `id`, `name`, `author`, `description`, `license` and the `icon`.
3. Change `main.lua`.
4. Write the README: how to play, how you score, and how a round ends.

## app.json for a game

```json
{
  "id": "my-game",
  "name": "My Game",
  "version": "1.0.0",
  "author": "your name",
  "description": "One sentence: how to play.",
  "category": "games",
  "api": 4,
  "type": "game",
  "frame_ms": 100,
  "permissions": [],
  "license": "MIT"
}
```

- `"type": "game"`, `"category": "games"` and `"api": 4` are what make it a game. A game can't have `"extends"`.
- `frame_ms` is optional: how often `step()` runs, in milliseconds, from 48 to 1000. It's 100 if you leave it out.
- The other fields are as for any app, including the optional `icon` (see [Building apps](APPS.md#appjson)).

## The four functions

A game defines these four global functions, and the Games app calls them.

| Function | When it runs | Return |
|---|---|---|
| `start(seed)` | A new round starts | nothing |
| `step(tapped, held)` | Every frame of the round | `"over"`, `"moved"` or `"still"` |
| `draw()` | The screen needs painting: after `start()`, and after a step that returns `"moved"` | nothing |
| `score()` | The Games app wants the score | a whole number |

**`start(seed)`** sets up a new round. Set every variable here, not at the top of the file: someone can play many
rounds in a row, and each one starts with `start()`. Call `math.randomseed(seed)` first (see
[randomness](#randomness-and-the-seed)).

**`step(tapped, held)`** moves the game on by one frame. `tapped` is true if B was pressed since the last frame,
and `held` is true while B is down. It returns one of these:

- `"moved"`: something changed, so the screen is redrawn. Returning nothing counts as `"moved"`.
- `"still"`: nothing changed, so the screen is left alone. Hop returns this while it waits for the first press.
- `"over"`: the round has ended. The Games app shows the game-over screen with `score()`.

**`draw()`** draws the whole play screen, starting from white. It doesn't change anything: all the changes happen
in `step()`, and `draw()` shows them.

**`score()`** returns the score so far, a whole number. Show it while people play, too; Hop draws it top right.

A whole game, if a very small one: each tap moves a box to the right, and the round ends at the edge.

```lua
local x

function start(seed)
  math.randomseed(seed)
  x = 0
end

function step(tapped, held)
  if tapped then x = x + 10 end
  if x >= 200 then return "over" end
  if tapped then return "moved" end
  return "still"
end

function draw()
  unidex.fill(x, 90, 20, 20)
end

function score()
  return x // 10
end
```

These four are all a game needs. The button functions of an app (`onA()`, `onB()` and the rest) aren't used: in a
round, B goes to `step()`.

## Frames and the screen

`step()` runs every `frame_ms` milliseconds, 100 unless you change it. The play screen uses the e-ink panel's fast
mode, which shows about 7 frames a second. That's quick for e-ink and slow for a game, so:

- **Move things a few pixels each frame,** not one. Hop's blocks move 5 pixels a frame at first.
- **Keep `draw()` simple.** A few filled boxes and some text redraw quickly. Hundreds of lines don't.
- **Return `"still"` when nothing changed.** The screen isn't touched, which saves a refresh.
- **Fast mode leaves faint ghosts** of what moved. Big solid shapes stay clear; thin lines and small text that move
  every frame blur.

## One button

In a round, B is the only button.

- **A tap** is `tapped`: true for one frame after B goes down. A tap that's over between two frames still counts.
- **A hold** is `held`: true for every frame while B is down. Use it for "keep going": hop higher, fly up, charge.
- **Holding A** leaves the round, without a score. You don't handle it.

Hop uses both: a tap starts a hop, and holding B on the way up makes it go higher. Say in your README which one
your game uses, or both.

## Randomness and the seed

`start(seed)` gets a number for the round. Call `math.randomseed(seed)` there and use `math.random` for everything
random in play. Then the same seed plays the same round, which is how the test tools replay a game.

```lua
function start(seed)
  math.randomseed(seed)
  gap = math.random(80, 140)  -- a whole number from 80 to 140
end
```

`unidex.random()` and `unidex.time()` still work, but they aren't part of the seed, so a round that uses them in
play can't be replayed. Keep them out of `step()`.

## What the Games app does for you

- **The list.** Your game is listed in Games after the built-in four, with "best N" beside it.
- **The frames.** It calls `step()` every `frame_ms`, and `draw()` when the screen needs it.
- **The game-over screen.** It shows the score, "New best!" or the best so far, and "B again" for another round.
- **The best score.** It keeps it in your game's data file `best`, so don't use that name for a file of your own.
  The home screen shows "Best: <name> N".
- **Sleep.** 30 seconds without B ends the round, so the device can go to sleep as usual. You don't need to save
  anything in the middle of a round.

**Hold B** on a store game in the Games list to offload or delete it, as in Apps.

Apps in the `games` category that aren't `"type": "game"` (Dice, Coin & RPS, Dex) are listed under Games too, and
open as normal apps from there. They aren't in Apps any more. Make yours a game when it's played in rounds with B
and has a score; make it an app when it needs both buttons or more than one screen.

## Laying out the screen

The screen is 200 x 200 pixels, black on white, with (0, 0) at the top left. In a round the Games app shows no
header and no hints, so the whole screen is yours, and you don't need to call `unidex.header()` or `unidex.hints()`.

- **`y` in the text calls is the baseline,** the line the letters sit on, not the top or the middle.
- **Leave room for the score.** Hop draws it top right in `"medium"`, at y = 20.
- **Keep a margin** of about 8 px from the edges for text.
- **Say how to start.** If nothing moves until the first press, say so on the screen, as Hop does ("B to hop").

## Making it fair and fun

- **Slow is fine.** At 7 frames a second, a game that's easy to read is more fun than one that's fast. Start slow
  and speed up a little as the score goes up.
- **Big shapes.** Solid boxes 10 pixels or more across are easy to follow on e-ink. Avoid detail that moves.
- **Be forgiving.** The screen is a little behind, so let near misses through. Hop's blocks count as touched only
  when they overlap the runner by more than 2 pixels.
- **Give people a moment.** Wait for the first press, or start with the first obstacle far away.
- **No flicker tricks.** Don't flash or invert the whole screen to show a hit: e-ink makes it slow and smeary. The
  game-over screen is enough.
- **Always winnable.** Check that what you put in the way can always be cleared, even at the top speed. Hop puts
  blocks further apart as it gets faster, so there's room to land between two.

## Your own data

`unidex.data` works as it does in apps ([Saving data](API.md#saving-data)), apart from the file `best`, which the
Games app keeps. Most games don't need any.

## Limits

The limits are the same as for any app: about 2 seconds for one call, about 512 KB of memory, and 64 KB a file. A
step should take a few milliseconds, so keep the work in each frame small. Breaking a limit, or any other error,
shows "App error" with the reason.

## Trying it

Until the firmware after v1.9 is released, use the website's "next" emulator: add `?v=next` to the page's
address.

- **In the App editor:** open [tools.unidex.shop/editor.html?v=next](https://tools.unidex.shop/editor.html?v=next),
  choose "A game" under "Start from", and press Run. It opens your game on the emulated unidex.
- **A folder you already have:** open [Try unidex](https://tools.unidex.shop/try.html?v=next) and choose your game's
  folder under "Try your app", then open it from Games on the simulated screen. Choose the folder again after each
  change.
- **On your unidex:** with firmware newer than v1.9, plug it in, press a button, and run
  `python3 tools/appinstall.py install path/to/your-game` from a copy of the
  [unidex](https://github.com/Forrest404/unidex) repository. It shows up in Games. Older firmware says "needs newer
  firmware".

Play a few rounds to the end, and one where you don't press anything for 30 seconds.

## Sending it in

Exactly as for an app: add your folder as `apps/<id>/` in a pull request. The [README](README.md#sending-it-in)
explains the steps and what gets checked by hand. The pull request asks how you score and how a round ends.
`apps/hop` is a game already in the store, if you want to see one.

## Checklist

- [ ] `app.json` has `"type": "game"`, `"category": "games"` and `"api": 4`, and no `"extends"`.
- [ ] `main.lua` defines `start`, `step`, `draw` and `score`.
- [ ] `start(seed)` calls `math.randomseed(seed)` and sets every variable, and play uses `math.random`.
- [ ] `step()` returns `"over"` when the round ends, and `"still"` when nothing changed.
- [ ] `score()` returns a whole number.
- [ ] The game doesn't use a data file called `best`.
- [ ] The shapes are big and the game is fair at its top speed.
- [ ] The README says how to play, how you score, and how a round ends.
