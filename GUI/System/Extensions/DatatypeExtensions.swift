// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Carbon.HIToolbox

//
// Comparable
//

/// Clamps a variable between `minimum` and `maximum`.
/// - parameter value: The value to clamp.
/// - parameter minimum: The minimum value to clamp `value` to.
/// - parameter maximum: The maximum value to clamp `value` to.
/// - returns: `value` if it is in-between `minimum` and `maximum`,
/// or a value that is no less than `minimum` and no greater than `maximum`.
///
/// If `minimum` is greater than `maximum`, a fatal error occurs.
@inlinable func clamp<X: Comparable>(_ value: X, minimum: X, maximum: X) -> X {
    precondition(minimum <= maximum, "Minimum (\(minimum)) is greater than maximum (\(maximum))!")
    return max(min(value, maximum), minimum)
}

extension Comparable {
    
    @available(*, deprecated, message: "Use the clamp function instead")
    func clamped(_ f: Self, _ t: Self) -> Self {
        
        var r = self
        if r > t { r = t }
        if r < f { r = f }
        return r
    }
}

//
// Data
//

extension Data {
    
    var bitmap: NSBitmapImageRep? {
        return NSBitmapImageRep(data: self)
    }
}

//
// Double
//

extension Double {
   
    func truncate(digits: Int) -> Double {
        let factor = Double(truncating: pow(10, digits) as NSNumber)
        return (self * factor).rounded() / factor
    }
}

//
// Strings
//

extension String {
    
    func indicesOf(string: String) -> [Int] {
        
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
              !range.isEmpty {
            
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }

    init?(keyCode: UInt16, carbonFlags: Int) {
        
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)!
        let dataRef = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue()
        let data = dataRef as Data
        let maxChars = 1
        var length = 0
        var chars = [UniChar](repeating: 0, count: maxChars)
        let error = data.withUnsafeBytes { urbp in
            let keyLayoutPtr = urbp.assumingMemoryBound(to: CoreServices.UCKeyboardLayout.self)
            let modifierKeyState = (carbonFlags >> 8) & 0xFF
            let keyTranslateOptions = OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit)
            var deadKeyState: UInt32 = 0

            return CoreServices.UCKeyTranslate(keyLayoutPtr.baseAddress,
                                               keyCode,
                                               UInt16(CoreServices.kUCKeyActionDisplay),
                                               UInt32(modifierKeyState),
                                               UInt32(LMGetKbdType()),
                                               keyTranslateOptions,
                                               &deadKeyState,
                                               maxChars,
                                               &length,
                                               &chars)
        }
        
        if error == noErr {
            self.init(NSString(characters: &chars, length: length))
        } else {
            return nil
        }
    }
}

extension NSAttributedString {
    
    convenience init(_ text: String, size: CGFloat, color: NSColor) {
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .center

        let attr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size),
            .foregroundColor: color,
            .paragraphStyle: paraStyle
        ]
        
        self.init(string: text, attributes: attr)
    }
}
