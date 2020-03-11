//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

class Scene
{
    private(set) weak var renderer: Renderer!
    private(set) var renderables = [Renderable]()
    private(set) var renderablesPipelineState: MTLRenderPipelineState?
    
    private var cameraScale: Float = 1
    private var cameraCenter: float2 = [0, 0]
    private let cameraMinScale: Float = 1
    private let cameraMaxScale: Float = 10
    private var isPinching = false
    private var pinchViewCenterStart: float2?
    private var pinchWorldCenterStart: float2?
    private var pinchCameraCenterStart: float2?
    private var pinchCameraScaleStart: Float?
    
    //MARK: - Init
    
    init(withRenderer renderer: Renderer) {
        self.renderer = renderer
        self.renderer.uniforms.viewMatrix = float4x4.identity()
        self.renderer.uniforms.modelMatrix = float4x4.identity()
        setupRenderablesPipelineStateIfNecessary()
        setupModels()
    }
    
    //MARK: - Public
    
    func updateViewMatrix() {
        let translationMatrix = float4x4(translation: float3(cameraCenter, 0)).inverse
        
        let scaleTranslationMatrix = float4x4(translation: [cameraCenter.x, cameraCenter.y, 0])
        let scaleMatrix = float4x4(scaling: [cameraScale, cameraScale, 1])
        
        renderer.uniforms.viewMatrix = translationMatrix * scaleTranslationMatrix * scaleMatrix * scaleTranslationMatrix.inverse
    }
    
    //MARK: - Private
    
    private func setupModels() {
        let plane = Plane(withExtent: [0.5, 0.5], center: [0, 0, 0], device: renderer.device)
        renderables.append(plane)
    }
    
    //MARK: - Setup
    
    private func setupRenderablesPipelineStateIfNecessary() {
        guard renderablesPipelineState == nil else {
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = renderer.library.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = renderer.library.makeFunction(name: "fragment_main")
        pipelineDescriptor.colorAttachments[0].pixelFormat = renderer.metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            let pipelineState = try renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            self.renderablesPipelineState = pipelineState
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    //MARK: - Rendering
    
    func render(withCommandBuffer commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        guard let renderablesPipelineState = renderablesPipelineState else {
            print("No renderables pipeline state.")
            return
        }
        
        renderEncoder.setRenderPipelineState(renderablesPipelineState)
        
        for renderable in renderables {
            renderable.render(withRenderEncoder: renderEncoder, uniforms: uniforms)
        }
    }
    
    //MARK: - Coordinate Spaces
    
    func convertFromUIKitSpaceToNDCSpace(_ point: CGPoint, inSize size: CGSize, isVector: Bool) -> float2 {
        var ndcPoint = float2((Float(point.x) / Float(size.width)) * Renderer.ndcSpan.x, (Float(point.y) / Float(size.height)) * Renderer.ndcSpan.y)
        if !isVector {
            ndcPoint = float2(ndcPoint.x - 1, ndcPoint.y - 1)
        }
        ndcPoint.y = -ndcPoint.y
        return ndcPoint
    }
    
    func convertFromNDCSpaceToViewSpace(_ point: float2, isVector: Bool) -> float2 {
        let viewPoint = renderer.uniforms.projectionMatrix.inverse * float4(point.x, point.y, 0, isVector ? 0 : 1)
        return float2(viewPoint.x, viewPoint.y)
    }
    
    func convertFromViewSpaceToWorldSpace(_ point: float2, isVector: Bool) -> float2 {
        let worldPoint = renderer.uniforms.viewMatrix.inverse * float4(point.x, point.y, 0, isVector ? 0 : 1)
        return float2(worldPoint.x, worldPoint.y)
    }
}

extension Scene: TouchMetalViewDelegate
{
    func touchMetalView(_ touchMetalView: TouchMetalView, didPinchWithPinchGestureRecognizer pinchGestureRecognizer: UIPinchGestureRecognizer) {
        let shouldIgnoreOneTouch = pinchGestureRecognizer.numberOfTouches == 1 && pinchGestureRecognizer.state != .ended
        if shouldIgnoreOneTouch {
            return
        }
        let location = pinchGestureRecognizer.location(in: touchMetalView)
        let ndcPoint = convertFromUIKitSpaceToNDCSpace(location, inSize: touchMetalView.bounds.size, isVector: false)
        let viewPoint = convertFromNDCSpaceToViewSpace(ndcPoint, isVector: false)
        let worldPoint = convertFromViewSpaceToWorldSpace(viewPoint, isVector: false)
        
        switch pinchGestureRecognizer.state {
        case .began:
            isPinching = true
            pinchViewCenterStart = viewPoint
            pinchWorldCenterStart = worldPoint
            pinchCameraCenterStart = cameraCenter
            pinchCameraScaleStart = cameraScale
        case .changed:
            break
        default:
            isPinching = false
            pinchViewCenterStart = nil
            pinchWorldCenterStart = nil
            pinchCameraCenterStart = nil
            pinchCameraScaleStart = nil
        }
        
        cameraScale = min(max(Float(cameraScale * Float(pinchGestureRecognizer.scale)), cameraMinScale), cameraMaxScale)
        pinchGestureRecognizer.scale = 1
        
        if let pinchCameraCenterStart = pinchCameraCenterStart, let pinchWorldCenterStart = pinchWorldCenterStart, let pinchCameraScaleStart = pinchCameraScaleStart, let pinchViewCenterStart = pinchViewCenterStart {
            let pinchCenterViewTranslation = viewPoint - pinchViewCenterStart
            let pinchCentersVector = pinchCameraCenterStart - pinchWorldCenterStart
            let ratioVector = ((pinchCameraScaleStart / cameraScale) * pinchCentersVector)
            let newCameraCenter = pinchWorldCenterStart + ratioVector + (-pinchCenterViewTranslation / cameraScale)
            cameraCenter = newCameraCenter
        }
        
        updateViewMatrix()
    }
        
    func touchMetalView(_ touchMetalView: TouchMetalView, didPanWithPanGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) {
        let uiKitTranslation = panGestureRecognizer.translation(in: touchMetalView)
        let ndcTranslation = convertFromUIKitSpaceToNDCSpace(uiKitTranslation, inSize: touchMetalView.bounds.size, isVector: true)
        let viewTranslation = convertFromNDCSpaceToViewSpace(ndcTranslation, isVector: true)
        let worldTranslation = convertFromViewSpaceToWorldSpace(viewTranslation, isVector: true)
        cameraCenter = cameraCenter - worldTranslation
        panGestureRecognizer.setTranslation(.zero, in: touchMetalView)
        
        updateViewMatrix()
    }
}
