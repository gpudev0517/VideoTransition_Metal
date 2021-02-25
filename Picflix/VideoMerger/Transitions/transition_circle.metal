//
//  transition_circle.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/9/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_circle(texture2d<float, access::read> inTexture [[ texture(0) ]],
                              texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                              texture2d<float, access::write> outTexture [[ texture(2) ]],
                              device const float *progress [[ buffer(0) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
    float2 ngid = float2(gid);
    float prog = *progress;
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();

    float4 orig = inTexture.read(gid);
    float4 secOrig = inTexture2.read(gid);
    
    float2 center = float2(0.5, 0.5);
    float4 backColor = float4(0.1,0.1,0.1,1);
    float distance = length(ngid - center);
    float radius = sqrt(8.0) * abs(prog - 0.5);
    
    if (distance > radius) {
        outTexture.write(backColor, gid);
    }
    else {
        if (prog < 0.5) return outTexture.write(secOrig, gid);
        else return outTexture.write(orig, gid);
    }
}

