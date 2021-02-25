//
//  transition_bounce.metal
//  GLMetalVideo
//
//  Created by Muhammad Khalid on 7/17/19.
//  Copyright © 2019 KMHK. All rights reserved.

#include <metal_stdlib>
#include <metal_texture>
using namespace metal;

kernel void transition_bounce(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                      texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                      texture2d<float, access::write> outTexture [[ texture(2) ]],
                                      device const float *progress [[ buffer(0) ]],
                                      uint2 gid [[ thread_position_in_grid ]])
{
    float4 shadow_colour = float4(0.0, 0.0, 0.0, 0.6);
    float shadow_height = 0.075;
    float bounces = 3.0;
    float PI = 3.14159265358;
    
    float prog = *progress;
    prog = (1.0 - prog);
    float2 ngid = float2(gid);
    ngid.x /= inTexture.get_width();
    ngid.y /= inTexture.get_height();
    //ngid.y = (1.0 - ngid.y);
    
    float time = prog;
    float stime = sin(time * PI / 2.);
    float phase = time * PI * bounces;
    float y = (abs(cos(phase))) * (1.0 - stime);
    float d = ngid.y - y;
   // ngid.y = (1.0 - ngid.y);
    
    float2 temp = float2(ngid.x, ngid.y + (1.0 - y));
    temp.x *= inTexture.get_width();
    //temp.y = 1.0 - temp.y;
    temp.y *= inTexture.get_height();
    
    float4 getFromColor_temp = inTexture.read(uint2(temp));
    float4 getToColor_gid = inTexture2.read(gid);
    
    float4 inner_mix = mix(getToColor_gid,
                          shadow_colour,
                          step(d, shadow_height) * (1.0 - mix(
                                                              ((d / shadow_height) * shadow_colour.a) + (1.0-shadow_colour.a),
                                                              1.0,
                                                              smoothstep(0.95,1.0,prog)
                                                              )
                                                    )
                          );
    float4 outer_mix = mix(inner_mix, getFromColor_temp, step(d,0.0));
    
    return outTexture.write(outer_mix, gid);
}
