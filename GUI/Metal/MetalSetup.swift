// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import simd

//
// Static texture parameters
//

// Parameters of a short / long frame texture delivered by the emulator
struct EmulatorTexture {

    static let width = 1024 // Int(HPIXELS)
    static let height = 320 // Int(VPIXELS)
}

// Parameters of a textures that combines a short and a long frame
struct MergedTexture {

    static let width = EmulatorTexture.width
    static let height = 2 * EmulatorTexture.height
    static let cutout = (width, height)
}

// Parameters of a (merged) texture that got upscaled
struct UpscaledTexture {

    static let width = 2 * MergedTexture.width
    static let height = 2 * MergedTexture.height
    static let cutout = (width, height)
}

public extension MetalView {

    func checkForMetal() {
        
        if MTLCreateSystemDefaultDevice() == nil {
            
            showNoMetalSupportAlert()
            NSApp.terminate(self)
            return
        }
    }
  
    func setupMetal() {

        track()
        
        buildMetal()
        buildTextures()
        buildSamplers()
        buildKernels()
        buildDotMasks()
        buildPipeline()
        
        // updateScreenGeometry()
        buildVertexBuffer()
        
        self.reshape(withFrame: self.frame)
        enableMetal = true
    }
    
    internal func buildMetal() {
    
        track()
            
        // Metal device
        device = MTLCreateSystemDefaultDevice()
        assert(device != nil, "Metal device must not be nil")
    
        // Metal layer
        metalLayer = self.layer as? CAMetalLayer
        assert(metalLayer != nil, "Metal layer must not be nil")
        
        metalLayer.device = device
        metalLayer.pixelFormat = MTLPixelFormat.bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = metalLayer.frame
        layerWidth = metalLayer.drawableSize.width
        layerHeight = metalLayer.drawableSize.height
    
        // Command queue
        queue = device?.makeCommandQueue()
        assert(queue != nil, "Metal command queue must not be nil")
    
        // Shader library
        library = device?.makeDefaultLibrary()
        assert(library != nil, "Metal library must not be nil")
    
        // View parameters
        self.sampleCount = 1
    }
    
    internal func buildTextures() {

        track()
        assert(device != nil)

        //
        // Background texture
        //
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.rgba8Unorm,
            width: 512,
            height: 512,
            mipmapped: false)

        // Background texture (drawn behind the cube)
        bgTexture = self.createBackgroundTexture()

        //
        // Emulator textures (one for short frames, one for long frames)
        //
        
        descriptor.width = EmulatorTexture.width
        descriptor.height = EmulatorTexture.height

        track("Creating emulator texture \(descriptor.width) x \(descriptor.height)")

        // Emulator textures (raw data of long and short frames)
        descriptor.usage = [ .shaderRead ]
        longFrameTexture = device?.makeTexture(descriptor: descriptor)
        assert(longFrameTexture != nil, "Failed to create long frame texture.")
        shortFrameTexture = device?.makeTexture(descriptor: descriptor)
        assert(shortFrameTexture != nil, "Failed to create short frame texture.")

        let actualWidth = longFrameTexture.width
        let actualHeight = longFrameTexture.height
        track("Created \(actualWidth) x \(actualHeight)")

        //
        // Textures that combine a short and a long frame (not yet upscaled)
        //
        
        descriptor.width = MergedTexture.width
        descriptor.height = MergedTexture.height
        
        // Merged emulator texture (long frame + short frame)
        descriptor.usage = [ .shaderRead, .shaderWrite, .renderTarget ]
        mergeTexture = device?.makeTexture(descriptor: descriptor)
        assert(mergeTexture != nil, "Failed to create merge texture.")
        
        // Bloom textures
        descriptor.usage = [ .shaderRead, .shaderWrite, .renderTarget ]
        bloomTextureR = device?.makeTexture(descriptor: descriptor)
        bloomTextureG = device?.makeTexture(descriptor: descriptor)
        bloomTextureB = device?.makeTexture(descriptor: descriptor)
        assert(bloomTextureR != nil, "Failed to create bloom texture (R).")
        assert(bloomTextureG != nil, "Failed to create bloom texture (G).")
        assert(bloomTextureB != nil, "Failed to create bloom texture (B).")

