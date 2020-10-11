// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

/**
 * Holds and manages an array of GamePad objects.
 * Up to five gamepads are managed. The first three gamepads are initialized
 * by default and represent a mouse and two keyboard emulated joysticks.
 * All remaining gamepads are added dynamically when HID devices are connected.
 */
class GamePadManager {

    /// Reference to the the controller
    var parent: MyController!
    
    /// Reference to the HID manager
    var hidManager: IOHIDManager

    // private let inputLock = NSLock()
    // Such a thing is used here: TODO: Check if we need this
    // https://github.com/joekarl/swift_handmade_hero/blob/master/Handmade%20Hero%20OSX/Handmade%20Hero%20OSX/InputManager.swift
    
    /// Gamepad storage
    var gamePads: [Int: GamePad] = [:]
    
    //
    // MARK: - Initialization
    //
    
    init(parent: MyController) {
    
        self.parent = parent
      
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault,
                                        IOOptionBits(kIOHIDOptionsTypeNone))

        // Add default devices
        gamePads[0] = GamePad(manager: self, type: .CPD_MOUSE)
        gamePads[0]!.name = "Mouse"
        gamePads[0]!.setIcon(name: "devMouseTemplate")
        gamePads[0]!.keyMap = 0
        
        gamePads[1] = GamePad(manager: self, type: .CPD_JOYSTICK)
        gamePads[1]!.name = "Joystick Keyset 1"
        gamePads[1]!.setIcon(name: "devKeys1Template")
        gamePads[1]!.keyMap = 1

        gamePads[2] = GamePad(manager: self, type: .CPD_JOYSTICK)
        gamePads[2]!.name = "Joystick Keyset 2"
        gamePads[2]!.setIcon(name: "devKeys2Template")
        gamePads[2]!.keyMap = 2

        // Tell the mouse event receiver where the mouse resides
        parent.metal.mouse1 = gamePads[0]!
                
