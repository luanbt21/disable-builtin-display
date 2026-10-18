import CoreGraphics

/// Snapshot of what is attached, as seen by the current process.
struct DisplayState {
    var externalCount: Int
    var builtinOnline: Bool

    static func current() -> DisplayState {
        let ids = Displays.online()
        return DisplayState(
            externalCount: ids.filter { !Displays.isBuiltin($0) }.count,
            builtinOnline: ids.contains(where: Displays.isBuiltin)
        )
    }

    /// Parses the output of `description`, e.g. "external=1 builtin=0".
    init?(parsing text: String) {
        var external: Int?
        var builtin: Int?
        for field in text.split(separator: " ") {
            let parts = field.split(separator: "=")
            guard parts.count == 2, let value = Int(parts[1]) else { continue }
            if parts[0] == "external" { external = value }
            if parts[0] == "builtin" { builtin = value }
        }
        guard let external, let builtin else { return nil }
        self.init(externalCount: external, builtinOnline: builtin == 1)
    }

    init(externalCount: Int, builtinOnline: Bool) {
        self.externalCount = externalCount
        self.builtinOnline = builtinOnline
    }

    var description: String { "external=\(externalCount) builtin=\(builtinOnline ? 1 : 0)" }
}

enum Displays {
    /// Displays that are currently online (a disabled display is not in this list).
    static func online() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &ids, &count)
        return Array(ids.prefix(Int(count)))
    }

    /// `CGDisplayIsBuiltin` returns -1 for IDs that don't exist, so compare against 1 exactly.
    static func isBuiltin(_ id: CGDirectDisplayID) -> Bool {
        CGDisplayIsBuiltin(id) == 1
    }

    static func describe(_ id: CGDirectDisplayID) -> String {
        let bounds = CGDisplayBounds(id)
        return "id=\(id) builtin=\(isBuiltin(id)) main=\(CGDisplayIsMain(id) != 0) "
            + "active=\(CGDisplayIsActive(id) != 0) mirrored=\(CGDisplayIsInMirrorSet(id) != 0) "
            + "\(Int(bounds.width))x\(Int(bounds.height))"
    }

    /// Detaches the built-in display. Refuses (returns false) if no external display is online.
    static func disableBuiltin() -> Bool {
        let ids = online()
        guard let builtin = ids.first(where: isBuiltin), ids.contains(where: { !isBuiltin($0) }) else {
            return false
        }
        return setEnabled(builtin, false)
    }

    /// Re-attaches the built-in display, even though it is no longer in the online list.
    static func enableBuiltin() -> Bool {
        var known = [CGDirectDisplayID](repeating: 0, count: 32)
        var count: UInt32 = 0
        _ = CGSGetDisplayList(UInt32(known.count), &known, &count)
        guard let builtin = (online() + known.prefix(Int(count))).first(where: isBuiltin) else {
            return false
        }
        return setEnabled(builtin, true)
    }

    /// Applies the change for this login session only; `.forSession` means a reboot restores it.
    private static func setEnabled(_ id: CGDirectDisplayID, _ enabled: Bool) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return false }
        // Leave any mirror set first, otherwise the built-in stays tied to the external.
        if !enabled { CGConfigureDisplayMirrorOfDisplay(config, id, kCGNullDirectDisplay) }
        guard CGSConfigureDisplayEnabled(config, id, enabled) == .success else {
            CGCancelDisplayConfiguration(config)
            return false
        }
        return CGCompleteDisplayConfiguration(config, .forSession) == .success
    }
}
