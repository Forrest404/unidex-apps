# unidex apps

The apps in the store on the [unidex website](https://forrest404.github.io/unidex/store.html). Each one is a
folder in `apps/`, written in Lua for the unidex e-ink device. Anyone can write one and send it in. Every app is
read and tried before it is listed.

## Writing an app

The guide has everything: the folder layout, the `app.json` fields, the `unidex.*` API, the limits and an
example. Read [Writing apps for unidex](https://github.com/Forrest404/unidex/blob/beta/docs/APPS.md).

`template/my-app/` is a starting point. Copy it, rename the folder to your app's id, and change `app.json`.

To try it on your own unidex before sending it in, plug it in and run, from a copy of the
[unidex](https://github.com/Forrest404/unidex) repository:

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

The automatic checks can't tell what an app is for. The review looks at what it does, whether its permissions
match that (an app that asks for `wifi` should say what it connects to and why), and whether it treats the people
using it fairly. The full rules for what is accepted will be written here before submissions open.

## Status

Submissions are not open yet. The store, the checks and this process are being tried out first.
