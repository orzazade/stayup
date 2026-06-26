import CoreGraphics

/// Performs the net-zero activity nudge: posts two synthetic mouse-move events
/// (one pixel out, then back) to the HID event tap. This resets the combined
/// session idle counter that Teams/Slack read, so you stay Available — without
/// the cursor visibly moving. No `cliclick`, no dependency; pure CoreGraphics.
///
/// Note: requires Accessibility (TCC) permission to post to `.cghidEventTap`.
enum ActivityInjector {
    static func nudge() {
        let source = CGEventSource(stateID: .combinedSessionState)
        // Current cursor position in CG (top-left origin) coordinates.
        let origin = CGEvent(source: nil)?.location ?? .zero
        let bumped = CGPoint(x: origin.x + 1, y: origin.y)

        // Two distinct positions — a same-location move can be de-duped and
        // would not reset the idle counter.
        CGEvent(mouseEventSource: source,
                mouseType: .mouseMoved,
                mouseCursorPosition: bumped,
                mouseButton: .left)?
            .post(tap: .cghidEventTap)

        CGEvent(mouseEventSource: source,
                mouseType: .mouseMoved,
                mouseCursorPosition: origin,
                mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }
}
