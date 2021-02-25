//
//  transition_bowtiehorizontal.metal
//  GLMetalVideo
//
//  Created by Mehrooz on 7/18/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_bowtiehorizontal(texture2d<float, access::read> inTexture [[ texture(0) ]],
                              texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                              texture2d<float, access::write> outTexture [[ texture(2) ]],
                              device const float *progress [[ buffer(0) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
//    float2 bottom_left = float2(0.0, 1.0);
//    float2 bottom_right = float2(1.0, 1.0);
//    float2 top_left = float2(0.0, 0.0);
//    float2 top_right = float2(1.0, 0.0);
//    float2 center = float2(0.5, 0.5);
}
float check(float2 p1, float2 p2, float2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}
