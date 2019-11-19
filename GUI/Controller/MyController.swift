// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

enum WarpMode {

    case auto
    case on
    case off
}

protocol MessageReceiver {
    func processMessage(_ msg: Message)
}

class MyController: NSWindowController, MessageReceiver {

    // Proxy
    // Implements a bridge between the emulator written in C++ and the
    // GUI written in Swift. Because Swift cannot interact with C++ directly,
    // the proxy is written in Objective-C.
    var amiga: AmigaProxy!

    // Preferences controller
    var preferencesController: PreferencesController?

    // Audio Engine
    var audioEngine: AudioEngine!
    
    // Game pad manager
    var gamePadManager: GamePadManager!
    
    // Keyboard controller
    var keyboardcontroller: KeyboardController!

    // Virtual keyboard (opened as a sheet) and it's visual appearance
    var virtualKeyboardSheet: VirtualKeyboardController?
    
    // Loop timer
    // The timer fires 60 times a second and executes all tasks that need to be
    //  done perdiodically (e.g., updating the speedometer and the debug panels)
    var timer: Timer?
    
    // Timer lock
    var timerLock: NSLock!
    
    // Speedometer to measure clock frequence and frames per second
    var speedometer: Speedometer!
    
    // Used inside the timer function to fine tune timed events
    var animationCounter = 0
        
    // Current mouse coordinate
    var mouseXY = NSPoint(x: 0, y: 0)
    
    // Indicates if mouse is currently hidden DEPRECATED
    var hideMouse = false

    // Indicates if a status bar is shown
    var statusBar = true

    // Small disk icon to be shown in NSMenuItems
    var smallDisk = NSImage.init(named: "diskTemplate")!.resize(width: 16.0, height: 16.0)
    
    // Drive that receives drag and drop inputs
    var dragAndDropDrive: DriveProxy?

    // Serial input and output
    var serialIn = ""
    var serialOut = ""

    // Warp mode
    var warpMode = WarpMode.auto { didSet { updateWarp() } }

    //
    // Preferences items
    //
    
    // General
    
    // Selected game pad slot for joystick in port A
    var inputDevice1 = Defaults.inputDevice1
    
    // Selected game pad slot for joystick in port B
    var inputDevice2 = Defaults.inputDevice2

    // Rom preferences
    
    // Rom URLs
    var romURL: URL = Defaults.rom
    var extURL: URL = Defaults.ext

    // Devices preferences
    var disconnectJoyKeys: Bool {
        get { return keyboardcontroller.disconnectJoyKeys }
        set {
            keyboardcontroller.disconnectJoyKeys = newValue
        }
    }
    var autofire: Bool {
        get { return amiga.joystick1.autofire }
        set {
            amiga.joystick1.autofire = newValue
            amiga.joystick2.autofire = newValue
        }
    }
    var autofireBullets: Int {
        get { return amiga.joystick1.autofireBullets }
        set {
            amiga.joystick1.autofireBullets = newValue
            amiga.joystick2.autofireBullets = newValue
        }
    }
    var autofireFrequency: Float {
        get { return amiga.joystick1.autofireFrequency }
        set {
            amiga.joystick1.autofireFrequency = newValue
            amiga.joystick2.autofireFrequency = newValue
        }
    }
    var keyMap0: [MacKey: UInt32]? {
        get { return gamePadManager.gamePads[0]?.keyMap }
        set { gamePadManager.gamePads[0]?.keyMap = newValue }
    }
    var keyMap1: [MacKey: UInt32]? {
        get { return gamePadManager.gamePads[1]?.keyMap }
        set { gamePadManager.gamePads[1]?.keyMap = newValue }
    }
 
    // Video preferences
 
