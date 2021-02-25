//
//  transition_crosszoom.metal
//  Picflix
//
//  Created by Khalid on 12/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


float Linear_ease(float begin, float change, float duration, float time) {
    return change * time / duration + begin;
}

float Exponential_easeInOut(float begin, float change, float duration, float time) {
    if (time == 0.0)
        return begin;
    else if (time == duration)
        return begin + change;
    time = time / (duration / 2.0);
    if (time < 1.0)
        return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
    return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

float Sinusoidal_easeInOut(float begin, float change, float duration, float time) {
    const float PI = 3.141592653589793;
    return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
}

float rand1 (float2 co) {
    return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
}

float3 crossFade(float2 uv, float dissolve,
                 texture2d<float, access::read> inTexture,
                 texture2d<float, access::read> inTexture2,
                 float aspectRatio,
                 float aspectRatio1,
                 float aspectRatio2)
{
    
    float2 agid1 = (uv);
    
    if( aspectRatio < aspectRatio1){
       agid1.x = 0.5 + (agid1.x - 0.5 ) * aspectRatio / aspectRatio1;
    }
    else{
       agid1.y = 0.5 + (agid1.y - 0.5 ) * aspectRatio1 / aspectRatio;
    }
    
    float2 agid2 = (uv);
    
    if( aspectRatio < aspectRatio2){
        agid2.x = 0.5 + (agid2.x - 0.5 ) * aspectRatio / aspectRatio2;
    }
    else{
        agid2.y = 0.5 + (agid2.y - 0.5 ) * aspectRatio2 / aspectRatio;
    }
    
    float4 fromColor(0.0);
    if( agid1.x  >= 0.0 && agid1.x < 1.0 && agid1.y  >= 0.0 && agid1.y < 1.0){
        agid1.x *= inTexture.get_width();
        agid1.y *= inTexture.get_height();
        fromColor = inTexture.read(uint2(agid1));
    }
    
    float4 toColor(0.0);
    if( agid2.x  >= 0.0 && agid2.x < 1.0 && agid2.y  >= 0.0 && agid2.y < 1.0){
        agid2.x *= inTexture2.get_width();
        agid2.y *= inTexture2.get_height();
        toColor = inTexture2.read(uint2(agid2));
    }
    
//    float2 tempFromColor = float2(toBounds(uv.x),toBounds(uv.y));
//    float2 tempToColor = float2(toBounds(uv.x),toBounds(uv.y));
//    //tempFromColor.y = 1.0 - tempFromColor.y;
//    //tempToColor.y = 1.0 - tempToColor.y;
//    tempFromColor.x *= inTexture.get_width();
//    tempFromColor.y *= inTexture.get_height();
//    tempToColor.x *= inTexture.get_width();
//    tempToColor.y *= inTexture.get_height();
//    float4 fromColor = inTexture.read(uint2(tempFromColor));
//    float4 toColor = inTexture2.read(uint2(tempToColor));

    return mix(fromColor.rgb, toColor.rgb, dissolve);
}

kernel void transition_crosszoom(texture2d<float, access::read> inTexture [[ texture(0) ]],
                                   texture2d<float, access::read> inTexture2 [[ texture(1) ]],
                                   texture2d<float, access::write> outTexture [[ texture(2) ]],
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
        
        float4 c1(0.0);
        if( agid1.x  >= 0.0 && agid1.x <= 1.0 && agid1.y  >= 0.0 && agid1.y <= 1.0){
            agid1.x *= inTexture.get_width();
            agid1.y *= inTexture.get_height();
            float4 orig = inTexture.read(uint2(agid1));
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
        
        float4 c2(0.0);
        if( agid2.x  >= 0.0 && agid2.x <= 1.0 && agid2.y  >= 0.0 && agid2.y <= 1.0){
            agid2.x *= inTexture2.get_width();
            agid2.y *= inTexture2.get_height();
            float4 secOrig = inTexture2.read(uint2(agid2));
            c2 = secOrig;
        }
        outTexture.write(c2, gid);
    }
    else{
        //ngid.y = 1.0 - ngid.y;
        
        float strength = 0.4;

        //const float PI = 3.141592653589793;

        float2 texCoord = ngid.xy / float2(1.0).xy;

        // Linear interpolate center across center half of the image
        float2 center = float2(Linear_ease(0.25, 0.5, 1.0, prog), 0.5);
        float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, prog);

        // Mirrored sinusoidal loop. 0->strength then strength->0
        /*float*/ strength = Sinusoidal_easeInOut(0.0, strength, 0.5, prog);

        float3 color = float3(0.0);
        float total = 0.0;
        float2 toCenter = center - texCoord;

        /* randomize the lookup values to hide the fixed number of samples */
        float offset = rand1(ngid);

        for (float t = 0.0; t <= 40.0; t++) {
            float percent = (t + offset) / 40.0;
            float weight = 4.0 * (percent - percent * percent);
            color += crossFade(texCoord + toCenter * percent * strength, dissolve,
                               inTexture,
                               inTexture2, aspectRatio, aspectRatio1, aspectRatio2) * weight;
            total += weight;
        }

        return outTexture.write(float4(color / total, 1.0),gid);
    }

    
}
