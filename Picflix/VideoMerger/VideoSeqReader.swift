//
//  VideoSeqReader.swift
//  Picflix
//
//  Created by Mehrooz on 10/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import AVFoundation
import MetalKit
import CoreVideo

final class VideoSeqReader {
    
    let PX_BUFFER_OPTS = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferMetalCompatibilityKey as String: true] as [String : Any]
    
    let videoOutput: AVAssetReaderTrackOutput?
    let reader: AVAssetReader?
    
    let nominalFrameRate: Float
    var totalTime: CMTime
    
    let sourceIsImage: Bool
    var imagePixelBuffer: CVPixelBuffer?
    
    init?(asset: AnyObject, frameRate: Float, durationTime: CMTime) {
        let avasset = asset as? AVAsset
        if avasset != nil {
            sourceIsImage = false
            do {
                reader = try AVAssetReader(asset: avasset!)
            }
            catch {
                print("Failed to create AVAssetReader: \(error.localizedDescription)")
                return nil
            }
            
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0] //as! AVAssetTrack
            videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: PX_BUFFER_OPTS)
            
            reader!.add(videoOutput!)
            
            nominalFrameRate = videoTrack.nominalFrameRate
            totalTime = asset.duration
            
            reader!.startReading()
            
            if reader!.status == .failed {
                print("Reader status faild")
                return nil
            }
            
            //assert(reader.status != .failed, "reader started failed error \(String(describing: reader.error))")
        }
        else {
            sourceIsImage = true
            
            videoOutput = nil
            reader = nil
            nominalFrameRate = frameRate
            totalTime = durationTime
            
            let uiimg = asset as! UIImage
            imagePixelBuffer = VideoSeqReader.pixelBuffer(from: uiimg)
        }
    }
    
    static func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue, kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let attrs = [ kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
      
        let byteBuffer = UnsafeMutableRawPointer(pixelData)
        let w = CVPixelBufferGetBytesPerRow(pixelBuffer!) / 4
        for index in 0...w * Int(image.size.height) {
            let tmp1 = byteBuffer?.load(fromByteOffset: index * 4, as: UInt8.self)
            let tmp2 = byteBuffer?.load(fromByteOffset: index * 4+2, as: UInt8.self)
            byteBuffer?.storeBytes(of: tmp2!, toByteOffset: index * 4, as: UInt8.self)
            byteBuffer?.storeBytes(of: tmp1!, toByteOffset: index * 4+2, as: UInt8.self)
        }
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    
    var frameCount : Int32 = 0
    func next() -> CVPixelBuffer? {
        
        if sourceIsImage == false {
            if let sb = videoOutput!.copyNextSampleBuffer() {
                let pxbuffer = CMSampleBufferGetImageBuffer(sb)
                return pxbuffer
            }
            return nil
        }
        else{
            if Float(totalTime.seconds) * nominalFrameRate > Float(frameCount){
                frameCount += 1
                return imagePixelBuffer
            }
            return nil
        }
    }
    
}
