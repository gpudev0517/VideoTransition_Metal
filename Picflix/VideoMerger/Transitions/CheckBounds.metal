//
//  CheckBounds.metal
//  Picflix
//
//  Created by Khalid on 13/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "CheckBounds.h"

float toBlack(float value) {
    if (value > 1.0){
        return float(0.0);
    } else if (value < 0.0) {
        return float(0.0);
    } else {
        return value;
    }
}
    
float toBounds(float value) {
    if (value > 1.0){
        return float(1.0);
    } else if (value < 0.0) {
        return float(0.0);
    } else {
        return value;
    }
}

float fixBounds(float value){
    float temp = 0;
    if (value > 1.0){
        temp = 1.0 - value;
        return value+temp+temp;
    } else if (value < 0.0) {
        temp = 1.0-value;
        return 1.0-temp;
    } else {
        return value;
    }
}


half4 aspectFillRead(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, float2 ngid) {
    
    float aspectRatio = outTexture.get_width() / float(outTexture.get_height());
    float aspectRatio1 = inTexture.get_width() / float(inTexture.get_height());
    
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
    return c1;
    
}

half4 aspectFitRead(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, float2 ngid) {
    
    float aspectRatio = outTexture.get_width() / float(outTexture.get_height());
    float aspectRatio1 = inTexture.get_width() / float(inTexture.get_height());
    
    float2 agid1 = (ngid);
    
    if( aspectRatio > aspectRatio1){
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
    return c1;
    
}
