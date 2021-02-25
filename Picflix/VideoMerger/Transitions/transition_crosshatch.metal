//
//  transition_crosshatch.metal
//  Picflix
//
//  Created by Mehrooz Khan on 09/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;

float random2(float2 co) {
  return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

kernel void transition_crosshatch(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
        
        float2 center = float2(0.5);
        float threshold = 3.0;
        float fadeEdge = 0.1;
        
        float dist = distance(center, ngid) / threshold;
        float r = prog - min(random2(float2(ngid.y, 0.0)), random2(float2(0.0, ngid.x)));
        
        half4 fromColor = aspectFillRead(inTexture, outTexture, ngid);
        half4 toColor = aspectFillRead(inTexture2, outTexture, ngid);
        float m = mix(0.0, mix(step(dist, r), 1.0, smoothstep(1.0-fadeEdge, 1.0, prog)), smoothstep(0.0, fadeEdge, prog));
        outTexture.write(mix(fromColor,toColor,m), gid);
    }
}


