//
//  VideoMerger.swift
//  GLMetalVideo
//
//  Created by Mehrooz on 7/8/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import CoreVideo

/*
 RenderPixelBuffers is used to maintain a reference to the pixel buffer until the Metal rendering
 is complete. This is because when CVMetalTextureCacheCreateTextureFromImage is used to create a
 Metal texture (CVMetalTexture) from the IOSurface that backs the CVPixelBuffer, the
 CVMetalTextureCacheCreateTextureFromImage doesn't increment the use count of the IOSurface; only
 the CVPixelBuffer, and the CVMTLTexture own this IOSurface. Therefore we must maintain a reference
 to the pixel buffer until the Metal rendering is done.
 */
class RenderPixelBuffers {
    var foregroundTexture: CVPixelBuffer?
    var backgroundTexture: CVPixelBuffer?
    var destinationTexture: CVPixelBuffer?

    init(_ foregroundTexture: CVPixelBuffer, backgroundTexture: CVPixelBuffer, destinationTexture: CVPixelBuffer) {
        self.foregroundTexture = foregroundTexture
        self.backgroundTexture = backgroundTexture
        self.destinationTexture = destinationTexture
    }
}

extension MTLTexture {
    
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
    
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}

protocol VideoMergerDelegate {
    func videosMergingSuccessfullyCompleted(url: URL)
    func videosMergingFailed()
    func videoMergingProgress(_ progress: CGFloat)
}

class VideoMerger {
    var mediaSource1 : AnyObject
    var mediaSource2 : AnyObject
    var exportURL : URL
    
    var delegate : VideoMergerDelegate
    
    init(media1: AnyObject, media2: AnyObject, export: URL, delegate : VideoMergerDelegate) {
        mediaSource1 = media1
        mediaSource2 = media2
        exportURL = export
        self.delegate = delegate
    }
    //AVAsset(url: videoUrl1)
    func startRendering(function: String, transitionSeconds: Double, videoSize: CGSize, duration: Int, duration1: Int) {
        
        guard let composition = VideoCompositionRender(asset: mediaSource1, asset1: mediaSource2, function: function, transitionSeconds: transitionSeconds, videoSize: videoSize, duration: duration, duration1: duration1) else {
            delegate.videosMergingFailed()
            return
        }
        
        guard let videoWriter = VideoWriter(outputFileURL: exportURL, render: composition, videoSize: videoSize) else {
            delegate.videosMergingFailed()
            return
        }
        videoWriter.delegate = self.delegate
        let writer = videoWriter
        
        writer.startRender(url: exportURL)
    }
}

