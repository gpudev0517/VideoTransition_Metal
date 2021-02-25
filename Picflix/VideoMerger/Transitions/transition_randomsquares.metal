//
//  transition_randomsquares.metal
//  Picflix
//
//  Created by Mehrooz Khan on 09/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;

float random1 (float2 co) {
  return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

kernel void transition_randomsquares(texture2d<half, access::read> inTexture [[ texture(0) ]],
                                   texture2d<half, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<half, access::write> outTexture [[ texture(2) ]],
                                   device const float *progress [[ buffer(0) ]],
                                   uint2 gid [[ thread_position_in_grid ]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    float2 ngid = float2(gid);
    float prog = *progress;
    
    prog = 1.0-prog;
    ngid.x /= float(outTexture.get_width());
    ngid.y /= float(outTexture.get_height());
    
    if( prog < 0.0){
        
        half4 c1 = aspectFillRead(inTexture, outTexture, ngid);

        outTexture.write(c1, gid);
    }
    else if( prog > 1.0){
        
        half4 c2 = aspectFillRead(inTexture2, outTexture, ngid) ;
        
        outTexture.write(c2, gid);
    }
    else {
        
        int2 size = int2(10, 10);
        float smoothness = 0.5;

        float r = random1(floor(float2(size) * ngid));
        float m = smoothstep(0.0, -smoothness, r - (prog * (1.0 + smoothness)));

        half4 fromColor = aspectFillRead(inTexture, outTexture, ngid);

        half4 toColor = aspectFillRead(inTexture2, outTexture, ngid);

        outTexture.write(mix(fromColor,toColor,m), gid);
        
    }
    
    
}