    var enhancer: Int {
        get { return metal.enhancer }
        set { metal.enhancer = newValue }
    }
    var upscaler: Int {
        get { return metal.upscaler }
        set { metal.upscaler = newValue }
    }
    var palette: Int {
        get { return Int(amiga.denise.palette()) }
        set { amiga.denise.setPalette(Palette(newValue)) }
    }
    var brightness: Double {
        get { return amiga.denise.brightness() }
        set { amiga.denise.setBrightness(newValue) }
    }
    var contrast: Double {
        get { return amiga.denise.contrast() }
        set { amiga.denise.setContrast(newValue) }
    }
    var saturation: Double {
        get { return amiga.denise.saturation() }
        set { amiga.denise.setSaturation(newValue) }
    }
    var eyeX: Float = 0.0 {
        didSet { metal.buildMatrices3D() }
    }
    var eyeY: Float = 0.0 {
        didSet { metal.buildMatrices3D() }
    }
    var eyeZ: Float = 0.0 {
        didSet { metal.buildMatrices3D() }
    }
    /*
    var eyeX: Float {
        get { return metal.getEyeX() }
        set { metal.setEyeX(newValue) }
    }
    var eyeY: Float {
        get { return metal.getEyeY() }
        set { metal.setEyeY(newValue) }
    }
    var eyeZ: Float {
        get { return metal.getEyeZ() }
        set { metal.setEyeZ(newValue) }
    }
    */
    var blur: Int32 {
        get { return metal.shaderOptions.blur }
        set { metal.shaderOptions.blur = newValue }
    }
    var blurRadius: Float {
        get { return metal.shaderOptions.blurRadius }
        set { metal.shaderOptions.blurRadius = newValue }
    }
    var bloom: Int32 {
        get { return metal.shaderOptions.bloom }
        set { metal.shaderOptions.bloom = newValue }
    }
    var bloomRadius: Float {
        get { return metal.shaderOptions.bloomRadius }
        set { metal.shaderOptions.bloomRadius = newValue }
    }
    var bloomBrightness: Float {
        get { return metal.shaderOptions.bloomBrightness }
        set { metal.shaderOptions.bloomBrightness = newValue }
    }
    var bloomWeight: Float {
        get { return metal.shaderOptions.bloomWeight }
        set { metal.shaderOptions.bloomWeight = newValue }
    }
    var flicker: Int32 {
        get { return metal.shaderOptions.flicker }
        set { metal.shaderOptions.flicker = newValue }
    }
    var flickerWeight: Float {
        get { return metal.shaderOptions.flickerWeight }
        set { metal.shaderOptions.flickerWeight = newValue }
    }
    var dotMask: Int32 {
        get { return metal.shaderOptions.dotMask }
        set { metal.shaderOptions.dotMask = newValue }
    }
    var dotMaskBrightness: Float {
        get { return metal.shaderOptions.dotMaskBrightness }
        set { metal.shaderOptions.dotMaskBrightness = newValue }
    }
    var scanlines: Int32 {
        get { return metal.shaderOptions.scanlines }
        set { metal.shaderOptions.scanlines = newValue }
    }
    var scanlineBrightness: Float {
        get { return metal.shaderOptions.scanlineBrightness }
        set { metal.shaderOptions.scanlineBrightness = newValue }
    }
    var scanlineWeight: Float {
        get { return metal.shaderOptions.scanlineWeight }
        set { metal.shaderOptions.scanlineWeight = newValue }
    }
    var disalignment: Int32 {
        get { return metal.shaderOptions.disalignment }
        set { metal.shaderOptions.disalignment = newValue }
    }
    var disalignmentH: Float {
        get { return metal.shaderOptions.disalignmentH }
        set { metal.shaderOptions.disalignmentH = newValue }
    }
    var disalignmentV: Float {
        get { return metal.shaderOptions.disalignmentV }
        set { metal.shaderOptions.disalignmentV = newValue }
    }
    
    //
    // Emulator preferences
    //
    
    // var alwaysWarp = false { didSet { updateWarp() } }
    
