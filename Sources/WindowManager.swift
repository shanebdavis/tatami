import AppKit
import ApplicationServices

/// Wraps the Accessibility (AX) API: finding the focused window of the
/// frontmost app and moving/resizing it.
///
/// Coordinate systems: the AX API uses top-left-origin global coordinates
/// (y grows downward from the top of the primary screen), while AppKit uses
/// bottom-left-origin (y grows upward). All public methods here speak AppKit
/// (Cocoa) coordinates; conversion happens at the AX boundary.
@MainActor
enum WindowManager {

    // MARK: - Accessibility permission

    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt directing the user to System Settings →
    /// Privacy & Security → Accessibility. Safe to call repeatedly.
    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        // Literal value of kAXTrustedCheckOptionPrompt; the global constant
        // itself isn't concurrency-safe under Swift 6.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    // MARK: - Focused window

    /// The focused window of the frontmost app. Our app never activates
    /// (LSUIElement + non-activating panels), so the frontmost app is the
    /// one the user is working in.
    static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXFocusedWindowAttribute as CFString, &value
        )
        guard result == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }

    /// Frame of a window in Cocoa coordinates, or nil if unreadable.
    static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        else { return nil }

        return cocoaRect(fromAX: CGRect(origin: position, size: size))
    }

    /// Moves/resizes a window to `frame` (Cocoa coordinates).
    static func setFrame(_ frame: CGRect, of window: AXUIElement) {
        let axFrame = axRect(fromCocoa: frame)
        var position = axFrame.origin
        var size = axFrame.size

        // Size first, then position, then size again: apps with minimum
        // sizes or self-managed layouts (Electron, some pro apps) can clamp
        // one attribute based on the other; the second size set wins.
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    // MARK: - Screens

    /// The screen containing (the largest part of) `frame`, in Cocoa coords.
    static func screen(containing frame: CGRect) -> NSScreen? {
        NSScreen.screens.max { a, b in
            a.frame.intersection(frame).area < b.frame.intersection(frame).area
        }
    }

    // MARK: - Coordinate conversion

    /// AX coordinates share the x-axis with Cocoa; y is flipped relative to
    /// the top of the primary screen (the screen whose Cocoa origin is 0,0).
    private static var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }

    static func axRect(fromCocoa rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryScreenHeight - rect.maxY,
               width: rect.width, height: rect.height)
    }

    static func cocoaRect(fromAX rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryScreenHeight - rect.maxY,
               width: rect.width, height: rect.height)
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
