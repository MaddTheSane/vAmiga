// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension Double {
   
    func truncate(digits: Int) -> Double {
        let factor = Double(truncating: pow(10, digits) as NSNumber)
        return (self * factor).rounded() / factor
    }
}

class Speedometer {
    
    /// Current emulation speed in MHz
    private var _mhz = 0.0
    var mhz: Double { return truncate(_mhz, digits: 2); }
    
    /// Current GPU performance in frames per second
    private var _fps = 0.0
    var fps: Double { return truncate(_fps, digits: 0); }
    
    /// Smoothing factor
    private let alpha = 0.5

    /// Time of the previous update
    private var latchedTimestamp: Double
    
    /// Value of the master clock in the previous update
    private var latchedCycle: Int64 = Int64.max
    
    /// Frame count in the previous update
    private var latchedFrame: Int64 = Int64.max
    
    init() {

        latchedTimestamp = Date().timeIntervalSince1970
    }
    
    func truncate(_ value: Double, digits: Int) -> Double {
        let factor = Double(truncating: pow(10, digits) as NSNumber)
        return (value * factor).rounded() / factor
    }
    
    /**
     * Updates speed, frame and jitter information.
     * This function needs to be invoked periodically to get meaningful
     * results.
     *   - parameter cycle:  Elapsed CPU cycles since power up
     *   - parameter frame:  Drawn frames since power up
     */
    func updateWith(cycle: Int64, frame: Int64) {
        
        let timestamp = Date().timeIntervalSince1970
        
        if cycle >= latchedCycle && frame >= latchedFrame {

            // Measure elapsed time in microseconds
            let elapsedTime = timestamp - latchedTimestamp
        
            // Measure clock frequency
            let elapsedCycles = Double(cycle - latchedCycle) / 1_000_000
            _mhz = alpha * (elapsedCycles / elapsedTime) + (1 - alpha) * _mhz

            // Measure frames per second
            let elapsedFrames = Double(frame - latchedFrame)
            _fps = alpha * (elapsedFrames / elapsedTime) + (1 - alpha) * _fps
        }
        
        // Keep values
        latchedTimestamp = timestamp
        latchedCycle = cycle
        latchedFrame = frame
    }
}
