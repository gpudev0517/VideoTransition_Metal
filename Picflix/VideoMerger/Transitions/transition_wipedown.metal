//
//  transition_wipedown.metal
//  GLMetalVideo
//
//  Created by Khalid on 14/07/2019.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

kernel void transition_wipedown(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  device const float *progress [[ buffer(0) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    float2 ngid = float2(gid);
    float prog = *progress;
    prog = (1.0 - prog);
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    ngid.y = (1.0 - ngid.y);
    
    float2 p = ngid.xy / float2(1.0).xy;
    
    float c = step(1.0 - p.y, prog);
    
    p.x *= inTexture.get_width();
    p.y = (1.0 - p.y);
    p.y *= inTexture.get_height();

    float4 a = inTexture.read(uint2(p));
    float4 b = inTexture2.read(uint2(p));
    
    
    
    return outTexture.write(mix(a,b,c), gid);
    
}



