//
//  CheckBounds.h
//  Picflix
//
//  Created by Khalid on 13/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#ifndef CheckBounds_h
#define CheckBounds_h
float toBlack(float value);
float toBounds(float value);
float fixBounds(float value);
half4 aspectFillRead(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, float2 ngid);
half4 aspectFitRead(texture2d<half, access::read> inTexture, texture2d<half, access::write> outTexture, float2 ngid);
#endif /* CheckBounds_h */
