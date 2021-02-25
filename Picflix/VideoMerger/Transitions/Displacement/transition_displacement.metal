//
//  transition_displacement.metal
//  GLMetalVideo
//
//  Created by Khalid on 13/07/2019.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
#include <metal_texture>
using namespace metal;

kernel void transition_displacement(texture2d<float, access::read> inTexture2 [[ texture(0) ]],
                                  texture2d<float, access::read> inTexture [[ texture(1) ]],
                                  texture2d<float, access::write> outTexture [[ texture(2) ]],
                                  texture2d<float, access::sample> sampleTexture [[ texture(3) ]],
                                    sampler samplr [[sampler(0)]],
                                  device const float *progress [[ buffer(0) ]],
                                  uint2 gid [[ thread_position_in_grid ]])
{
    
    float strength = 0.5;
    float prog = *progress;
    prog = (1.0 - prog);
    float2 ngid = float2(gid);
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    ngid.y = (1.0 - ngid.y);
    
    float4 clr = sampleTexture.sample(samplr, ngid);
    float displacement = (clr.r * strength);
    //displacement += prog/displacement;
    float2 uvFrom = float2(ngid.x + prog * displacement, ngid.y);
    float2 uvTo = float2(ngid.x - (1.0 - prog) * displacement, ngid.y);
    
    uvFrom.x *= inTexture.get_width();
    uvFrom.y = (1.0 - uvFrom.y);
    uvFrom.y *= inTexture.get_height();
    
    uvTo.x *= inTexture.get_width();
    uvTo.y = (1.0 - uvTo.y);
    uvTo.y *= inTexture.get_height();
    
    if (uvTo.x < 0 ) {
        uvTo.x = abs(uvTo.x);
        //return outTexture.write(float4(0.5,0.1,0.1,1), gid);
    }
    
    float4 orig = inTexture.read(uint2(uvTo));
    float4 secOrig = inTexture2.read(uint2(uvFrom));
    
    if (uvFrom.y < 0 ) {
        //uvTo.x = 0.0;
        return outTexture.write(float4(0.5,0.1,0.1,1), gid);
    }
//    else {
//        return outTexture.write(mix(secOrig, orig, prog), gid);
//    }
    return outTexture.write(mix(secOrig, orig, prog), gid);
   
    
}