    var warpLoad = Defaults.warpLoad { didSet { updateWarp() } }
    var driveNoise = Defaults.driveNoise
    var driveNoiseNoPoll = Defaults.driveNoiseNoPoll
    var driveBlankDiskFormat = Defaults.driveBlankDiskFormat
    var driveBlankDiskFormatIntValue: Int {
        get { return Int(driveBlankDiskFormat.rawValue) }
        set { driveBlankDiskFormat = FileSystemType.init(newValue) }
    }
    var screenshotSource = Defaults.screenshotSource
    var screenshotTarget = Defaults.screenshotTarget
    var screenshotTargetIntValue: Int {
        get { return Int(screenshotTarget.rawValue) }
        set { screenshotTarget = NSBitmapImageRep.FileType(rawValue: UInt(newValue))! }
    }
    var keepAspectRatio: Bool {
        get { return metal.keepAspectRatio }
        set { metal.keepAspectRatio = newValue }
    }
    var exitOnEsc: Bool {
        get { return keyboardcontroller.exitOnEsc }
        set { keyboardcontroller.exitOnEsc = newValue }
    }
    var closeWithoutAsking = Defaults.closeWithoutAsking
    var ejectWithoutAsking = Defaults.ejectWithoutAsking
    var pauseInBackground = Defaults.pauseInBackground
    
    /// Remembers if the emulator was running or paused when it lost focus.
    /// Needed to implement the pauseInBackground feature.
    var pauseInBackgroundSavedState = false
    
    var takeAutoSnapshots: Bool {
        get { return amiga.takeAutoSnapshots() }
        set { amiga.setTakeAutoSnapshots(newValue) }
    }
    var snapshotInterval: Int {
        get { return amiga.snapshotInterval() }
        set { amiga.setSnapshotInterval(newValue) }
    }
  
    // Updates the warp status
    func updateWarp() {

        var warp: Bool

        switch warpMode {
        case .auto: warp = amiga.diskController.spinning() && warpLoad
        case .on: warp = true
        case .off: warp = false
        }

        warp ? amiga.warpOn() : amiga.warpOff()
    }
    
    // Returns the icon of the sand clock in the bottom bar
    var hourglassIcon: NSImage? {
        switch warpMode {
        case .auto:
            return NSImage.init(named: amiga.warp() ? "hourglass3Template" : "hourglass1Template")
        case .on:
            return NSImage.init(named: "warpLockOnTemplate")
        case .off:
            return NSImage.init(named: "warpLockOffTemplate")
        }
    }

    /*
    var hourglassIcon: NSImage? {
        if amiga.warp() {
            if warpMode == .auto {
                return NSImage.init(named: "hourglass2Template")
            } else {
                return NSImage.init(named: "hourglass3Template")
            }
        } else {
            return NSImage.init(named: "hourglass1Template")
        }
    }
    */

    //
    // Outlets
    //
    
    // Main screen
    @IBOutlet weak var metal: MetalView!
    
    // Bottom bar
    @IBOutlet weak var powerLED: NSButton!

    @IBOutlet weak var df0LED: NSButton!
    @IBOutlet weak var df1LED: NSButton!
    @IBOutlet weak var df2LED: NSButton!
    @IBOutlet weak var df3LED: NSButton!
    @IBOutlet weak var df0Disk: NSButton!
    @IBOutlet weak var df1Disk: NSButton!
    @IBOutlet weak var df2Disk: NSButton!
    @IBOutlet weak var df3Disk: NSButton!
    @IBOutlet weak var df0DMA: NSProgressIndicator!
    @IBOutlet weak var df1DMA: NSProgressIndicator!
    @IBOutlet weak var df2DMA: NSProgressIndicator!
    @IBOutlet weak var df3DMA: NSProgressIndicator!

    @IBOutlet weak var cmdLock: NSButton!

    @IBOutlet weak var clockSpeed: NSTextField!
    @IBOutlet weak var clockSpeedBar: NSLevelIndicator!
    @IBOutlet weak var warpLockIcon: NSButton!
    @IBOutlet weak var warpIcon: NSButton!
    
