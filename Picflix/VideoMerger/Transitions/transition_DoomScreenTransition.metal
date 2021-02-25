//
//  transition_DoomScreenTransition.metal
//  Picflix
//
//  Created by Mehrooz Khan on 09/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
#include "CheckBounds.h"
using namespace metal;

float rand(int num) {
  return fract(fmod(float(num) * 67123.313, 12.0) * sin(float(num) * 10.3) * cos(float(num)));
}

float wave(int num, float frequency, int bars) {
  float fn = float(num) * frequency * 0.1 * float(bars);
  return cos(fn * 0.5) * cos(fn * 0.13) * sin((fn+10.0) * 0.3) / 2.0 + 0.5;
}

float drip(int num, int bars, float dripScale) {
  return sin(float(num) / float(bars - 1) * 3.141592) * dripScale;
}

float pos(int num, float noise, int bars, float frequency, float dripScale) {
  return (noise == 0.0 ? wave(num, frequency, bars) : mix(wave(num, frequency, bars), rand(num), noise)) + (dripScale == 0.0 ? 0.0 : drip(num, bars, dripScale));
}

kernel void transition_DoomScreenTransition(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
        
        // Number of total bars/columns
        int bars = 30;

        // Multiplier for speed ratio. 0 = no variation when going down, higher = some elements go much faster
        float amplitude = 2;

        // Further variations in speed. 0 = no noise, 1 = super noisy (ignore frequency)
        float noise = 0.1;

        // Speed variation horizontally. the bigger the value, the shorter the waves
        float frequency = 0.5;

        // How much the bars seem to "run" from the middle of the screen first (sticking to the sides). 0 = no drip, 1 = curved drip
        float dripScale = 0.5;
        
        int bar = int(ngid.x * (float(bars)));
        float scale = 1.0 + pos(bar, noise, bars, frequency, dripScale) * amplitude;
        float phase = prog * scale;
        float posY = 1.0 - ngid.y / float2(1.0).y;
        
        if (phase + posY < 1.0) {
            float2 toRead = float2(ngid.x, ngid.y + mix(0.0, float2(-1.0).y, phase)) / float2(1.0).xy;
            half4 color = aspectFillRead(inTexture, outTexture, toRead);
            outTexture.write(color, gid);
        }
        else {
            float2 toRead = ngid.xy / float2(1.0).xy;
            half4 color = aspectFillRead(inTexture2, outTexture, toRead);
            outTexture.write(color, gid);
        }
    }
}


