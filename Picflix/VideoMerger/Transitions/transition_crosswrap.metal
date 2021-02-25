//
//  transition_crosswrap.metal
//  Picflix
//
//  Created by Mehrooz Khan on 08/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;


kernel void transition_crosswrap(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
        
        float x = prog;
        x=smoothstep(.0,1.0,(x*2.0+ngid.x-1.0));
        
        float2 agid1 = ((ngid-.5)*(1.-x)+.5);
        
        half4 fromColor = aspectFillRead(inTexture, outTexture, agid1);
        
        float2 agid2 = ((ngid-.5)*x+.5);
        
        half4 toColor = aspectFillRead(inTexture2, outTexture, agid2);
        
        return outTexture.write(mix(fromColor,toColor,prog), gid);
    }
    
    
}