    // Toolbar
    @IBOutlet weak var toolbar: NSToolbar!
}

extension MyController {

    // Provides the undo manager
    override open var undoManager: UndoManager? {
        return metal.undoManager
    }
 
    // Provides the document casted to the correct type
    var mydocument: MyDocument? {
        return document as? MyDocument
    }
    
    /// Indicates if the emulator needs saving
    var needsSaving: Bool {
        get {
            return document?.changeCount != 0
        }
        set {
            if newValue && !closeWithoutAsking {
                document?.updateChangeCount(.changeDone)
            } else {
                document?.updateChangeCount(.changeCleared)
            }
        }
    }

    //
    // Initialization
    //

    override open func awakeFromNib() {

        track()
                
        // Create audio engine
        audioEngine = AudioEngine.init(withPaula: amiga.paula)
    }

    override open func windowDidLoad() {
 
        track()
        
        // Reset mouse coordinates
        mouseXY = NSPoint.zero
        hideMouse = false
        
        // Create keyboard controller
        keyboardcontroller = KeyboardController()
        if keyboardcontroller == nil {
            track("Failed to create keyboard controller")
            return
        }

        // Create game pad manager
        gamePadManager = GamePadManager(controller: self)
        if gamePadManager == nil {
            track("Failed to create game pad manager")
            return
        }
        
        // Setup window
        configureWindow()
        
        // Get metal running
        metal.setupMetal()
    
        // Load user defaults
        loadUserDefaults()
        
        // Register listener
        addListener()

        // Power up. If a Rom is in place, the emulator starts running.
        // Otherwise, it sends a MISSING_ROM message.
        amiga.run()
        
        // Create speed monitor and get the timer tunning
        createTimer()
        
        // Update toolbar
        toolbar.validateVisibleItems()
        
        // Update status bar
        refreshStatusBar()
    }
    
    func configureWindow() {
    
        // Add status bar
        window?.autorecalculatesContentBorderThickness(for: .minY)
        window?.setContentBorderThickness(32.0, for: .minY)
        statusBar = true
        
        // Adjust size and enable auto-save for window coordinates
        adjustWindowSize()
        window?.windowController?.shouldCascadeWindows = false // true ?!
        let name = NSWindow.FrameAutosaveName("dirkwhoffmann.de.vAmiga.window")
        window?.setFrameAutosaveName(name)
        
        // Enable fullscreen mode
        window?.collectionBehavior = .fullScreenPrimary
    }
    
    func addListener() {
        
        track()
        
        // Convert 'self' to a void pointer
        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        amiga.addListener(myself) { (ptr, type, data) in

            // Convert void pointer back to 'self'
            let myself = Unmanaged<MyController>.fromOpaque(ptr!).takeUnretainedValue()
            
            // Process message in the main thread
            DispatchQueue.main.async {
                let mType = MessageType(rawValue: type)
                myself.processMessage(Message(type: mType, data: data))
            }
        }
  
        track("Listener is in place")
    }
    
    func createTimer() {
    
        // Create speed monitor
        speedometer = Speedometer()
        
        // Create timer and speedometer
        timerLock = NSLock()
        timer = Timer.scheduledTimer(timeInterval: 1.0/12, // 12 times a second
                                     target: self,
                                     selector: #selector(timerFunc),
                                     userInfo: nil,
                                     repeats: true)
        
        track("GUI timer is up and running")
    }

    //
    // Timer and message processing
    //
    
