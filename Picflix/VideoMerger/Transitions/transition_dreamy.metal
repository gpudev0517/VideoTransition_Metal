//
//  transition_dreamy.metal
//  Picflix
//
//  Created by Khalid on 12/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float2 offset(float progress, float x, float theta) {
    float shifty = 0.03*progress*cos(10.0*(progress+x));
    return float2(0, shifty);
}

kernel void transition_dreamy(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
    prog = 1.0 - prog;
    ngid.x /= outTexture.get_width();
    ngid.y /= outTexture.get_height();
    
    //ngid.y = (1.0 - ngid.y);
    //ngid.x = (1.0 - ngid.x);
    
    
    float aspectRatio = outTexture.get_width() / float(outTexture.get_height());
    float aspectRatio1 = inTexture.get_width() / float(inTexture.get_height());
    float aspectRatio2 = inTexture2.get_width() / float(inTexture2.get_height());
    
    if( prog < 0.0){
        
        
        float2 agid1 = (ngid);
        
        if( aspectRatio < aspectRatio1){
           agid1.x = 0.5 + (agid1.x - 0.5 ) * aspectRatio / aspectRatio1;
        }
        else{
           agid1.y = 0.5 + (agid1.y - 0.5 ) * aspectRatio1 / aspectRatio;
        }
        
        half4 c1(0.0);
        if( agid1.x  >= 0.0 && agid1.x < 1.0 && agid1.y  >= 0.0 && agid1.y < 1.0){
            agid1.x *= inTexture.get_width();
            agid1.y *= inTexture.get_height();
            half4 orig = inTexture.read(uint2(agid1));
            c1 = orig;
        }
        
        outTexture.write(c1, gid);
    }
    else if( prog > 1.0){
        
        float2 agid2 = (ngid);
        
        if( aspectRatio < aspectRatio2){
            agid2.x = 0.5 + (agid2.x - 0.5 ) * aspectRatio / aspectRatio2;
        }
        else{
            agid2.y = 0.5 + (agid2.y - 0.5 ) * aspectRatio2 / aspectRatio;
        }
        
        half4 c2(0.0);
        if( agid2.x  >= 0.0 && agid2.x < 1.0 && agid2.y  >= 0.0 && agid2.y < 1.0){
            agid2.x *= inTexture2.get_width();
            agid2.y *= inTexture2.get_height();
            half4 secOrig = inTexture2.read(uint2(agid2));
            c2 = secOrig;
        }
        outTexture.write(c2, gid);
    }
    else {
        ngid.y = 1.0- ngid.y;
        float2 t1 = ngid + offset(prog, ngid.x, 0.0);
        float2 t2 = ngid + offset(1.0-prog, ngid.x, 3.14);
        
        t1.y = 1.0 - t1.y;
        t2.y = 1.0 - t2.y;
        
        float2 agid1 = (t1);
        
        if( aspectRatio < aspectRatio1){
           agid1.x = 0.5 + (agid1.x - 0.5 ) * aspectRatio / aspectRatio1;
        }
        else{
           agid1.y = 0.5 + (agid1.y - 0.5 ) * aspectRatio1 / aspectRatio;
        }
        
        float2 agid2 = (t2);
        
        if( aspectRatio < aspectRatio2){
            agid2.x = 0.5 + (agid2.x - 0.5 ) * aspectRatio / aspectRatio2;
        }
        else{
            agid2.y = 0.5 + (agid2.y - 0.5 ) * aspectRatio2 / aspectRatio;
        }
        
        half4 fromColor(0.0);
        if( agid1.x  >= 0.0 && agid1.x < 1.0 && agid1.y  >= 0.0 && agid1.y < 1.0){
            agid1.x *= inTexture.get_width();
            agid1.y *= inTexture.get_height();
            fromColor = inTexture.read(uint2(agid1));
        }
        
        half4 toColor(0.0);
        if( agid2.x  >= 0.0 && agid2.x < 1.0 && agid2.y  >= 0.0 && agid2.y < 1.0){
            agid2.x *= inTexture2.get_width();
            agid2.y *= inTexture2.get_height();
            toColor = inTexture2.read(uint2(agid2));
        }
        
//        
//        
//        //tempFromColor.y = abs(1.0 - tempFromColor.y);
//        //tempFromColor.x = 1.0 - tempFromColor.x;
//        //tempToColor.y = abs(1.0 - tempToColor.y);
//        //tempToColor.x = 1.0 - tempToColor.x;
//        tempFromColor.x *= inTexture.get_width();
//        tempFromColor.y *= inTexture.get_height();
//        tempToColor.x *= inTexture2.get_width();
//        tempToColor.y *= inTexture2.get_height();
//        float4 fromColor = inTexture.read(uint2(tempFromColor));
//        float4 toColor = inTexture2.read(uint2(tempToColor));
//        
        
        return outTexture.write(mix(fromColor, toColor, prog),gid);
    }
    
    
}
