//
//  transition_kaleidoscope.metal
//  Picflix
//
//  Created by Mehrooz Khan on 09/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;


kernel void transition_kaleidoscope(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
        
        float speed = 1.0;
        float angle = 1.0;
        float power = 1.5;
        
        float2 p = ngid.xy / float2(1.0).xy;
        float2 q = float2(p);
        float t = pow(prog, power)*speed;
        p = p -0.5;
        for (int i = 0; i < 7; i++) {
          p = float2(sin(t)*p.x + cos(t)*p.y, sin(t)*p.y - cos(t)*p.x);
          t += angle;
          p = abs(fmod(p, 2.0) - 1.0);
        }
        abs(fmod(p, 1.0));
        
        half4 fromColor1 = aspectFillRead(inTexture, outTexture, q);
        half4 toColor1 = aspectFillRead(inTexture2, outTexture, q);
        half4 m1 = mix(fromColor1, toColor1, prog);
        
        half4 fromColor2 = aspectFillRead(inTexture, outTexture, p);
        half4 toColor2 = aspectFillRead(inTexture2, outTexture, p);
        half4 m2 = mix(fromColor2, toColor2, prog);
        
        outTexture.write(mix(m1, m2, 1.0 - 2.0*abs(prog - 0.5)), gid);
    }
}


