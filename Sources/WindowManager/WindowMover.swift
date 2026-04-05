import AppKit

enum WindowMover {
    // MARK: - Public

    static func moveFrontmost(to position: SnapPosition) {
        guard let window = focusedWindow() else { return }

        switch position {
        case .nextDisplay:
            moveToAdjacentDisplay(window, forward: true)
        case .previousDisplay:
            moveToAdjacentDisplay(window, forward: false)
        default:
            let screen = ScreenUtils.screen(containing: window)
            if let frame = ScreenUtils.axFrame(for: position, on: screen) {
                setFrame(of: window, to: frame)
            }
        }
    }

    // MARK: - Private

    private static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &ref) == .success,
              let ref else { return nil }
        return (ref as! AXUIElement)
    }

    private static func setFrame(of window: AXUIElement, to frame: CGRect) {
        var origin = frame.origin
        var size   = frame.size

        if let posValue  = AXValueCreate(.cgPoint, &origin) {
            _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
        if let sizeValue = AXValueCreate(.cgSize,  &size) {
            _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    private static func moveToAdjacentDisplay(_ window: AXUIElement, forward: Bool) {
        let currentScreen = ScreenUtils.screen(containing: window)
        let targetScreen  = forward
            ? ScreenUtils.nextScreen(after: currentScreen)
            : ScreenUtils.previousScreen(before: currentScreen)

        guard targetScreen != currentScreen else { return }

        // Read current position and size
        var posRef:  CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)  == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute    as CFString, &sizeRef) == .success,
              let posRef, let sizeRef
        else { return }

        var axPos  = CGPoint.zero
        var axSize = CGSize.zero
        AXValueGetValue(posRef  as! AXValue, .cgPoint, &axPos)
        AXValueGetValue(sizeRef as! AXValue, .cgSize,  &axSize)

        let mainH = NSScreen.screens[0].frame.height

        // Relative position of the window within the current screen's visible frame
        // (working in NSScreen bottom-left coords for clarity)
        let src = currentScreen.visibleFrame
        let dst = targetScreen.visibleFrame

        let nsWindowY = mainH - axPos.y - axSize.height   // convert AX → NS y
        let relX = (axPos.x      - src.minX) / src.width
        let relY = (nsWindowY    - src.minY) / src.height

        let newNsX = dst.minX + relX * dst.width
        let newNsY = dst.minY + relY * dst.height
        let newAxY = mainH - newNsY - axSize.height

        var newOrigin = CGPoint(x: newNsX, y: newAxY)
        if let posValue = AXValueCreate(.cgPoint, &newOrigin) {
            _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
    }
}
