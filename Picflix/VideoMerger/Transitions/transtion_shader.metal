//
//  transtion_shader.metal
//  GLMetalVideo
//
//  Created by MacMaster on 7/9/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transtion_shader(texture2d<float, access::read> inTexture [[ texture(0) ]],
                        texture2d<float, access::write> inTexture2 [[ texture(1) ]],
                        texture2d<float, access::write> outTexture [[ texture(2) ]],
                        device const float *time [[ buffer(0) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    float2 ngid = float2(gid);
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    
    float4 orig = inTexture.read(gid);
    
    float2 p = -1.0 + 2.0 * orig.xy;
    
    float iGlobalTime = *time;
    
    float x = p.x;
    float y = p.y;
    
    float mov0 = x + y + 1.0 * cos( 2.0*sin(iGlobalTime)) + 11.0 * sin(x/1.);
    float mov1 = y / 0.9 + iGlobalTime;
    float mov2 = x / 0.2;
    
    float c1 = abs( 0.5 * sin(mov1 + iGlobalTime) + 0.5 * mov2 - mov1 - mov2 + iGlobalTime );
    float c2 = abs( sin(c1 + sin(mov0/2. + iGlobalTime) + sin(y/1.0 + iGlobalTime) + 3.0 * sin((x+y)/1.)) );
    float c3 = abs( sin(c2 + cos(mov1 + mov2 + c2) + cos(mov2) + sin(x/1.)) );
    
    float4 colorAtPixel = float4(c1, c2, c3, 1.0);
    outTexture.write(colorAtPixel, gid);
}

