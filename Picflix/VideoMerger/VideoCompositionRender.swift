//
//  VideoCompositionRender.swift
//  Picflix
//
//  Created by Mehrooz on 10/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import CoreVideo

final class VideoCompositionRender {
    
    fileprivate var pixelBuffers: RenderPixelBuffers?
    
    let header_reader: VideoSeqReader
    let tail_reader: VideoSeqReader
    
    let header_duration : CMTime
    let tail_duration : CMTime
    
    var presentationTime : CMTime = CMTime.zero
    
    var frameCount : Float = 0.0
    
    var transtionSecondes : Double = 1
    
    var transtion_function = "transition_none"
    
    var inputTime: CFTimeInterval?
    
    var pixelBuffer: CVPixelBuffer?
    
    var videoSize: CGSize = CGSize(width: 1280, height: 720)
    
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue
    private var computePipelineState: MTLComputePipelineState
    var device: MTLDevice
    
    init?(asset: AnyObject, asset1: AnyObject, function: String, transitionSeconds: Double, videoSize: CGSize, duration: Int, duration1: Int) {
        
        guard let reader1 = VideoSeqReader(asset: asset, frameRate: 30, durationTime: CMTime(value: CMTimeValue(duration * 1000), timescale: 1000)),
            let reader2 = VideoSeqReader(asset: asset1, frameRate: 30, durationTime: CMTime(value: CMTimeValue(duration1 * 1000), timescale: 1000))
            else {
            return nil
        }
        self.videoSize = videoSize
        header_reader = reader1
        tail_reader = reader2
        
        self.datas = [UInt8](repeating: 0, count: Int(videoSize.width*videoSize.height*4))
        
        transtion_function = function
        
        if asset as? AVAsset != nil {
            header_duration = asset.duration
        }
        else{
            header_duration = header_reader.totalTime
        }
        
        if asset1 as? AVAsset != nil {
            tail_duration = asset1.duration
        }
        else{
            tail_duration = tail_reader.totalTime
        }
        
        self.transtionSecondes = transitionSeconds
        
        // Get the default metal device and create command queue.
        guard let metalDevice = MTLCreateSystemDefaultDevice(), let queue = metalDevice.makeCommandQueue() else {
            return nil
        }
        
        device = metalDevice
        
        commandQueue = queue
        
        // Create the metal library containing the shaders
        guard let library = metalDevice.makeDefaultLibrary() else {
            print("Failed to make metal library")
            return nil
        }
        
        // Create a function with a specific name.
        guard let function = library.makeFunction(name: transtion_function) else {
            print("Metal function not found")
            return nil
        }
        
        // Create a compute pipeline with the above function.
        guard let cps = try? metalDevice.makeComputePipelineState(function: function) else {
            print("Failed to compute pipeline")
            return nil
        }
        computePipelineState = cps
        
        
        // Initialize the cache to convert the pixel buffer into a Metal texture.
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            print("Unable to allocate texture cache.")
            return nil
        }
        else {
            textureCache = textCache!
        }
        
