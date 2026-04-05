import Carbon.HIToolbox

// File-scope storage accessible from the @convention(c) event handler
private var hotkeyCallbacks: [UInt32: () -> Void] = [:]
private var hotkeyRefs: [EventHotKeyRef] = []
private var nextID: UInt32 = 1

// Carbon event handler — must be a plain C function, so it lives at file scope.
private let carbonEventHandler: EventHandlerUPP = { _, event, _ -> OSStatus in
    var hkID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    hotkeyCallbacks[hkID.id]?()
    return noErr
}

// Four-char signature: 'WMGR'
private let kSignature: OSType = 0x574D4752

final class HotKeyManager {
    static let shared = HotKeyManager()

    private init() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonEventHandler,
            1, &spec,
            nil, nil
        )
    }

    // MARK: - Registration

    /// Register a single hotkey.  `keyCode` is a Carbon kVK_* constant.
    /// `modifiers` uses Carbon modifier flags (controlKey | optionKey etc.).
    func register(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        let id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: kSignature, id: id)

        let status = RegisterEventHotKey(
            keyCode, modifiers, hkID,
            GetApplicationEventTarget(),
            0, &ref
        )

        if status == noErr, let ref {
            hotkeyRefs.append(ref)
            hotkeyCallbacks[id] = action
        }
    }

    // MARK: - Magnet default bindings

    func registerAll() {
        // ⌃⌥  (Control + Option)
        let co  = UInt32(controlKey | optionKey)
        // ⌃⌥⇧ (Control + Option + Shift)
        let cos = UInt32(controlKey | optionKey | shiftKey)

        // ── Halves ──────────────────────────────────────────────────────────
        register(keyCode: UInt32(kVK_LeftArrow),  modifiers: co)  { WindowMover.moveFrontmost(to: .leftHalf) }
        register(keyCode: UInt32(kVK_RightArrow), modifiers: co)  { WindowMover.moveFrontmost(to: .rightHalf) }
        register(keyCode: UInt32(kVK_UpArrow),    modifiers: co)  { WindowMover.moveFrontmost(to: .topHalf) }
        register(keyCode: UInt32(kVK_DownArrow),  modifiers: co)  { WindowMover.moveFrontmost(to: .bottomHalf) }

        // ── Fullscreen ───────────────────────────────────────────────────────
        register(keyCode: UInt32(kVK_Return),     modifiers: co)  { WindowMover.moveFrontmost(to: .maximize) }

        // ── Quarters ─────────────────────────────────────────────────────────
        //   U = top-left   I = top-right
        //   J = bot-left   K = bot-right
        register(keyCode: UInt32(kVK_ANSI_U), modifiers: co) { WindowMover.moveFrontmost(to: .topLeft) }
        register(keyCode: UInt32(kVK_ANSI_I), modifiers: co) { WindowMover.moveFrontmost(to: .topRight) }
        register(keyCode: UInt32(kVK_ANSI_J), modifiers: co) { WindowMover.moveFrontmost(to: .bottomLeft) }
        register(keyCode: UInt32(kVK_ANSI_K), modifiers: co) { WindowMover.moveFrontmost(to: .bottomRight) }

        // ── Thirds ───────────────────────────────────────────────────────────
        register(keyCode: UInt32(kVK_ANSI_D), modifiers: co) { WindowMover.moveFrontmost(to: .leftThird) }
        register(keyCode: UInt32(kVK_ANSI_F), modifiers: co) { WindowMover.moveFrontmost(to: .centerThird) }
        register(keyCode: UInt32(kVK_ANSI_G), modifiers: co) { WindowMover.moveFrontmost(to: .rightThird) }

        // ── Two-thirds ───────────────────────────────────────────────────────
        register(keyCode: UInt32(kVK_ANSI_E), modifiers: co) { WindowMover.moveFrontmost(to: .leftTwoThirds) }
        register(keyCode: UInt32(kVK_ANSI_T), modifiers: co) { WindowMover.moveFrontmost(to: .rightTwoThirds) }

        // ── Multi-display ────────────────────────────────────────────────────
        register(keyCode: UInt32(kVK_RightArrow), modifiers: cos) { WindowMover.moveFrontmost(to: .nextDisplay) }
        register(keyCode: UInt32(kVK_LeftArrow),  modifiers: cos) { WindowMover.moveFrontmost(to: .previousDisplay) }
    }
}
