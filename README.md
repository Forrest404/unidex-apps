# unidex apps

The apps, games and plugins in the store on the [unidex website](https://tools.unidex.shop/store.html). Each one
is a folder in `apps/`, written in Lua for the unidex e-ink device (v1.7 or newer). Anyone can write one and send it
in. Every app is tried automatically and read by a person before it's listed.

## Writing an app

[Building apps](APPS.md) is the place to start: how an app runs, laying out a screen, keeping data through sleep,
patterns that work with two buttons, going online, and trying it. `template/my-app/` is a working app to copy.
Every call, in one short list, is in [The unidex API](API.md).

## Writing a game

A game is played in Games, next to Flappy, Dino, Stack and Jetpack, with B as its one button. You write four
functions (start a round, step a frame, draw it, give the score) and the Games app does the rest: the frames, the
game-over screen and the best score. [Making games](GAMES.md) explains how, and `template/my-game/` is a working
one to start from (Hop, also in the store as `apps/hop`). Games need firmware newer than v1.9.

## Writing a plugin

A plugin adds to one of the built-in apps instead of being an app of its own. For now that's Badge: a badge
plugin draws a badge that can change, like today's date or the moon. [Writing plugins](PLUGINS.md) explains how
they run, what they can and can't do, and how to try one. `template/my-badge/` is a working one to start from.

## Trying it on your unidex

To try an app, game or plugin on your own unidex before sending it in, plug it in, press a button, and run this
from a copy of the [unidex](https://github.com/Forrest404/unidex) repository:

```sh
python3 tools/appinstall.py install path/to/your-app
```

## Sending it in

1. Fork this repository and add your app as `apps/<id>/` (one app per pull request).
2. Open a pull request. The checklist in it asks a few questions about the app.
3. Automatic checks run on it. They check `app.json` and the limits, read every Lua file for syntax errors, and
   then install the app in the unidex emulator and press every button. If it shows "App error", the check fails
   and says where. The screenshots it takes are attached to the run, under Artifacts.
4. Then the owner of the store reads the code and tries it, and either:
   - **accepts it:** the pull request is merged, and the app appears in the store within about 6 hours, or
   - **declines it:** the pull request is closed with a comment saying why. You can fix it and open a new one.

To update an app you already have in the store, change its folder, raise `version`, and open a new pull request.

## What gets checked by hand

The automatic checks catch crashes and broken files. A person then reads every app before it's listed, and looks at
these things. An app is declined, with the reason written on the pull request, if:

- **It doesn't work,** or doesn't do what its description says.
- **It asks for more than it needs.** An app with the `wifi` permission must say in its README which addresses it
  connects to and why, and only use them for that.
- **It collects or sends anything about the person using it** that they wouldn't expect, or sends anything at all
  without saying so.
- **It's harmful or deceptive:** it pretends to be something it isn't (another app, the device's own screens, a
  login page), tries to get round the sandbox, or is meant to hurt or harass anyone.
- **It isn't yours to share.** Every app names its licence in `app.json`, and opening a pull request means you
  have the right to share everything in the folder under it.
- **It's offensive,** or not suitable for a device that people carry around, show their friends and use at school.

Being declined isn't final: fix what the comment says and open a new pull request. Apps that are already listed can
be removed later if they turn out to break these rules; the store page then stops offering them.

Questions, or a problem with an app in the store? [Open an issue](https://github.com/Forrest404/unidex-apps/issues).
