//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

protocol Renderable
{
    var name: String { get }
    func render(withRenderEncoder renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms)
}
