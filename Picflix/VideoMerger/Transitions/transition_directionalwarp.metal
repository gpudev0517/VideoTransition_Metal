//
//  transition_directionalwarp.metal
//  Picflix
//
//  Created by Khalid on 11/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void transition_directionalwarp(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
    
    float2 direction = float2(-1.0, 1.0);
    float smoothness = 0.5;
    float2 center = float2(0.5, 0.5);
    
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
        
        ngid.y = (1.0 - ngid.y);
        
        float2 v = normalize(direction);
        v /= abs(v.x) + abs(v.y);
        float d = v.x * center.x + v.y * center.y;
        float m = 1.0 - smoothstep(-smoothness, 0.0, v.x * ngid.x + v.y * ngid.y - (d - 0.5 + prog * (1.0 + smoothness)));
        
        float2 t1 = (ngid - 0.5) * (1.0 - m) + 0.5;
        float2 t2 = (ngid - 0.5) * m + 0.5;
        
        t1.y = 1.0-t1.y;
        t2.y = 1.0-t2.y;
        
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
        
        return outTexture.write(mix(fromColor, toColor, m),gid);
    }
}
