//
//  transition_squareswire.metal
//  Picflix
//
//  Created by Mehrooz Khan on 09/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;


kernel void transition_squareswire(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
        
        int2 squares = int2(10,10);
        float2 direction = float2(1.0, 0.5);
        float smoothness = 1.6;
        float2 center = float2(0.5, 0.5);
        
        float2 v = normalize(direction);
        v /= abs(v.x)+abs(v.y);
        float d = v.x * center.x + v.y * center.y;
        float offset = smoothness;
        float pr = smoothstep(-offset, 0.0, v.x * ngid.x + v.y * ngid.y - (d-0.5+prog*(1.+offset)));
        float2 squarep = fract(ngid*float2(squares));
        float2 squaremin = float2(pr/2.0);
        float2 squaremax = float2(1.0 - pr/2.0);
        float a = (1.0 - step(prog, 0.0)) * step(squaremin.x, squarep.x) * step(squaremin.y, squarep.y) * step(squarep.x, squaremax.x) * step(squarep.y, squaremax.y);
        
        half4 fromColor = aspectFillRead(inTexture, outTexture, ngid);
        
        half4 toColor = aspectFillRead(inTexture2, outTexture, ngid);
        
        outTexture.write(mix(fromColor,toColor,a), gid);
    }
    
    
}


