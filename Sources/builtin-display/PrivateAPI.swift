import CoreGraphics

// Private CoreGraphics (SkyLight) symbols. They are not in any public header, so they are
// bound by name. They may change or disappear in a future macOS release.

/// Queues "attach/detach this display" inside a CGDisplayConfigRef transaction.
@_silgen_name("CGSConfigureDisplayEnabled")
func CGSConfigureDisplayEnabled(_ config: CGDisplayConfigRef?, _ display: CGDirectDisplayID, _ enabled: Bool) -> CGError

/// Lists every display the WindowServer knows about, including detached ones.
/// (`CGGetOnlineDisplayList` drops a display once it is disabled.)
@_silgen_name("CGSGetDisplayList")
func CGSGetDisplayList(_ max: UInt32, _ list: UnsafeMutablePointer<CGDirectDisplayID>?, _ count: UnsafeMutablePointer<UInt32>?) -> CGError