        // Prepare to accept HID devices
        let deviceCriteria = [
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_Joystick
            ],
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad
            ],
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_MultiAxisController
            ],
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse
            ]
        ]
                
        // Declare bridging closures (bridge between Swift methods and C callbacks)
        let matchingCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, device in
            let this: GamePadManager = unsafeBitCast(inContext, to: GamePadManager.self)
            this.hidDeviceAdded(context: inContext, result: inResult, sender: inSender, device: device)
        }
        
        let removalCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, device in
            let this: GamePadManager = unsafeBitCast(inContext, to: GamePadManager.self)
            this.hidDeviceRemoved(context: inContext, result: inResult, sender: inSender, device: device)
        }
        
        // Configure the HID manager
        let hidContext = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, deviceCriteria as CFArray)
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, matchingCallback, hidContext)
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, removalCallback, hidContext)
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    func shutDown() {

        track()
        
        // Terminate communication with all connected HID devices
        for (_, pad) in gamePads { pad.close() }

        // Close the HID manager
        IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))

        // Free all slots
        gamePads = [:]
    }

    deinit {

        track()
    }
        
    //
    // MARK: - Managing slots
    //
    
    /// Returns true iff the specified game pad slot is used or free
    func isUsed(slot: Int) -> Bool { return gamePads[slot] != nil }
    func isEmpty(slot: Int) -> Bool { return gamePads[slot] == nil }
    
    /// Returns the lowest free slot number or nil if all slots are occupied
    func findFreeSlot() -> Int? {
        
        var nr = 0
        while !isEmpty(slot: nr) { nr += 1 }
        
        // We support up to 5 devices
        return (nr < 5) ? nr : nil
    }
    
    func connect(slot: Int, port: Int) {
        
        // Remove any existing binding to this port
        for (_, pad) in gamePads where pad.port == port { pad.port = 0 }
        
        // Bind the new device
        gamePads[slot]?.port = port
        
        // Update the device type on the Amiga side
        parent.amiga.suspend()
        let deviceType = gamePads[slot]?.type ?? .CPD_NONE
        if port == 1 { parent.amiga.controlPort1.connect(deviceType) }
        if port == 2 { parent.amiga.controlPort2.connect(deviceType) }
        parent.amiga.resume()
    }

    func getName(slot: Int) -> String {
        
        if let name = gamePads[slot]?.name {
            return name
        } else {
            return "USB device"
        }
    }

    func getIcon(slot: Int) -> NSImage {
        
        if let icon = gamePads[slot]?.icon {
            return icon
        } else if gamePads[slot]?.isMouse == true {
            return NSImage.init(named: "devMouseTemplate")!
        } else {
            return NSImage.init(named: "devGamepad1Template")!
        }
    }

    func getSlot(port: Int) -> Int {
        
        var result = InputDevice.none
        
        for (slot, pad) in gamePads where pad.port == port {
            assert(result == InputDevice.none)
            result = slot
        }
        
        return result
    }
        
    //
    // MARK: - HID stuff
    //
    
    func isBuiltIn(device: IOHIDDevice) -> Bool {
        
        let key = kIOHIDBuiltInKey as CFString
        
        if let value = IOHIDDeviceGetProperty(device, key) as? Int {
            return value != 0
        } else {
            return false
        }
    }

    /// Device matching callback
    /// This method is invoked when a matching HID device is plugged in.
    func hidDeviceAdded(context: UnsafeMutableRawPointer?,
                        result: IOReturn,
                        sender: UnsafeMutableRawPointer?,
                        device: IOHIDDevice) {
    
        track()
        
        // Ignore internal devices
        if isBuiltIn(device: device) { return }
        
        // Find a free slot for the new device
        guard let slot = findFreeSlot() else {
            track("Maximum number of devices reached. Ignoring device")
            return
        }
        
        // Collect device properties
        let vendorIDKey = kIOHIDVendorIDKey as CFString
        let productIDKey = kIOHIDProductIDKey as CFString
        let locationIDKey = kIOHIDLocationIDKey as CFString

        var vendorID = 0
        var productID = 0
        var locationID = 0
        
        if let value = IOHIDDeviceGetProperty(device, vendorIDKey) as? Int {
            vendorID = value
        }
        if let value = IOHIDDeviceGetProperty(device, productIDKey) as? Int {
            productID = value
        }
        if let value = IOHIDDeviceGetProperty(device, locationIDKey) as? Int {
            locationID = value
        }
        
        track("    slotNr = \(slot)")
        track("  vendorID = \(vendorID)")
        track(" productID = \(productID)")
        track("locationID = \(locationID)")

        // Add device
        if device.isMouse() {
            addMouse(slot: slot, device: device,
                     vendorID: vendorID, productID: productID, locationID: locationID)
        } else {
            addJoystick(slot: slot, device: device,
                        vendorID: vendorID, productID: productID, locationID: locationID)
        }
        
        // Update to toolbar
        parent.toolbar.validateVisibleItems()
        listDevices()
    }
    
    func addJoystick(slot: Int,
                     device: IOHIDDevice,
                     vendorID: Int,
                     productID: Int,
                     locationID: Int) {
        
        // Open device
        let optionBits = kIOHIDOptionsTypeNone // kIOHIDOptionsTypeSeizeDevice
        let status = IOHIDDeviceOpen(device, IOOptionBits(optionBits))
        if status != kIOReturnSuccess {
            track("WARNING: Cannot open HID device")
            return
        }
        
        // Create a GamePad object
        gamePads[slot] = GamePad(manager: self,
                                 device: device,
                                 type: .CPD_JOYSTICK,
                                 vendorID: vendorID,
                                 productID: productID,
                                 locationID: locationID)
        
        // Register input value callback
        let hidContext = unsafeBitCast(gamePads[slot], to: UnsafeMutableRawPointer.self)
        IOHIDDeviceRegisterInputValueCallback(device,
                                              gamePads[slot]!.inputValueCallback,
                                              hidContext)
    }
    
    func addMouse(slot: Int,
                  device: IOHIDDevice,
                  vendorID: Int,
                  productID: Int,
                  locationID: Int) {
                
        // Create a GamePad object
        gamePads[slot] = GamePad(manager: self,
                                 device: device,
                                 type: .CPD_MOUSE,
                                 vendorID: vendorID,
                                 productID: productID,
                                 locationID: locationID)
        
        // Inform the mouse event receiver about the new mouse
        parent.metal.mouse2 = gamePads[slot]
    }
    
    func hidDeviceRemoved(context: UnsafeMutableRawPointer?,
                          result: IOReturn,
                          sender: UnsafeMutableRawPointer?,
                          device: IOHIDDevice) {
        
        track()
    
        let locationIDKey = kIOHIDLocationIDKey as CFString
        var locationID = 0
        if let value = IOHIDDeviceGetProperty(device, locationIDKey) as? Int {
            locationID = value
        }
                
        // Search for a matching locationID and remove device
        for (slotNr, device) in gamePads where device.locationID == locationID {
            gamePads[slotNr] = nil
            track("Clearing slot \(slotNr)")
        }
                
        // Inform the controller about the new device
        parent.toolbar.validateVisibleItems()
        
        listDevices()
    }
    
    func listDevices() {
        
        print("Input devices:")
        for i in 0 ... Int.max {
            
            guard let dev = gamePads[i] else { break }
            
            print("Slot \(i) [\(dev.port)]: ", terminator: "")
            if let name = dev.name {
                print("\(name) (\(dev.vendorID), \(dev.productID), \(dev.locationID))", terminator: "")
            } else {
                print("Placeholder device", terminator: "")
            }
            print(dev.isMouse ? " (Mouse)" : "")
        }
    }
    
    func refresh(popup: NSPopUpButton, hide: Bool = false) {
        
        let slots = [
            InputDevice.mouse,
            InputDevice.keyset1,
            InputDevice.keyset2,
            InputDevice.joystick1,
            InputDevice.joystick2
        ]
                
        for s in slots {
            if let item = popup.menu?.item(withTag: s) {
                item.title = getName(slot: s)
                item.image = getIcon(slot: s)
                item.isEnabled = isUsed(slot: s)
                item.isHidden = isEmpty(slot: s) && hide
            }
        }
    }
}