    @objc func timerFunc() {

        assert(timerLock != nil)
        timerLock.lock()
 
        animationCounter += 1

        // Do 12 times a second ...
        if (animationCounter % 1) == 0 {
            
            // Refresh debug panel if open
            /*
            if amiga.isRunning() {
                if myAppDelegate.inspector?.window?.isVisible ?? false {
                    myAppDelegate.inspector?.refresh(everything: false)
                }
            }
            */
        }
        
        // Do 6 times a second ...
        if (animationCounter % 2) == 0 {
 
        }
        
        // Do 3 times a second ...
        if (animationCounter % 4) == 0 {
            speedometer.updateWith(cycle: amiga.cpu.cycles(), frame: metal.frames)
            let mhz = speedometer.mhz
            let fps = speedometer.fps
            clockSpeed.stringValue = String(format: "%.2f MHz %.0f fps", mhz, fps)
            clockSpeedBar.doubleValue = 10 * mhz
        
            // Let the cursor disappear in fullscreen mode
            if metal.fullscreen &&
                CGEventSource.secondsSinceLastEventType(.combinedSessionState,
                                                        eventType: .mouseMoved) > 1.0 {
                NSCursor.setHiddenUntilMouseMoves(true)
            }

            // metal.dxabssum *= 0.5
        }
        
        timerLock.unlock()
    }
 
    func processMessage(_ msg: Message) {

        switch msg.type {
    
        case MSG_CONFIG,
             MSG_MEM_LAYOUT:
             myAppDelegate.inspector?.refresh(everything: true)

        case MSG_BREAKPOINT_CONFIG,
             MSG_BREAKPOINT_REACHED:
             myAppDelegate.inspector?.refresh(everything: true)
 
        case MSG_READY_TO_POWER_ON:
    
            // Launch the emulator
            amiga.run()
     
            // Process attachment (if any)
            mydocument?.mountAmigaAttachment()
        
        case MSG_RUN:

            needsSaving = true
            toolbar.validateVisibleItems()
            myAppDelegate.inspector?.refresh(everything: true)
            refreshStatusBar()
    
        case MSG_PAUSE:
            
            toolbar.validateVisibleItems()
            myAppDelegate.inspector?.refresh(everything: true)
            refreshStatusBar()
    
        case MSG_POWER_ON:

            serialIn = ""
            serialOut = ""
            metal.zoomIn()
            toolbar.validateVisibleItems()
            myAppDelegate.inspector?.refresh(everything: true)
            
        case MSG_POWER_OFF:

            metal.zoomOut(steps: 20) // blendOut()
            toolbar.validateVisibleItems()
            myAppDelegate.inspector?.refresh(everything: true)
            
        case MSG_RESET:
            
            myAppDelegate.inspector?.refresh(everything: true)
            
        case MSG_WARP_ON,
             MSG_WARP_OFF:
            
            refreshStatusBar()
            
        case MSG_POWER_LED_ON:
            powerLED.image = NSImage.init(named: "powerLedOn")

        case MSG_POWER_LED_DIM:
            powerLED.image = NSImage.init(named: "powerLedDim")

        case MSG_POWER_LED_OFF:
            powerLED.image = NSImage.init(named: "powerLedOff")

        case MSG_DMA_DEBUG_ON:
            metal.zoomTextureOut()

        case MSG_DMA_DEBUG_OFF:
            metal.zoomTextureIn()

        case MSG_DRIVE_CONNECT:
            
            switch msg.data {
                
            case 0: myAppDelegate.df0Menu.isHidden = false
            case 1: myAppDelegate.df1Menu.isHidden = false
            case 2: myAppDelegate.df2Menu.isHidden = false
            case 3: myAppDelegate.df3Menu.isHidden = false
            default: fatalError()
            }
            
            refreshStatusBar()
            
        case MSG_DRIVE_DISCONNECT:
            
            switch msg.data {
            case 0: myAppDelegate.df0Menu.isHidden = true
            case 1: myAppDelegate.df1Menu.isHidden = true
            case 2: myAppDelegate.df2Menu.isHidden = true
            case 3: myAppDelegate.df3Menu.isHidden = true
            default: fatalError()
            }
            
            // Remove drop target status from the disconnect drive
            if dragAndDropDrive === amiga.df(msg.data) {
                dragAndDropDrive = nil
            }
            
            refreshStatusBar()
            
        case MSG_DRIVE_DISK_INSERT,
             MSG_DRIVE_DISK_EJECT,
             MSG_DRIVE_DISK_UNSAVED,
             MSG_DRIVE_DISK_SAVED,
             MSG_DRIVE_DISK_PROTECTED,
             MSG_DRIVE_DISK_UNPROTECTED:

            refreshStatusBar()
            
        case MSG_DRIVE_LED_ON:
            
            let image = NSImage.init(named: "driveLedOn")
            switch msg.data {
            case 0: df0LED.image = image
            case 1: df1LED.image = image
            case 2: df2LED.image = image
            case 3: df3LED.image = image
            default: fatalError()
            }
            
        case MSG_DRIVE_LED_OFF:
            
            let image = NSImage.init(named: "driveLedOff")
            switch msg.data {
            case 0: df0LED.image = image
            case 1: df1LED.image = image
            case 2: df2LED.image = image
            case 3: df3LED.image = image
            default: fatalError()
            }
            
        case MSG_DRIVE_MOTOR_ON,
             MSG_DRIVE_MOTOR_OFF:
            
            updateWarp()
            refreshStatusBar()

        case MSG_DRIVE_HEAD:
            
            if driveNoise {
                playSound(name: "drive_click", volume: 1.0)
            }
  
        case MSG_DRIVE_HEAD_POLL:
 
            if driveNoise && !driveNoiseNoPoll {
                playSound(name: "drive_click", volume: 1.0)
            }

        case MSG_SER_IN:
            serialIn += String(UnicodeScalar(msg.data & 0xFF)!)

        case MSG_SER_OUT:
            serialOut += String(UnicodeScalar.init(msg.data & 0xFF)!)

        case MSG_AUTOSNAPSHOT_LOADED,
             MSG_USERSNAPSHOT_LOADED,
             MSG_USERSNAPSHOT_SAVED:
            metal.blendIn(steps: 20)

        case MSG_AUTOSNAPSHOT_SAVED:
            break

        case MSG_ROM_MISSING:
            myDocument?.showConfigurationAltert(msg.type.rawValue)
            openPreferences(tab: "Roms")

        case MSG_CHIP_RAM_LIMIT,
             MSG_AROS_RAM_LIMIT:
            myDocument?.showConfigurationAltert(msg.type.rawValue)
            openPreferences(tab: "Hardware")

        default:
            
            track("Unknown message: \(msg)")
            assert(false)
        }
    }