        let width2 = Int(videoSize.width)
        let height2 = Int(videoSize.height)
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = width2
        textureDescriptor.height = height2
        //textureDescriptor.usage = .shaderWrite
        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue)
        
        outputTexture = self.device.makeTexture(descriptor: textureDescriptor)
        if outputTexture == nil {
            print("Failed to create metal outtexture")
            return nil
        }
        
    }
    var datas:[UInt8]
    var outputTexture: MTLTexture?
    
    func next() -> (CVPixelBuffer, CMTime)? {
        
        if presentationTime.seconds < header_duration.seconds - transtionSecondes {
            
            if let frame = header_reader.next() {
                
                let frameRate = header_reader.nominalFrameRate
                let timeScale : Float = Float(header_duration.timescale)
                presentationTime = CMTimeMake(value: Int64(frameCount * timeScale / frameRate), timescale: Int32(timeScale))
                
                if let targetTexture = render(pixelBuffer: frame, pixelBuffer2: nil, progress: 10.0) {
                    var outPixelbuffer: CVPixelBuffer?
                    let bytesperpixel = 4
                    let byteperrow = bytesperpixel * targetTexture.width
                    let region = MTLRegionMake2D(0, 0, targetTexture.width, targetTexture.height)
                    targetTexture.getBytes(&datas, bytesPerRow: byteperrow, from: region, mipmapLevel: 0 )

                    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                 targetTexture.height, kCVPixelFormatType_32BGRA, &datas,
                                                byteperrow, nil, nil, nil, &outPixelbuffer);
                    if outPixelbuffer != nil {
                        frameCount += 1
                        return (outPixelbuffer!, presentationTime)
                    }
                }
            }
            
            
        } else if presentationTime.seconds >= header_duration.seconds - transtionSecondes && presentationTime.seconds < header_duration.seconds {
            
            if let frame1 = tail_reader.next(){
                if let frame = header_reader.next() {
                    let frameRate = header_reader.nominalFrameRate
                    let timeScale : Float = Float(header_duration.timescale)
                    presentationTime = CMTimeMake(value: Int64(frameCount * timeScale / frameRate), timescale: Int32(timeScale))
                    
                    let progress = (header_duration.seconds - presentationTime.seconds) / transtionSecondes
                    if let targetTexture = render(pixelBuffer: frame, pixelBuffer2: frame1, progress: Float(progress)) {
                        var outPixelbuffer: CVPixelBuffer?
                        let bytesperpixel = 4
                        let byteperrow = bytesperpixel * targetTexture.width
                        let region = MTLRegionMake2D(0, 0, targetTexture.width, targetTexture.height)
                        targetTexture.getBytes(&datas, bytesPerRow: byteperrow, from: region, mipmapLevel: 0 )

                        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                     targetTexture.height, kCVPixelFormatType_32BGRA, &datas,
                                                    byteperrow, nil, nil, nil, &outPixelbuffer);
                        if outPixelbuffer != nil {
                            frameCount += 1
                            
                            return (outPixelbuffer!, presentationTime)
                        }
                    }
                }
                else{
                    let frameRate = header_reader.nominalFrameRate
                    let timeScale : Float = Float(header_duration.timescale)
                    presentationTime = CMTimeMake(value: Int64(frameCount * timeScale / frameRate), timescale: Int32(timeScale))
                    
                    if let targetTexture = render(pixelBuffer: nil, pixelBuffer2: frame1, progress: -10.0) {
                        var outPixelbuffer: CVPixelBuffer?
                        let bytesperpixel = 4
                        let byteperrow = bytesperpixel * targetTexture.width
                        let region = MTLRegionMake2D(0, 0, targetTexture.width, targetTexture.height)
                        targetTexture.getBytes(&datas, bytesPerRow: byteperrow, from: region, mipmapLevel: 0 )

                        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                     targetTexture.height, kCVPixelFormatType_32BGRA, &datas,
                                                    byteperrow, nil, nil, nil, &outPixelbuffer);
                        if outPixelbuffer != nil {
                            frameCount += 1
                            return (outPixelbuffer!, presentationTime)
                        }
                    }
                }
            }
        } else {
            
            if let frame = tail_reader.next() {
                
                let frameRate = header_reader.nominalFrameRate
                let timeScale : Float = Float(header_duration.timescale)
                presentationTime = CMTimeMake(value: Int64(frameCount * timeScale / frameRate), timescale: Int32(timeScale))
                
                if let targetTexture = render(pixelBuffer: nil, pixelBuffer2: frame, progress: -10.0) {
                    var outPixelbuffer: CVPixelBuffer?
                    let bytesperpixel = 4
                    let byteperrow = bytesperpixel * targetTexture.width
                    let region = MTLRegionMake2D(0, 0, targetTexture.width, targetTexture.height)
                    targetTexture.getBytes(&datas, bytesPerRow: byteperrow, from: region, mipmapLevel: 0 )

                    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                 targetTexture.height, kCVPixelFormatType_32BGRA, &datas,
                                                byteperrow, nil, nil, nil, &outPixelbuffer);
                    if outPixelbuffer != nil {
                        frameCount += 1
                        return (outPixelbuffer!, presentationTime)
                    }
                }
            }
            
            
        }
        
        return nil
        
    }
    
    func buildTextureForPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> MTLTexture? {

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)

        guard let metalTextureCache = textureCache else { return nil }

        var texture: CVMetalTexture?
        /*
         CVMetalTextureCacheCreateTextureFromImage is used to create a Metal texture (CVMetalTexture) from a
         CVPixelBuffer (or more precisely, a texture from the IOSurface that backs a CVPixelBuffer).

         Note: Calling CVMetalTextureCacheCreateTextureFromImage does not increment the use count of the
         IOSurface; only the CVPixelBuffer, and the CVMTLTexture own this IOSurface. At least one of the two
         must be retained until Metal rendering is done. The MTLCommandBuffer completion handler is good for
         this purpose.
        */
        let status =
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, metalTextureCache, pixelBuffer, nil,
                                                      MTLPixelFormat.bgra8Unorm, width, height, 0, &texture)
        if status == kCVReturnSuccess {
            guard let textureFromImage = texture else { return nil }

            guard let metalTexture = CVMetalTextureGetTexture(textureFromImage) else { return nil }

            return metalTexture
        } else { return nil }
    }
    
    
    private func render(pixelBuffer: CVPixelBuffer?, pixelBuffer2: CVPixelBuffer?, progress: Float) -> MTLTexture? {
        // here the metal code
        // Check if the pixel buffer exists
        
        
        // Create a command buffer and compute command encoder.
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        
        // Set the compute pipeline state for the command encoder.
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        
        if( pixelBuffer != nil){
            // Get width and height for the pixel buffer
            let width = CVPixelBufferGetWidth(pixelBuffer!)
            let height = CVPixelBufferGetHeight(pixelBuffer!)

            // Converts the pixel buffer in a Metal texture.
            var cvTextureOut: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer!, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
            guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
               print("Failed to create metal texture1")
               return nil
            }
            
            // Set the input and output textures for the compute shader.
            computeCommandEncoder.setTexture(inputTexture, index: 0)
        }
        
        if( pixelBuffer2 != nil){
            // Get width and height for the pixel buffer
            let width1 = CVPixelBufferGetWidth(pixelBuffer2!)
            let height1 = CVPixelBufferGetHeight(pixelBuffer2!)

            // Converts the pixel buffer in a Metal texture.
            var cvTextureOut1: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer2!, nil, .bgra8Unorm, width1, height1, 0, &cvTextureOut1)
            guard let cvTexture1 = cvTextureOut1, let inputTexture1 = CVMetalTextureGetTexture(cvTexture1) else {
               print("Failed to create metal texture2")
               return nil
            }
            
            computeCommandEncoder.setTexture(inputTexture1, index: 1)
        }
        
         /*
          We must maintain a reference to the pixel buffer until the Metal rendering is complete. This is because the
          'buildTextureForPixelBuffer' function above uses CVMetalTextureCacheCreateTextureFromImage to create a
          Metal texture (CVMetalTexture) from the IOSurface that backs the CVPixelBuffer, but
          CVMetalTextureCacheCreateTextureFromImage doesn't increment the use count of the IOSurface; only the
          CVPixelBuffer, and the CVMTLTexture own this IOSurface. Therefore we must maintain a reference to either
          the pixel buffer or Metal texture until the Metal rendering is done. The MTLCommandBuffer completion
          handler below is then used to release these references.
          */
