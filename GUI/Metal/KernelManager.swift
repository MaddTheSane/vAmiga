// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class KernelManager {
    
    let device: MTLDevice
    let renderer: Renderer
    
    var library: MTLLibrary! = nil
    
    // An instance of the merge filters
    var mergeFilter: MergeFilter! = nil
    var mergeBypassFilter: MergeBypassFilter! = nil

    // Filter galleries
    var enhancerGallery = [ComputeKernel?](repeating: nil, count: 3)
    var upscalerGallery = [ComputeKernel?](repeating: nil, count: 3)
    var bloomFilterGallery = [ComputeKernel?](repeating: nil, count: 2)
    var scanlineFilterGallery = [ComputeKernel?](repeating: nil, count: 3)

    // The currently selected filters
    var enhancer: ComputeKernel!
    var upscaler: ComputeKernel!
    var bloomFilter: ComputeKernel!
    var scanlineFilter: ComputeKernel!
    
    //
    // Initializing
    //
    
    init(view: MTKView, device: MTLDevice, renderer: Renderer) {
        
        self.device = device
        self.renderer = renderer
        
        buildKernels()
    }
    
    internal func buildKernels() {
    
        let mc = (TextureSize.merged.width, TextureSize.merged.height)
        let uc = (TextureSize.upscaled.width, TextureSize.upscaled.height)

        // Create shader library
        library = device.makeDefaultLibrary()
        renderer.metalAssert(library != nil, "The Shader Library could not be built.")
        
        // Build merge filters
        mergeFilter = MergeFilter.init(device: device, library: library, cutout: mc)
        mergeBypassFilter = MergeBypassFilter.init(device: device, library: library, cutout: mc)
        
        // Build enhancers (first-pass, in-texture upscaling)
        enhancerGallery[0] = BypassFilter.init(device: device, library: library, cutout: mc)
        enhancerGallery[1] = InPlaceEpxScaler.init(device: device, library: library, cutout: mc)
        enhancerGallery[2] = InPlaceXbrScaler.init(device: device, library: library, cutout: mc)
        enhancer = enhancerGallery[0]

        // Build upscalers (second-pass upscaling)
        upscalerGallery[0] = BypassUpscaler.init(device: device, library: library, cutout: uc)
        upscalerGallery[1] = EPXUpscaler.init(device: device, library: library, cutout: uc)
        upscalerGallery[2] = XBRUpscaler.init(device: device, library: library, cutout: uc)
        upscaler = upscalerGallery[0]
        
        // Build bloom filters
        bloomFilterGallery[0] = BypassFilter.init(device: device, library: library, cutout: uc)
        bloomFilterGallery[1] = SplitFilter.init(device: device, library: library, cutout: uc)
        bloomFilter = bloomFilterGallery[0]
        
        // Build scanline filters
        scanlineFilterGallery[0] = BypassFilter.init(device: device, library: library, cutout: uc)
        scanlineFilterGallery[1] = SimpleScanlines(device: device, library: library, cutout: uc)
        scanlineFilterGallery[2] = BypassFilter.init(device: device, library: library, cutout: uc)
        scanlineFilter = scanlineFilterGallery[0]
    }
    
    //
    // Managing kernels
    //
    
    func selectEnhancer(_ nr: Int) -> Bool {
        
        if nr >= 0 && nr < enhancerGallery.count && enhancerGallery[nr] != nil {
            enhancer = enhancerGallery[nr]!
            return true
        }
        return false
    }

    func selectUpscaler(_ nr: Int) -> Bool {
        
        if nr >= 0 && nr < upscalerGallery.count && upscalerGallery[nr] != nil {
            upscaler = upscalerGallery[nr]!
            return true
        }
        return false
    }
    
    func selectBloomFilter(_ nr: Int) -> Bool {
        
        if nr >= 0 && nr < bloomFilterGallery.count && bloomFilterGallery[nr] != nil {
            bloomFilter = bloomFilterGallery[nr]!
            return true
        }
        return false
    }

    func selectScanlineFilter(_ nr: Int) -> Bool {
        
        if nr >= 0 && nr < scanlineFilterGallery.count && scanlineFilterGallery[nr] != nil {
            scanlineFilter = scanlineFilterGallery[nr]!
            return true
        }
        return false
    }
    
    //
    // Accessing the library
    //
    
    func makeFunction(name: String) -> MTLFunction? {
        
        return library.makeFunction(name: name)
    }
}
