//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

class Plane
{
    private var vertexCount: Int?
    private var vertexBuffer: MTLBuffer?
    private let modelMatrix: float4x4
    private var texture: MTLTexture!
    
    //MARK: - Init
    
    init(withExtent extent: float2, center: float3, device: MTLDevice) {
        modelMatrix = float4x4(translation: center)
        setupTexture(withDevice: device)
        setupBuffers(withExtent: extent, center: center, device: device)
    }
    
    //MARK: - Private
    
    private func setupTexture(withDevice device: MTLDevice) {
        let imageName = "fruit"
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        let fileExtension = URL(fileURLWithPath: imageName).pathExtension.isEmpty ? "jpg" : nil
        guard let url = Bundle.main.url(forResource: imageName, withExtension: fileExtension)  else {
            fatalError("Failed to load \(imageName)")
        }

        texture = try! textureLoader.newTexture(URL: url, options: textureLoaderOptions)
        print("loaded texture: \(url.lastPathComponent)")
    }
    
    private func setupBuffers(withExtent extent: float2, center: float3, device: MTLDevice) {
        let halfWidth = extent.x / 2
        let halfHeight = extent.y / 2
        let z = center.z
        
        var vertices = [Vertex]()
        vertices.append(Vertex(position: [-halfWidth, halfHeight, z], textureCoordinate: [0, 1]))
        vertices.append(Vertex(position: [-halfWidth, -halfHeight, z], textureCoordinate: [0, 0]))
        vertices.append(Vertex(position: [halfWidth, halfHeight, z], textureCoordinate: [1, 1]))
        vertices.append(Vertex(position: [halfWidth, -halfHeight, z], textureCoordinate: [1, 0]))
        vertices.append(Vertex(position: [-halfWidth, -halfHeight, z], textureCoordinate: [0, 0]))
        vertices.append(Vertex(position: [halfWidth, halfHeight, z], textureCoordinate: [1, 1]))
            
        self.vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeShared)
        vertexCount = vertices.count
    }
}

extension Plane: Renderable
{
    var name: String {
        "Plane"
    }
    
    func render(withRenderEncoder renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        guard let vertexBuffer = vertexBuffer, let vertexCount = vertexCount else {
            print("No vertex data or index count.")
            return
        }
        
        renderEncoder.pushDebugGroup(name)
        
        var _uniforms = uniforms
        _uniforms.modelMatrix = modelMatrix
        renderEncoder.setVertexBytes(&_uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        renderEncoder.setFragmentTexture(texture, index: 2)
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        renderEncoder.popDebugGroup()
    }
}
