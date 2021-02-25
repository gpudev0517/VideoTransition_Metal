//
//  transition_linearblur.metal
//  GLMetalVideo
//
//  Created by Mehrooz on 13/07/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

kernel void transition_linearblur(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
    
    half4 c1 = half4(0.0);
    half4 c2 = half4(0.0);
    
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
        
        if( agid1.x  >= 0.0 && agid1.x < 1.0 && agid1.y  >= 0.0 && agid1.y < 1.0){
            agid1.x *= inTexture.get_width();
            agid1.y *= inTexture.get_height();
            half4 orig = inTexture.read(uint2(agid1));
            c1 += orig;
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
        
        if( agid2.x  >= 0.0 && agid2.x < 1.0 && agid2.y  >= 0.0 && agid2.y < 1.0){
            agid2.x *= inTexture2.get_width();
            agid2.y *= inTexture2.get_height();
            half4 secOrig = inTexture2.read(uint2(agid2));
            c2 += secOrig;
        }
        outTexture.write(c2, gid);
    }
    else{
        uniform <float> intensity = 0.1;
        const int passes = 10;

        //float d = length(float2(0.5) - float2(prog));

        float disp = intensity * (0.5 - abs(0.5 - prog));



        for(int xi = 0; xi<passes; xi++) {
            float x = (float(xi) / float(passes)) - 0.5;

            for(int yi=0; yi<passes; yi++) {
                float y = (float(yi) / float(passes)) - 0.5;

                float2 v = float2(x,y);

                float d = disp;
                float2 agid1 = (ngid) + (d*v);
                float2 agid2 = (ngid) + (d*v);
                
                if( aspectRatio < aspectRatio1){
                    agid1.x = 0.5 + (agid1.x - 0.5 ) * aspectRatio / aspectRatio1;
                }
                else{
                    agid1.y = 0.5 + (agid1.y - 0.5 ) * aspectRatio1 / aspectRatio;
                }
                
                if( aspectRatio < aspectRatio2){
                    agid2.x = 0.5 + (agid2.x - 0.5 ) * aspectRatio / aspectRatio2;
                }
                else{
                    agid2.y = 0.5 + (agid2.y - 0.5 ) * aspectRatio2 / aspectRatio;
                }
                
                if( agid1.x  >= 0.0 && agid1.x < 1.0 && agid1.y  >= 0.0 && agid1.y < 1.0){
                    agid1.x *= inTexture.get_width();
                    agid1.y *= inTexture.get_height();
                    half4 orig = inTexture.read(uint2(agid1));
                    c1 += orig;
                }
                
                
                if( agid2.x  >= 0.0 && agid2.x < 1.0 && agid2.y  >= 0.0 && agid2.y < 1.0){
                    agid2.x *= inTexture2.get_width();
                    agid2.y *= inTexture2.get_height();
                    half4 secOrig = inTexture2.read(uint2(agid2));
                    c2 += secOrig;
                }
            }
        }

        c1 /= float(passes * passes);
        c2 /= float(passes * passes);

        //    half4 c1 = inTexture.read(gid);
        //    half4 c2 = inTexture2.read(gid);
        outTexture.write(mix(c1,c2,prog), gid);
        
    }

    
}
