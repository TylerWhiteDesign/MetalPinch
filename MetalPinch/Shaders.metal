//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut vertex_main(uint vertexID [[ vertex_id ]], constant Vertex *vertexArray [[ buffer(0) ]], constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut vertex_out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * float4(vertexArray[vertexID].position, 1),
        .textureCoordinate = vertexArray[vertexID].textureCoordinate
    };
    
    return vertex_out;
}

fragment float4 fragment_main(VertexOut vertex_in [[stage_in]], texture2d<float> colorTexture [[ texture(2) ]]) {
    constexpr sampler textureSampler;
    float3 baseColor = colorTexture.sample(textureSampler, vertex_in.textureCoordinate).rgb;
    
    return float4(baseColor, 1);
}