//         pixelBuffers = RenderPixelBuffers(pixelBuffer!,
//                                           backgroundTexture: pixelBuffer2!,
//                                           destinationTexture: pixelBuffer!)
        
        
        
        
        computeCommandEncoder.setTexture(outputTexture, index: 2)
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        
        let samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor)
        computeCommandEncoder.setSamplerState(samplerState, index: 0)
        computeCommandEncoder.setSamplerState(samplerState, index: 1)
        computeCommandEncoder.setSamplerState(samplerState, index: 2)
        
        // Convert the time in a metal buffer.
        var time = Float(progress)
        computeCommandEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        let threadGroupCount = MTLSizeMake(16, 16, 1)
        
        let threadGroups: MTLSize = {
            MTLSizeMake((Int(videoSize.width) + threadGroupCount.width - 1) / threadGroupCount.width, (Int(videoSize.height)+threadGroupCount.height - 1) / threadGroupCount.height, 1)
        }()
        
        // Encode a threadgroup's execution of a compute function
        computeCommandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        // End the encoding of the command.
        computeCommandEncoder.endEncoding()
        
        // Register the current drawable for rendering.
        //commandBuffer!.present(drawable)
        
        // Use the command buffer completion block to release the reference to the pixel buffers.
        commandBuffer.addCompletedHandler({ _ in
            //self.pixelBuffers = nil // Release the reference to the pixel buffers.
        })
        
        // Commit the command buffer for execution.
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
    
    
    
    
//    func getCMSampleBuffer(pixelBuffer : CVPixelBuffer?) -> CMSampleBuffer? {
//
//        if pixelBuffer == nil {
//            return nil
//        }
//
//        var info = CMSampleTimingInfo()
//        info.presentationTimeStamp = CMTime.zero
//        info.duration = CMTime.invalid
//        info.decodeTimeStamp = CMTime.invalid
//
//
//        var formatDesc: CMFormatDescription? = nil
//        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &formatDesc)
//
//        var sampleBuffer: CMSampleBuffer? = nil
//
//        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
//                                                 imageBuffer: pixelBuffer!,
//                                                 formatDescription: formatDesc!,
//                                                 sampleTiming: &info,
//                                                 sampleBufferOut: &sampleBuffer);
//
//        return sampleBuffer!
//    }
    
    
}
