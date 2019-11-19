// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension MyController: NSWindowDelegate {
        
    public func windowDidBecomeMain(_ notification: Notification) {
        
        guard let window = notification.object as? NSWindow else { return }
        
        // Inform the application delegate
        myAppDelegate.windowDidBecomeMain(window)
        
        // Start emulator if it was only paused while in background
        if pauseInBackground && pauseInBackgroundSavedState { amiga.run() }

        // Register for mouse move events
        window.acceptsMouseMovedEvents = true
        
        // Make sure the aspect ratio is correct
        adjustWindowSize()

        // Update the status bar
        myController?.refreshStatusBar()

        // Let the emulator tell us it's current state
        amigaProxy?.ping()

    }
    
    public func windowDidResignMain(_ notification: Notification) {
        
        // track()
        
        // Stop emulator if it is configured to pause in background
        pauseInBackgroundSavedState = amiga.isRunning
        if pauseInBackground { amiga.pause() }
    }
    
    public func windowWillClose(_ notification: Notification) {
        
        track()

        // Stop timer
        timerLock.lock()
        timer?.invalidate()
        timer = nil
        timerLock.unlock()

        // Disconnect the audio engine
        audioEngine.shutDown()

        // Unregister from the message queue
        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        amiga.removeListener(myself)

        // Stop metal view
        metal.cleanup()
    }
    
    public func windowWillEnterFullScreen(_ notification: Notification) {

        track()
        metal.fullscreen = true
        showStatusBar(false)
    }
    
    public func  windowDidEnterFullScreen(_ notification: Notification) {

        track()
    }
    
    public func windowWillExitFullScreen(_ notification: Notification) {

        track()
        metal.fullscreen = false
        showStatusBar(true)
    }
    
    public func windowDidExitFullScreen(_ notification: Notification) {

        // track()
    }
    
    public func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        
        track()
        let autoHideToolbar = NSApplication.PresentationOptions.autoHideToolbar
        var options = NSApplication.PresentationOptions.init(rawValue: autoHideToolbar.rawValue)
        options.insert(proposedOptions)
        return options
    }
    
    public func window(_ window: NSWindow, willUseFullScreenContentSize proposedSize: NSSize) -> NSSize {

        var myRect = metal.bounds
        myRect.size = proposedSize
        return proposedSize
    }
    
    // Fixes a NSSize to match our desired aspect ration
    func fixSize(window: NSWindow, size: NSSize) -> NSSize {
        
        // Get some basic parameters
        let windowFrame = window.frame
        let deltaX = size.width - windowFrame.size.width
        let deltaY = size.height - windowFrame.size.height
        
        // How big would the metal view become?
        let metalFrame = metal.frame
        let metalX = metalFrame.size.width + deltaX
        let metalY = metalFrame.size.height + deltaY
        
        // We want to achieve an aspect ratio of 804:621
        let newMetalX  = metalY * (804.0 / 621.0)
        let dx = newMetalX - metalX
        
        return NSSize.init(width: size.width + dx, height: size.height)
    }

    // Fixes a NSRect to match our desired aspect ration
    func fixRect(window: NSWindow, rect: NSRect) -> NSRect {
        
        let newSize = fixSize(window: window, size: rect.size)
        let newOriginX = (rect.width - newSize.width) / 2.0
        
        return NSRect.init(x: newOriginX, y: 0, width: newSize.width, height: newSize.height)
    }
    
    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        
        return fixSize(window: sender, size: frameSize)
    }
    
    public func windowWillUseStandardFrame(_ window: NSWindow,
                                           defaultFrame newFrame: NSRect) -> NSRect {

        return fixRect(window: window, rect: newFrame)
    }
}

extension MyController {
    
    /// Adjusts the windows vertical size programatically
    func adjustWindowSize() {
        
        // track()
        if var frame = window?.frame {
            
            // Compute size correction
            let newsize = windowWillResize(window!, to: frame.size)
            let correction = newsize.height - frame.size.height
            
            // Adjust frame
            frame.origin.y -= correction
            frame.size = newsize
            
            window!.setFrame(frame, display: true)
        }
    }
}
