import Foundation

/// Keeps the built-in display disabled while an external one is attached, and brings it back
/// when the last external display goes away so the Mac is never left without a screen.
///
/// A long-lived command-line process never receives WindowServer display updates: reconfiguration
/// callbacks don't fire and `CGGetOnlineDisplayList` goes stale. So every poll runs this same
/// binary again as a short-lived child, which always sees the real state.
final class Watcher {
    private let pollInterval: TimeInterval = 2
    /// Consecutive polls without an external display before the built-in is re-enabled, so a
    /// brief monitor power-cycle doesn't flip it on and rearrange windows.
    private let missesBeforeReenable = 2
    private var externalMissingPolls = 0

    func run() {
        log("watching display changes (polling every \(Int(pollInterval))s)")
        reconcile()
        Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [self] _ in reconcile() }
        RunLoop.main.run()
    }

    /// External present -> built-in off; no external -> built-in on. Idempotent.
    private func reconcile() {
        guard let state = DisplayState(parsing: child(["state"])) else { return }
        externalMissingPolls = state.externalCount > 0 ? 0 : externalMissingPolls + 1

        if state.externalCount > 0 && state.builtinOnline {
            log("external attached: " + child(["off"]))
        } else if state.externalCount == 0 && !state.builtinOnline && externalMissingPolls >= missesBeforeReenable {
            log("no external display: " + child(["on"]))
        }
    }

    private func child(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Bundle.main.executablePath ?? CommandLine.arguments[0])
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        do { try process.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func log(_ message: String) {
        print(message)
        fflush(stdout)
    }
}
