# maki-herdr-pane-title-sync

A maki package that reports the focused maki session's id and title to the herdr
pane maki runs in, so the herdr pane title tracks the session (including
`/rename`) without herdr parsing maki's session logs.

## What it does

- Activates only when running inside a herdr pane (`HERDR_ENV=1` +
  `HERDR_PANE_ID`); otherwise it loads and exits without doing anything.
- `SessionTitleChanged` / `SessionStatusChanged` (focused) →
  `herdr pane report-metadata --source herdr:maki --title <title>`

## Requirements

- maki with the `SessionTitleChanged` autocmd event (v0.6.0 or above)

## Install

Declare it in the global `init.lua`:

```lua
maki.pack.add({ "https://github.com/xqqmdy/maki-herdr-pane-title-sync", })
```
