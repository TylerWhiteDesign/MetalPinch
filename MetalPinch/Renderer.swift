//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

class Renderer: NSObject
{
    static let ndcSpan: float3 = [2, 2, 1]
    
    let metalView: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    var uniforms = Uniforms()
    
    var scene: Scene? {
        didSet {
            sceneDidChange()
        }
    }
    
    //MARK: - Init
    
    init(metalView: MTKView) {
        self.metalView = metalView
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create device.")
        }
        self.device = device
        
        guard let commandQueue = self.device.makeCommandQueue() else {
            fatalError("Could not make command queue.")
        }
        self.commandQueue = commandQueue
        
        guard let library = self.device.makeDefaultLibrary() else {
            fatalError("Could not make library.")
        }
        self.library = library
        
        super.init()
        
        self.metalView.delegate = self
        self.metalView.device = device
        self.metalView.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.metalView.depthStencilPixelFormat = .depth32Float
        
        mtkView(self.metalView, drawableSizeWillChange: self.metalView.drawableSize)
    }
    
    private func updateProjectionMatrix(withSize size: CGSize) {
        let aspect: Float = Float(size.width / size.height)
        let scaleMatrix = float4x4(scaling: [1, aspect, 1])
        uniforms.projectionMatrix = scaleMatrix
    }
    
    //MARK: - Private
    
    private func sceneDidChange() {
        guard let scene = scene else {
            print("No scene")
            return
        }

        if let touchMetalView = self.metalView as? TouchMetalView {
            touchMetalView.touchDelegate = scene
        }
    }
}

//MARK: - MTKViewDelegate

extension Renderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateProjectionMatrix(withSize: size)
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
                
        if let scene = scene {
            scene.render(withCommandBuffer: commandBuffer, renderEncoder: renderEncoder, uniforms: uniforms)
        }
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
