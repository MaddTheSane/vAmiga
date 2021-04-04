// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class SplashScreen: Layer {
        
    var bgTexture: MTLTexture! = nil
    var bgRect: Node?
    
    var vertexUniforms = VertexUniforms(mvp: matrix_identity_float4x4)
    var fragmentUniforms = FragmentUniforms(alpha: 1.0,
                                            white: 0.0,
                                            dotMaskWidth: 0,
                                            dotMaskHeight: 0,
                                            scanlineDistance: 0)
    
    override init(renderer: Renderer) {

        super.init(renderer: renderer)

        alpha.set(1.0)        
        let img = NSImage.init(named: "background")!
        bgTexture = img.toTexture(device: device, vflip: false)
        
        renderer.metalAssert(bgTexture != nil,
                             "The background texture could not be allocated.")
    }

    func setupFragmentShader(encoder: MTLRenderCommandEncoder) {
        
        // Setup textures
        encoder.setFragmentTexture(bgTexture, index: 0)
        encoder.setFragmentTexture(bgTexture, index: 1)
        
        // Select the texture sampler
        encoder.setFragmentSamplerState(ressourceManager.samplerLinear, index: 0)

        // Setup uniforms
        encoder.setFragmentBytes(&renderer.shaderOptions,
                                 length: MemoryLayout<ShaderOptions>.stride,
                                 index: 0)
        encoder.setFragmentBytes(&fragmentUniforms,
                                 length: MemoryLayout<FragmentUniforms>.stride,
                                 index: 1)
    }
    
    func render(_ encoder: MTLRenderCommandEncoder) {
        
        // Configure vertex shader
        encoder.setVertexBytes(&vertexUniforms,
                               length: MemoryLayout<VertexUniforms>.stride,
                               index: 1)
        
        // Configure the fragment shader
        setupFragmentShader(encoder: encoder)
        
        // Render
        bgRect!.drawPrimitives(encoder)
    }
}
