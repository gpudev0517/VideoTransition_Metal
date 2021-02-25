//
//  transition_bowtievertical.metal
//  Picflix
//
//  Created by Khalid on 12/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float check1(float2 p1, float2 p2, float2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool PointInTriangle (float2 pt, float2 p1, float2 p2, float2 p3)
{
    bool b1, b2, b3;
    b1 = check1(pt, p1, p2) < 0.0;
    b2 = check1(pt, p2, p3) < 0.0;
    b3 = check1(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}

bool in_top_triangle(float2 p, float progress){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(0.5, progress);
    vertex2 = float2(0.5 -progress, 0.0);
    vertex3 = float2(0.5 +progress, 0.0);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

bool in_bottom_triangle(float2 p, float progress){
    float2 vertex1, vertex2, vertex3;
    vertex1 = float2(0.5, 1.0 - progress);
    vertex2 = float2(0.5-progress, 1.0);
    vertex3 = float2(0.5+progress, 1.0);
    if (PointInTriangle(p, vertex1, vertex2, vertex3))
    {
        return true;
    }
    return false;
}

float blur_edge(float2 bot1, float2 bot2, float2 top, float2 testPt)
{
    float2 lineDir = bot1 - top;
    float2 perpDir = float2(lineDir.y, -lineDir.x);
    float2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));
    
    lineDir = bot2 - top;
    perpDir = float2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);
    
    if (min_dist < 0.005) {
        return min_dist / 0.005;
    }
    else  {
        return 1.0;
    };
}

kernel void transition_bowtievertical(texture2d<half, access::read> inTexture [[ texture(0) ]],
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
    
    float2 agid1 = (ngid);
    
    if( aspectRatio < aspectRatio1){
       agid1.x = 0.5 + (agid1.x - 0.5 ) * aspectRatio / aspectRatio1;
    }
    else{
       agid1.y = 0.5 + (agid1.y - 0.5 ) * aspectRatio1 / aspectRatio;
    }
    
    float2 agid2 = (ngid);
    
    if( aspectRatio < aspectRatio2){
        agid2.x = 0.5 + (agid2.x - 0.5 ) * aspectRatio / aspectRatio2;
    }
    else{
        agid2.y = 0.5 + (agid2.y - 0.5 ) * aspectRatio2 / aspectRatio;
    }
    
    if( prog < 0.0){
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
        
        if (in_top_triangle(ngid,prog))
        {
            if (prog < 0.1)
            {
                return outTexture.write(fromColor,gid);
            }
            if (ngid.y < 0.5)
            {
                float2 vertex1 = float2(0.5, prog);
                float2 vertex2 = float2(0.5-prog, 0.0);
                float2 vertex3 = float2(0.5+prog, 0.0);
                return outTexture.write(mix(
                           fromColor,
                           toColor,
                           blur_edge(vertex2, vertex3, vertex1, ngid)
                           ),gid);
            }
            else
            {
                if (prog > 0.0)
                {
                    return outTexture.write(toColor,gid);
                }
                else
                {
                    return outTexture.write(fromColor,gid);
                }
            }
        }
        else if (in_bottom_triangle(ngid,prog))
        {
            if (ngid.y >= 0.5)
            {
                float2 vertex1 = float2(0.5, 1.0-prog);
                float2 vertex2 = float2(0.5-prog, 1.0);
                float2 vertex3 = float2(0.5+prog, 1.0);
                return outTexture.write(mix(
                           fromColor,
                           toColor,
                           blur_edge(vertex2, vertex3, vertex1, ngid)
                           ),gid);
            }
            else
            {
                return outTexture.write(fromColor,gid);
            }
        }
        else {
            return outTexture.write(fromColor,gid);
        }
        
    }
    
    
    
}