    //
    // Dialogs
    //
    
    func openPreferences(tab: String = "") {
        
        if preferencesController == nil {
            let nibName = NSNib.Name("Preferences")
            preferencesController = PreferencesController.init(windowNibName: nibName)
        }

        preferencesController!.showSheet(tab: tab)
    }
    
    //
    // Keyboard events
    //

    // Keyboard events are handled by the emulator window.
    // If they are handled here, some keys such as 'TAB' don't trigger an event.

    //
    //  Game pad events
    //
    
    // GamePadManager delegation method
    // Returns true, iff a joystick event has been triggered on port A or B
    @discardableResult
    func joystickEvent(slot: Int, events: [JoystickEvent]) -> Bool {
        
        if slot == inputDevice1 {
            for event in events { amiga.joystick1.trigger(event) }
            return true
        }

        if slot == inputDevice2 {
            for event in events { amiga.joystick2.trigger(event) }
            return true
        }
        
        return false
    }    

    //
    // Action methods (status bar)
    //
    
    @IBAction func warpAction(_ sender: Any!) {

        track()

        switch warpMode {
        case .auto: warpMode = .on
        case .on: warpMode = .off
        case .off: warpMode = .auto
        }

        refreshStatusBar()
    }

    //
    // Misc
    //
    
    func playSound(name: String, volume: Float) {
        
        if let s = NSSound.init(named: name) {
            s.volume = volume
            s.play()
        } else {
            track("ERROR: Cannot create NSSound object.")
        }
    }
}
