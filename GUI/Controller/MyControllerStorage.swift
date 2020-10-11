// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension MyController {
    
    //
    // MARK: - Snapshots
    //
    
    func load(snapshot: SnapshotProxy?) {
        
        if snapshot == nil { return }
        
        amiga.suspend()
        amiga.load(fromSnapshot: snapshot)
        amiga.resume()
    }

    func takeAutoSnapshot() { amiga.requestAutoSnapshot() }
    func takeUserSnapshot() { amiga.requestUserSnapshot() }
        
    func restoreSnapshot(item: Int, auto: Bool) -> Bool {
        
        if auto {
            if let snapshot = mydocument!.autoSnapshots.element(at: item) {
                load(snapshot: snapshot)
                return true
            }
        } else {
            if let snapshot = mydocument!.userSnapshots.element(at: item) {
                load(snapshot: snapshot)
                return true
            }
        }
        
        return false
    }
    
    func restoreAutoSnapshot(item: Int) -> Bool {
        
        return restoreSnapshot(item: item, auto: true)
    }
    func restoreUserSnapshot(item: Int) -> Bool {
        
        return restoreSnapshot(item: item, auto: false)
    }
    
    func restoreLatestAutoSnapshot() -> Bool {
        
        let count = mydocument!.autoSnapshots.count
        return count > 0 ? restoreAutoSnapshot(item: count - 1) : false
    }
    
    func restoreLatestUserSnapshot() -> Bool {
        
        let count = mydocument!.userSnapshots.count
        return count > 0 ? restoreUserSnapshot(item: count - 1) : false
    }
    
    //
    // MARK: - Screenshots
    //
    
    func takeScreenshot(auto: Bool) {
        
        track()
        let upscaled = pref.screenshotSource > 0
        
        // Take screenshot
        guard let screen = renderer.screenshot(afterUpscaling: upscaled) else {
            track("Failed to create screenshot")
            return
        }
        let screenshot = Screenshot.init(screen: screen, format: pref.screenshotTarget)
        
        auto ?
            mydocument!.autoScreenshots.append(screenshot) :
            mydocument!.userScreenshots.append(screenshot)
    }
    
    func takeAutoScreenshot() { takeScreenshot(auto: true) }
    func takeUserScreenshot() { takeScreenshot(auto: false) }
}
