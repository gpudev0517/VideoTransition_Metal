//
//  TextureCreater.swift
//  GLMetalVideo
//
//  Created by Mehrooz on 15/07/2019.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import MetalKit
import CoreVideo


class TextureCreater {
    
    static func textureFromImage(_ image: UIImage, device: MTLDevice, textureCache: CVMetalTextureCache) -> MTLTexture? {
    
        var pixelBuffer: CVPixelBuffer?
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue]
        
        var status = CVPixelBufferCreate(nil, Int(image.size.width), Int(image.size.height),
                                         kCVPixelFormatType_32BGRA, attrs as CFDictionary,
                                         &pixelBuffer)
        assert(status == noErr)
        
        let coreImage = CIImage(image: image)!
        let context = CIContext(mtlDevice: device)
        context.render(coreImage, to: pixelBuffer!)
        
        var textureWrapper: CVMetalTexture?
        
        status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           textureCache, pixelBuffer!, nil, .bgra8Unorm,
                                                           CVPixelBufferGetWidth(pixelBuffer!), CVPixelBufferGetHeight(pixelBuffer!), 0, &textureWrapper)
        
        let texture = CVMetalTextureGetTexture(textureWrapper!)!
        
        return texture
        
    }
    
}
