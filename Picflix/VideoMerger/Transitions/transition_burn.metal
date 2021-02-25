//
//  transition_burn.metal
//  GLMetalVideo
//
//  Created by Khalid on 14/07/2019.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_burn(texture2d<float, access::read> inTexture [[ texture(0) ]],
                              texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                              texture2d<float, access::write> outTexture [[ texture(2) ]],
                              device const float *progress [[ buffer(0) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
    
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float3 color = float3(0.9,0.4,0.2);
    
    float4 orig = inTexture.read(gid)  + float4((1 - prog) * color, 1.0);
    float4 secOrig = inTexture2.read(gid) + float4(prog * color, 1.0);
    
    return outTexture.write(mix(secOrig,orig,prog), gid);
    
}



