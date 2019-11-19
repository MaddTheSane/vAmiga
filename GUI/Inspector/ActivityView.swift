// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class ActivityView: NSView {

    // Values of the upper graph
    var values = [Array(repeating: 0.0, count: 128),
                  Array(repeating: 0.0, count: 128)]

    //
    // Configuring the view
    //

    // Number of horizontal help lines
    @IBInspectable var numlines: Int = 4

    // Set to true to use a logarithmic scale
    @IBInspectable var logscale: Bool = true

    // Set to true if the view should cover an upper and a lower part
    @IBInspectable var splitview: Bool = false

    // Colors for drawing both graphs
    var color1, alpha1a, alpha1b: NSColor!
    var color2, alpha2a, alpha2b: NSColor!

    //
    // Computed properties
    //

    // Scale factor
    var scale: Double { return Double(frame.height) / (splitview ? 2.0 : 1.0) }

    // Vertical location of the zero point
    var zero: Double { return splitview ? Double(frame.height) / 2.0 : 1.0 }

    // MAKE LOCAL
    var w = 0.0, h = 0.0

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupColors()
    }

    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupColors()
    }

    func setupColors() {

        // Check for dark mode
        var darkMode = false
        if #available(OSX 10.14, *) {
            darkMode = NSApp.effectiveAppearance.name == NSAppearance.Name.darkAqua
        }

        if darkMode {

            color1 = NSColor(r: 102, g: 178, b: 255, a: 255)
            alpha1a = NSColor(r: 102, g: 178, b: 255, a: 50)
            alpha1b = NSColor(r: 102, g: 178, b: 255, a: 150)

            color2 = NSColor(r: 255, g: 102, b: 178, a: 255)
            alpha2a = NSColor(r: 255, g: 102, b: 178, a: 50)
            alpha2b = NSColor(r: 255, g: 102, b: 178, a: 150)

        } else {

            color1 = NSColor(r: 0, g: 102, b: 204, a: 255)
            alpha1a = NSColor(r: 0, g: 102, b: 204, a: 50)
            alpha1b = NSColor(r: 0, g: 102, b: 204, a: 150)

            color2 = NSColor(r: 204, g: 0, b: 204, a: 255)
            alpha2a = NSColor(r: 204, g: 0, b: 204, a: 50)
            alpha2b = NSColor(r: 204, g: 0, b: 204, a: 150)
        }
    }

    func update() {

        needsDisplay = true
    }

    func add(value: Double, storage: Int) {

        assert(storage == 0 || storage == 1)
        assert(value >= 0.0)

        // let v = logscale ? log10(1.0 + 9.0 * value) : value
        let v = logscale ? log2(1.0 + 1.0 * value) : value
        let max = values[storage].count

        for i in 0 ..< max-1 {
            values[storage][i] = values[storage][i+1]
            values[storage][max-1] = 0.4 * values[storage][max-2] + 0.6 * v
        }
    }

    func add(val1: Double, val2: Double = 0.0) {

        add(value: val1, storage: 0)
        if splitview { add(value: val2, storage: 1) }

        needsDisplay = true
    }

    /*
    func add(val1: Double, val2: Double = 0.0) {

        add(value: 1.0, storage: 0)
        if splitview { add(value: 1.0, storage: 1) }

        needsDisplay = true
    }
    */

    func sample(x: Int, storage: Int) -> Double {

        assert(storage == 0 || storage == 1)

        let pos = Double(x) / Double(w)
        let val = values[storage][Int(pos * Double(values[storage].count - 1))]

        return storage == 0 ? val : -val
    }

    func drawGrid() {

        let delta = 1.0 / Double(numlines)
        let c = scale, z = Int(zero)

        if let context = NSGraphicsContext.current?.cgContext {

            NSColor.tertiaryLabelColor.setStroke()
            context.setLineWidth(0.5)

            for i in 0...numlines {
                var y = Double(i) * delta
                if logscale { y = log10(1.0 + 9*y) }
                context.move(to: CGPoint(x: 0, y: z + Int(c * y)))
                context.addLine(to: CGPoint(x: Int(w), y: z + Int(c * y)))
                context.strokePath()
            }

            if splitview {
                for i in 1..<numlines {
                     var y = Double(i) * delta
                     if logscale { y = log10(1.0 + 9*y) }
                     context.move(to: CGPoint(x: 0, y: z - Int(c * y)))
                     context.addLine(to: CGPoint(x: Int(w), y: z - Int(c * y)))
                     context.strokePath()
                 }
            }
        }
    }

    func drawZeroLine() {

        if let context = NSGraphicsContext.current?.cgContext {

            context.setLineWidth(1)
            NSColor.secondaryLabelColor.setStroke()
            context.move(to: CGPoint(x: 0, y: Int(zero)))
            context.addLine(to: CGPoint(x: Int(w), y: Int(zero)))
            context.strokePath()
        }
    }

    func createGraph(storage s: Int) -> NSBezierPath {

        let graph = NSBezierPath()
        let c = scale, z = zero

        var y = sample(x: 0, storage: s)
        graph.move(to: CGPoint(x: 0, y: Int(z + y * c)))
        for x in 0...Int(w) {
            y = sample(x: x, storage: s)
            graph.line(to: CGPoint(x: x, y: Int(z + y * c)))
        }

        return graph
    }

    func draw(upper: Bool) {

        let context = NSGraphicsContext.current?.cgContext
        var graph1, graph2, clip1, clip2: NSBezierPath?

        // Create gradient
        let c2 = NSColor(r: 255, g: 255, b: 0, a: 128).cgColor
        let c3 = NSColor(r: 255, g: 0, b: 0, a: 128).cgColor
        let grad1 = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: [alpha1a.cgColor, alpha1b.cgColor, c2, c3] as CFArray,
                               locations: [0.0, 0.6, 0.8, 1.0] as [CGFloat])!
        let grad2 = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: [alpha2a.cgColor, alpha2b.cgColor, c2, c3] as CFArray,
                               locations: [0.0, 0.6, 0.8, 1.0] as [CGFloat])!

        // Create graph lines
        graph1 = createGraph(storage: 0)
        if splitview { graph2 = createGraph(storage: 1) }

        // Create clipping areas
        clip1 = graph1?.copy() as? NSBezierPath
        clip1?.line(to: CGPoint(x: Int(w), y: Int(zero)))
        clip1?.line(to: CGPoint(x: 0, y: Int(zero)))
        clip1?.close()

        if splitview {
            clip2 = graph2?.copy() as? NSBezierPath
            clip2?.line(to: CGPoint(x: Int(w), y: Int(zero)))
            clip2?.line(to: CGPoint(x: 0, y: Int(zero)))
            clip2?.close()
        }

        // Apply a gradient fill
        context?.saveGState()
        clip1?.addClip()
        context?.drawLinearGradient(grad1,
                                    start: CGPoint(x: 0, y: zero),
                                    end: CGPoint(x: 0, y: bounds.height),
                                    options: [])
        context?.restoreGState()

        // Draw graph line
        /*
        color1.setStroke()
        graph1?.lineWidth = 2.0
        graph1?.stroke()
        */

        // Draw lower graph
        if splitview {

            // Apply a gradient fill
            context?.saveGState()
            clip2?.addClip()
            context?.drawLinearGradient(grad2,
                                        start: CGPoint(x: 0, y: zero),
                                        end: CGPoint(x: 0, y: 0),
                                        options: [])
            context?.restoreGState()

            // Draw graph line
            /*
            color2.setStroke()
            graph2?.lineWidth = 2.0
            graph2?.stroke()
            */
        }
    }

    override func draw(_ dirtyRect: NSRect) {

        let context = NSGraphicsContext.current?.cgContext

        // Store width and height
        w = Double(frame.width)
        h = Double(frame.height - 1)

        // Clear the view
        NSColor.clear.set()
        context?.fill(dirtyRect)

        // Draw background
        drawGrid()

        // Draw positive values
        draw(upper: true)
        draw(upper: false)

        drawZeroLine()
    }
}

extension NSColor {

    func lighter(by percentage: CGFloat = 30.0) -> NSColor {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> NSColor {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> NSColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return NSColor(red: min(red + percentage/100, 1.0),
                       green: min(green + percentage/100, 1.0),
                       blue: min(blue + percentage/100, 1.0),
                       alpha: alpha)
    }

    func transparent(alpha: CGFloat = 0.3) -> NSColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return NSColor(red: r, green: g, blue: b, alpha: alpha)
    }
}
