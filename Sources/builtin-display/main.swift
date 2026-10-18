import Foundation

let usage = """
usage: builtin-display <command>

  list    show online displays
  off     disable the built-in display (needs an external display; lasts until logout/reboot)
  on      re-enable the built-in display
  state   print "external=<n> builtin=<0|1>"
  watch   keep the built-in off while an external display is attached (run by the launch agent)
"""

switch CommandLine.arguments.dropFirst().first ?? "list" {
case "list":
    Displays.online().forEach { print(Displays.describe($0)) }

case "off":
    let state = DisplayState.current()
    guard state.builtinOnline else { print("built-in display is not online"); exit(1) }
    guard state.externalCount > 0 else {
        print("refusing: no external display online, you would have no screen")
        exit(1)
    }
    print(Displays.disableBuiltin() ? "built-in display disabled" : "failed to disable built-in display")

case "on":
    guard !DisplayState.current().builtinOnline else { print("built-in display already enabled"); exit(0) }
    print(Displays.enableBuiltin() ? "built-in display enabled" : "built-in display not found; log out and in to restore")

case "state":
    print(DisplayState.current().description)

case "watch":
    Watcher().run()

default:
    print(usage)
    exit(2)
}
