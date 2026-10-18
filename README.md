# Disable builtin display

Disable a MacBook's built-in display from the command line, so macOS stops driving a panel you
aren't using. Handy for a laptop used with an external monitor, or one whose screen is broken.

macOS offers no supported way to do this. When an external display is attached it either mirrors
the built-in one or keeps it running as a second screen, and both cost GPU time. `pmset` and
display sleep only blank the panel. This tool actually detaches it, using a private CoreGraphics call
(`CGSConfigureDisplayEnabled`).

## Features

- `off` / `on` commands to detach and re-attach the built-in display
- A background watcher (launch agent) that keeps it off whenever an external display is attached
- Fail-safe: it re-enables the built-in display when the last external display disappears, so you
  are never left with no screen
- Session-scoped: the change lasts until logout or reboot, nothing is written to disk or NVRAM

## Requirements

- A MacBook running macOS 12 or later (the package's minimum target). It has only been tested on
  macOS 27.2 with an M1 Pro; other versions and Intel Macs are untested.
- Swift toolchain (Xcode or the Command Line Tools) to build it
- [just](https://github.com/casey/just) for the install recipes (`brew install just`). Without it you can
  run `./scripts/install.sh` directly.

## Install

```sh
git clone <this repo> && cd builtin-display
just install
```

`just install` builds a release binary, installs it to `~/.local/bin/builtin-display`, and loads a
launch agent (`com.local.builtin-display`) that starts at every login. Use `PREFIX=/some/dir just install`
to install somewhere else. Make sure `~/.local/bin` is on your `PATH` if you want to run the tool by name.

To remove everything (this also re-enables the built-in display first):

```sh
just uninstall
```

## Usage

```
builtin-display list    show online displays
builtin-display off     disable the built-in display (needs an external display)
builtin-display on      re-enable the built-in display
builtin-display state   print "external=<n> builtin=<0|1>"
builtin-display watch   keep the built-in off while an external display is attached
```

With the launch agent installed you normally never run these by hand. `off` refuses to run when no
external display is online.

Logs are in `~/Library/Logs/builtin-display.log`.

### Temporarily turn the built-in display back on

The agent switches the built-in off again within a couple of seconds, so stop it first:

```sh
launchctl bootout gui/$(id -u)/com.local.builtin-display
builtin-display on
```

Start it again with `just install`.

## How it works

- **Detach:** `CGSConfigureDisplayEnabled` (a private API) is queued inside a normal
  `CGBeginDisplayConfiguration` transaction and applied with `kCGConfigureForSession`. If the
  display is mirrored, it leaves the mirror set first.
- **Re-attach:** a detached display disappears from `CGGetOnlineDisplayList`, so `on` finds it
  through the private `CGSGetDisplayList`.
- **Watch:** the watcher polls every 2 seconds. It disables the built-in when an external display is
  present, and re-enables it after two consecutive polls with no external display, so a brief
  monitor power-cycle doesn't flip it on.
- **Why each poll runs a child process:** a long-lived command-line process never receives
  WindowServer display updates. Reconfiguration callbacks don't fire and the display list goes
  stale after the first call. Each poll therefore re-runs the same binary (`builtin-display state`),
  which always sees the real state.

```
Sources/builtin-display/
  main.swift          command-line entry point
  Displays.swift      listing, enabling and disabling displays
  Watcher.swift       the polling loop used by `watch`
  PrivateAPI.swift    the private CoreGraphics declarations
launchd/              launch agent template
scripts/              install / uninstall
```

## Remote access with no screen

SSH and Screen Sharing keep working with the monitor off, as long as the Mac stays awake:

- Enable Remote Login (SSH) and/or Screen Sharing in System Settings → General → Sharing.
- Stop the Mac sleeping while plugged in: `sudo pmset -c sleep 0`. The macOS default of a few
  minutes of idle sleep will drop your remote connection.
- If the external monitor goes away, the watcher re-enables the built-in display, which gives Screen
  Sharing a screen to show.

## Recovery

If you end up with no picture on any display, connect over SSH and run `builtin-display on`. If that
doesn't help, reboot: the change is session-scoped, so the built-in display comes back.

## Caveats

- This relies on private, undocumented APIs. A macOS update can break it. It is not App Store safe.
- The re-enable path when a monitor is unplugged has not been exercised on every setup. Test it once:
  unplug the monitor's cable, wait about 5 seconds, and the built-in display should come back.
- Docks, KVMs or virtual displays that register as external displays count as "external" for the
  watcher's purposes.