        descriptor.usage = [ .shaderRead, .shaderWrite, .renderTarget ]
        lowresEnhancedTexture = device?.makeTexture(descriptor: descriptor)
        assert(lowresEnhancedTexture != nil, "Failed to create lowres enhancement texture.")
        
        //
        // Upscaled textures
        //
        
        descriptor.width  = UpscaledTexture.width
        descriptor.height = UpscaledTexture.height
        
        // Upscaled emulator texture
        descriptor.usage = [ .shaderRead, .shaderWrite, .pixelFormatView, .renderTarget ]
        upscaledTexture = device?.makeTexture(descriptor: descriptor)
        assert(upscaledTexture != nil, "Failed to create upscaling texture.")
        
        // Scanline texture
        scanlineTexture = device?.makeTexture(descriptor: descriptor)
        assert(scanlineTexture != nil, "Failed to create scanline texture.")
    }
    
    internal func buildSamplers() {

        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = MTLSamplerAddressMode.clampToEdge
        descriptor.tAddressMode = MTLSamplerAddressMode.clampToEdge
        descriptor.mipFilter = MTLSamplerMipFilter.notMipmapped

        // Nearest neighbor sampler
        descriptor.minFilter = MTLSamplerMinMagFilter.linear
        descriptor.magFilter = MTLSamplerMinMagFilter.linear
        samplerLinear = device!.makeSamplerState(descriptor: descriptor)
        
        // Linear sampler
        descriptor.minFilter = MTLSamplerMinMagFilter.nearest
        descriptor.magFilter = MTLSamplerMinMagFilter.nearest
        samplerNearest = device!.makeSamplerState(descriptor: descriptor)
    }
    
    internal func buildKernels() {
        
        assert(device != nil)
        assert(library != nil)
        
        let mc = MergedTexture.cutout
        let uc = UpscaledTexture.cutout
        
        // Build the mergefilter
        mergeFilter = MergeFilter(device: device!, library: library, cutout: mc)
        
        // Build low-res enhancers (first-pass, in-texture upscaling)
        enhancerGallery[0] = BypassFilter(device: device!, library: library, cutout: mc)
        enhancerGallery[1] = InPlaceEpxScaler(device: device!, library: library, cutout: mc)
        enhancerGallery[2] = InPlaceXbrScaler(device: device!, library: library, cutout: mc)
        
        // Build upscalers (second-pass upscaling)
        upscalerGallery[0] = BypassUpscaler(device: device!, library: library, cutout: uc)
        upscalerGallery[1] = EPXUpscaler(device: device!, library: library, cutout: uc)
        upscalerGallery[2] = XBRUpscaler(device: device!, library: library, cutout: uc)
        
        // Build bloom filters
        bloomFilterGallery[0] = BypassFilter(device: device!, library: library, cutout: uc)
        bloomFilterGallery[1] = SplitFilter(device: device!, library: library, cutout: uc)

        // Build scanline filters
        scanlineFilterGallery[0] = BypassFilter(device: device!, library: library, cutout: uc)
        scanlineFilterGallery[1] = SimpleScanlines(device: device!, library: library, cutout: uc)
        scanlineFilterGallery[2] = BypassFilter(device: device!, library: library, cutout: uc)
    }
    
    func buildDotMasks() {
        
        let selected = shaderOptions.dotMask
        let max  = UInt8(85 + shaderOptions.dotMaskBrightness * 170)
        let base = UInt8((1 - shaderOptions.dotMaskBrightness) * 85)
        let none = UInt8(30 + (1 - shaderOptions.dotMaskBrightness) * 55)
        
        let R = UInt32(r: max, g: base, b: base)
        let G = UInt32(r: base, g: max, b: base)
        let B = UInt32(r: base, g: base, b: max)
        let M = UInt32(r: max, g: base, b: max)
        let W = UInt32(r: max, g: max, b: max)
        let N = UInt32(r: none, g: none, b: none)

        let maskSize = [
            CGSize(width: 1, height: 1),
            CGSize(width: 3, height: 1),
            CGSize(width: 4, height: 1),
            CGSize(width: 3, height: 9),
            CGSize(width: 4, height: 8)
            ]
        
        let maskData = [
            
            [ W ],
            [ M, G, N ],
            [ R, G, B, N ],
            [ M, G, N,
              M, G, N,
              N, N, N,
              N, M, G,
              N, M, G,
              N, N, N,
              G, N, M,
              G, N, M,
              N, N, N],
            [ R, G, B, N,
              R, G, B, N,
              R, G, B, N,
              N, N, N, N,
              B, N, R, G,
              B, N, R, G,
              B, N, R, G,
              N, N, N, N]
        ]
        
        for n in 0 ... 4 {
            
            // Create image representation in memory
            let cap = Int(maskSize[n].width) * Int (maskSize[n].height)
            let mask = calloc(cap, MemoryLayout<UInt32>.size)!
            let ptr = mask.bindMemory(to: UInt32.self, capacity: cap)
            for i in 0 ... cap - 1 {
                ptr[i] = maskData[n][i]
            }
            
            // Create image
            let image = NSImage.make(data: mask, rect: maskSize[n])
            
            // Create texture if the dotmask is the currently selected mask
            if n == selected {
                dotMaskTexture = image?.toTexture(device: device!)
            }
            
            // Store preview image
            dotmaskImages[n] = image?.resizeSharp(width: 12, height: 12)
        }
    }
    
    func buildMatricesBg() {
        
        let model  = matrix_identity_float4x4
        let view   = matrix_identity_float4x4
        let aspect = Float(layerWidth) / Float(layerHeight)
        let proj   = perspectiveMatrix(fovY: (Float(65.0 * (.pi / 180.0))),
                                             aspect: aspect,
                                             nearZ: 0.1,
                                             farZ: 100.0)
        
        vertexUniformsBg.mvp = proj * view * model
    }
    
    func buildMatrices2D() {
    
        let model = matrix_identity_float4x4
        let view  = matrix_identity_float4x4
        let proj  = matrix_identity_float4x4
        
        vertexUniforms2D.mvp = proj * view * model
    }
    
    func buildMatrices3D() {

        let xAngle = -angleX.current / 180.0 * .pi
        let yAngle = angleY.current / 180.0 * .pi
        let zAngle = angleZ.current / 180.0 * .pi

        let xShift = -shiftX.current - controller.eyeX
        let yShift = -shiftY.current - controller.eyeY
        let zShift = shiftZ.current + controller.eyeZ

        let aspect = Float(layerWidth) / Float(layerHeight)

        let view = matrix_identity_float4x4
        let proj = perspectiveMatrix(fovY: Float(65.0 * (.pi / 180.0)),
                                     aspect: aspect,
                                     nearZ: 0.1,
                                     farZ: 100.0)

        let transEye = translationMatrix(x: xShift,
                                         y: yShift,
                                         z: zShift + 1.39 - 0.16)

        let transRotX = translationMatrix(x: 0.0,
                                          y: 0.0,
                                          z: 0.16)

        let rotX = rotationMatrix(radians: xAngle, x: 0.5, y: 0.0, z: 0.0)
        let rotY = rotationMatrix(radians: yAngle, x: 0.0, y: 0.5, z: 0.0)
        let rotZ = rotationMatrix(radians: zAngle, x: 0.0, y: 0.0, z: 0.5)

        // Chain all transformations
        let model = transEye * rotX * transRotX * rotY * rotZ

        vertexUniforms3D.mvp = proj * view * model
    }

    func buildVertexBuffer() {
    
        if device == nil {
            return
        }
        
        let capacity = 16 * 3 * 8
        let pos = UnsafeMutablePointer<Float>.allocate(capacity: capacity)
        
        func setVertex(_ i: Int, _ position: SIMD3<Float>, _ texture: SIMD2<Float>) {
            
            let first = i * 8
            pos[first + 0] = position.x
            pos[first + 1] = position.y
            pos[first + 2] = position.z
            pos[first + 3] = 1.0 /* alpha */
            pos[first + 4] = texture.x
            pos[first + 5] = texture.y
            pos[first + 6] = 0.0 /* alignment byte (unused) */
            pos[first + 7] = 0.0 /* alignment byte (unused) */
        }
        
        let dx = Float(0.64)
        let dy = Float(0.48)
        let dz = Float(0.64)
        let bgx = Float(6.4)
        let bgy = Float(4.8)
        let bgz = Float(-6.8)

        let upperLeft = SIMD2<Float>(Float(textureRect.minX), Float(textureRect.minY))
        let upperRight = SIMD2<Float>(Float(textureRect.maxX), Float(textureRect.minY))
        let lowerLeft = SIMD2<Float>(Float(textureRect.minX), Float(textureRect.maxY))
        let lowerRight = SIMD2<Float>(Float(textureRect.maxX), Float(textureRect.maxY))

        // Background
        setVertex(0, SIMD3<Float>(-bgx, +bgy, -bgz), SIMD2<Float>(0.0, 0.0))
        setVertex(1, SIMD3<Float>(-bgx, -bgy, -bgz), SIMD2<Float>(0.0, 1.0))
        setVertex(2, SIMD3<Float>(+bgx, -bgy, -bgz), SIMD2<Float>(1.0, 1.0))
    
        setVertex(3, SIMD3<Float>(-bgx, +bgy, -bgz), SIMD2<Float>(0.0, 0.0))
        setVertex(4, SIMD3<Float>(+bgx, +bgy, -bgz), SIMD2<Float>(1.0, 0.0))
        setVertex(5, SIMD3<Float>(+bgx, -bgy, -bgz), SIMD2<Float>(1.0, 1.0))
    
        // -Z
        setVertex(6, SIMD3<Float>(-dx, +dy, -dz), upperLeft)
        setVertex(7, SIMD3<Float>(-dx, -dy, -dz), lowerLeft)
        setVertex(8, SIMD3<Float>(+dx, -dy, -dz), lowerRight)
    
        setVertex(9, SIMD3<Float>(-dx, +dy, -dz), upperLeft)
        setVertex(10, SIMD3<Float>(+dx, +dy, -dz), upperRight)
        setVertex(11, SIMD3<Float>(+dx, -dy, -dz), lowerRight)
    
        // +Z
        setVertex(12, SIMD3<Float>(-dx, +dy, +dz), upperRight)
        setVertex(13, SIMD3<Float>(-dx, -dy, +dz), lowerRight)
        setVertex(14, SIMD3<Float>(+dx, -dy, +dz), lowerLeft)
    
        setVertex(15, SIMD3<Float>(-dx, +dy, +dz), upperRight)
        setVertex(16, SIMD3<Float>(+dx, +dy, +dz), upperLeft)
        setVertex(17, SIMD3<Float>(+dx, -dy, +dz), lowerLeft)
    
        // -X
        setVertex(18, SIMD3<Float>(-dx, +dy, -dz), upperRight)
        setVertex(19, SIMD3<Float>(-dx, -dy, -dz), lowerRight)
        setVertex(20, SIMD3<Float>(-dx, -dy, +dz), lowerLeft)
    
        setVertex(21, SIMD3<Float>(-dx, +dy, -dz), upperRight)
        setVertex(22, SIMD3<Float>(-dx, +dy, +dz), upperLeft)
        setVertex(23, SIMD3<Float>(-dx, -dy, +dz), lowerLeft)
    
        // +X
        setVertex(24, SIMD3<Float>(+dx, +dy, -dz), upperLeft)
        setVertex(25, SIMD3<Float>(+dx, -dy, -dz), lowerLeft)
        setVertex(26, SIMD3<Float>(+dx, -dy, +dz), lowerRight)
    
        setVertex(27, SIMD3<Float>(+dx, +dy, -dz), upperLeft)
        setVertex(28, SIMD3<Float>(+dx, +dy, +dz), upperRight)
        setVertex(29, SIMD3<Float>(+dx, -dy, +dz), lowerRight)
    
        // -Y
        setVertex(30, SIMD3<Float>(+dx, -dy, -dz), upperRight)
        setVertex(31, SIMD3<Float>(-dx, -dy, -dz), upperLeft)
        setVertex(32, SIMD3<Float>(-dx, -dy, -dz + 2*dy), lowerLeft)
    
        setVertex(33, SIMD3<Float>(+dx, -dy, -dz), upperRight)
        setVertex(34, SIMD3<Float>(+dx, -dy, -dz + 2*dy), lowerRight)
        setVertex(35, SIMD3<Float>(-dx, -dy, -dz + 2*dy), lowerLeft)
    
        // +Y
        setVertex(36, SIMD3<Float>(+dx, +dy, -dz), lowerRight)
        setVertex(37, SIMD3<Float>(-dx, +dy, -dz), lowerLeft)
        setVertex(38, SIMD3<Float>(-dx, +dy, -dz + 2*dy), upperLeft)
    
        setVertex(39, SIMD3<Float>(+dx, +dy, -dz), lowerRight)
        setVertex(40, SIMD3<Float>(-dx, +dy, -dz + 2*dy), upperLeft)
        setVertex(41, SIMD3<Float>(+dx, +dy, -dz + 2*dy), upperRight)
    
        // 2D drawing quad
        setVertex(42, SIMD3<Float>(-1, 1, 0), upperLeft)
        setVertex(43, SIMD3<Float>(-1, -1, 0), lowerLeft)
        setVertex(44, SIMD3<Float>( 1, -1, 0), lowerRight)
    
        setVertex(45, SIMD3<Float>(-1, 1, 0), upperLeft)
        setVertex(46, SIMD3<Float>( 1, 1, 0), upperRight)
        setVertex(47, SIMD3<Float>( 1, -1, 0), lowerRight)
    
        let opt = MTLResourceOptions.cpuCacheModeWriteCombined
        let len = capacity * 4
        positionBuffer = device?.makeBuffer(bytes: pos, length: len, options: opt)
        assert(positionBuffer != nil, "positionBuffer must not be nil")
    }
 
    func buildDepthBuffer() {
        
        // track("buildDepthBuffer")

        if device == nil {
            return
        }
        
        let width = Int(layerWidth)
        let height = Int(layerHeight)
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.depth32Float,
            width: width,
            height: height,
            mipmapped: false)
        descriptor.resourceOptions = MTLResourceOptions.storageModePrivate
        descriptor.usage = MTLTextureUsage.renderTarget
        
        depthTexture = device?.makeTexture(descriptor: descriptor)
        assert(depthTexture != nil, "Failed to create depth texture")
    }
    
    func buildPipeline() {

        track()
        assert(device != nil)
        assert(library != nil)
        
        // Get vertex and fragment shader from library
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")
        assert(vertexFunc != nil)
        assert(fragmentFunc != nil)

        // Create depth stencil state
        let stencilDescriptor = MTLDepthStencilDescriptor()
        stencilDescriptor.depthCompareFunction = MTLCompareFunction.less
        stencilDescriptor.isDepthWriteEnabled = true
        depthState = device?.makeDepthStencilState(descriptor: stencilDescriptor)
        
        // Setup vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Positions
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
    
        // Texture coordinates
        vertexDescriptor.attributes[1].format = MTLVertexFormat.half2
        vertexDescriptor.attributes[1].offset = 16
        vertexDescriptor.attributes[1].bufferIndex = 1
    
        // Single interleaved buffer
        vertexDescriptor.layouts[0].stride = 24
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex
    
        // Render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "vAmiga Metal pipeline"
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        
        // Color attachment
        let colorAttachment = pipelineDescriptor.colorAttachments[0]!
        colorAttachment.pixelFormat = MTLPixelFormat.bgra8Unorm
        colorAttachment.isBlendingEnabled = true
        colorAttachment.rgbBlendOperation = MTLBlendOperation.add
        colorAttachment.alphaBlendOperation = MTLBlendOperation.add
        colorAttachment.sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        colorAttachment.sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        colorAttachment.destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        colorAttachment.destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        do {
            try pipeline = device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Cannot create Metal graphics pipeline")
        }
    }
}