extension IOHIDDevice {
    
    func isMouse() -> Bool {
        
        let key = kIOHIDPrimaryUsageKey as CFString
        
        if let value = IOHIDDeviceGetProperty(self, key) as? Int {
            return value == kHIDUsage_GD_Mouse
        } else {
            return false
        }
    }
    
    func listProperties() {
        
        let keys = [kIOHIDTransportKey, kIOHIDVendorIDKey, kIOHIDVendorIDSourceKey, kIOHIDProductIDKey, kIOHIDVersionNumberKey, kIOHIDManufacturerKey, kIOHIDProductKey, kIOHIDSerialNumberKey, kIOHIDCountryCodeKey, kIOHIDStandardTypeKey, kIOHIDLocationIDKey, kIOHIDDeviceUsageKey, kIOHIDDeviceUsagePageKey, kIOHIDDeviceUsagePairsKey, kIOHIDPrimaryUsageKey, kIOHIDPrimaryUsagePageKey, kIOHIDMaxInputReportSizeKey, kIOHIDMaxOutputReportSizeKey, kIOHIDMaxFeatureReportSizeKey, kIOHIDReportIntervalKey, kIOHIDSampleIntervalKey, kIOHIDBatchIntervalKey, kIOHIDRequestTimeoutKey, kIOHIDReportDescriptorKey, kIOHIDResetKey, kIOHIDKeyboardLanguageKey, kIOHIDAltHandlerIdKey, kIOHIDBuiltInKey, kIOHIDDisplayIntegratedKey, kIOHIDProductIDMaskKey, kIOHIDProductIDArrayKey, kIOHIDPowerOnDelayNSKey, kIOHIDCategoryKey, kIOHIDMaxResponseLatencyKey, kIOHIDUniqueIDKey, kIOHIDPhysicalDeviceUniqueIDKey]
        
        for key in keys {
            if let prop = IOHIDDeviceGetProperty(self, key as CFString) {
                print("\t" + key + ": \(prop)")
            }
        }
    }
}
