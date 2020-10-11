// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Metal
import MetalKit
import MetalPerformanceShaders

//
// MARK: - Additional uniforms needed by the vertex shader
//

struct VertexUniforms {
    
    var mvp: simd_float4x4
}

//
// MARK: - Uniforms passed to all compute shaders and the fragment shader
//
    
struct ShaderOptions: Codable {

    var blur: Int32
    var blurRadius: Float
    
    var bloom: Int32
    var bloomRadius: Float
    var bloomBrightness: Float
    var bloomWeight: Float

    var flicker: Int32
    var flickerWeight: Float

    var dotMask: Int32
    var dotMaskBrightness: Float
    
    var scanlines: Int32
    var scanlineBrightness: Float
    var scanlineWeight: Float
    
    var disalignment: Int32
    var disalignmentH: Float
    var disalignmentV: Float
}

//
// MARK: - Uniforms passed to the merge shader
//

struct MergeUniforms {

    var longFrameScale: Float
    var shortFrameScale: Float
}

//
// MARK: - Additional uniforms needed by the fragment shader
//

struct FragmentUniforms {
    
    var alpha: Float
    var dotMaskWidth: Int32
    var dotMaskHeight: Int32
    var scanlineDistance: Int32
}

//
// MARK: - Base class for all compute kernels
//

class ComputeKernel: NSObject {

    var device: MTLDevice!
    var kernel: MTLComputePipelineState!

    // The rectangle the compute kernel is applied to
    var cutout = (256, 256)
    
    convenience init?(name: String, device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        
        self.init()
        
        self.device = device
        self.cutout = cutout
        
        // Lookup kernel function in library
        guard let function = library.makeFunction(name: name) else {
            track("ERROR: Cannot find kernel function '\(name)' in library.")
            return nil
        }
        
        // Create kernel
        do {
            try kernel = device.makeComputePipelineState(function: function)
        } catch {
            track("ERROR: Cannot create compute kernel '\(name)'.")
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.icon = NSImage.init(named: "metal")
            alert.messageText = "Failed to create compute kernel."
            alert.informativeText = "Kernel '\(name)' will be ignored when selected."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return nil
        }
    }
    
    func apply(commandBuffer: MTLCommandBuffer, source: MTLTexture, target: MTLTexture,
               options: UnsafeRawPointer? = nil) {
        
        apply(commandBuffer: commandBuffer, textures: [source, target], options: options)
    }

    func apply(commandBuffer: MTLCommandBuffer, textures: [MTLTexture],
               options: UnsafeRawPointer? = nil) {
        
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            
            for (index, texture) in textures.enumerated() {
                encoder.setTexture(texture, index: index)
            }
            apply(encoder: encoder, options: options)
        }
    }

    func apply(encoder: MTLComputeCommandEncoder, options: UnsafeRawPointer? = nil) {
        
        // Bind pipeline
        encoder.setComputePipelineState(kernel)
        
        // Pass in shader options
        if options != nil {
            encoder.setBytes(options!,
                             length: MemoryLayout<ShaderOptions>.stride,
                             index: 0)
        }
        
        // Determine thread group size and number of groups
        let groupW = kernel.threadExecutionWidth
        let groupH = kernel.maxTotalThreadsPerThreadgroup / groupW
        let threadsPerGroup = MTLSizeMake(groupW, groupH, 1)
        
        let countW = (cutout.0) / groupW
        let countH = (cutout.1) / groupH
        let threadgroupCount = MTLSizeMake(countW, countH, 1)
        
        // Finally, we're ready to dispatch
        encoder.dispatchThreadgroups(threadgroupCount,
                                     threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()
    }
}

//
// MARK: - Bypass filter
//

class BypassFilter: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "bypass",
                  device: device, library: library, cutout: cutout)
    }
}

//
// MARK: - Mergers
//

class MergeFilter: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "merge",
                  device: device, library: library, cutout: cutout)
    }
}

class MergeBypassFilter: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "bypassmerger",
                  device: device, library: library, cutout: cutout)
    }
}

//
// MARK: - Upscalers
//

class BypassUpscaler: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "bypassupscaler",
                  device: device, library: library, cutout: cutout)
    }
}

class InPlaceEpxScaler: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "inPlaceEpx",
                  device: device, library: library, cutout: cutout)
    }
}

class InPlaceXbrScaler: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "inPlaceXbr",
                  device: device, library: library, cutout: cutout)
    }
}
class EPXUpscaler: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "epxupscaler",
                  device: device, library: library, cutout: cutout)
    }
}

class XBRUpscaler: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "xbrupscaler",
                  device: device, library: library, cutout: cutout)
    }
}

//
// MARK: - Split filter
//

class SplitFilter: ComputeKernel {

    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "split",
                  device: device, library: library, cutout: cutout)
    }
}

//
// MARK: - Scanline filter
//

class SimpleScanlines: ComputeKernel {
    
    convenience init?(device: MTLDevice, library: MTLLibrary, cutout: (Int, Int)) {
        self.init(name: "scanlines",
                  device: device, library: library, cutout: cutout)
    }
}
