//
//  VideoManager.swift
//  Picflix
//
//  Created by Khalid Khan on 04/12/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoManager: NSObject {
    static let shared = VideoManager()
    var defaultSize = CGSize(width: 1080, height: 1080) // Default video size
    typealias Completion = (URL?, Error?) -> Void
    
    func merge(video:AVAsset, withBackgroundMusic bgmusic:AVAsset?, watermark: FGWatermark?, completion:@escaping Completion) -> Void {
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        // Get video track
        guard let videoTrack = video.tracks(withMediaType: AVMediaType.video).first else {
            completion(nil, nil)
            return
        }
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        let outputSize = videoTrack.naturalSize
        let insertTime = CMTime.zero
        
        // Get audio track
        let audioTrack:AVAssetTrack? = bgmusic?.tracks(withMediaType: AVMediaType.audio).first
        
        // Init video & audio composition track
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let startTime = CMTime.zero
        let videoDuration = video.duration
        
        do {
            // Add video track to video composition at specific time
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: videoDuration),
                                                       of: videoTrack,
                                                       at: insertTime)
            
            // Add audio track to audio composition at specific time
            if let musicTrack = audioTrack, let music = bgmusic {
                if(CMTimeCompare(videoDuration, music.duration) <= 0){
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: video.duration), of: musicTrack, at: CMTime.zero)
                }else if(CMTimeCompare(videoDuration, music.duration) == 1){
                     var currentTime = CMTime.zero
                     while(true){
                        var audioDuration = music.duration
                        let totalDuration = CMTimeAdd(currentTime,audioDuration);
                        if(CMTimeCompare(totalDuration, videoDuration)==1){
                            audioDuration = CMTimeSubtract(videoDuration,currentTime);
                        }
                        
                        try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: audioDuration), of: musicTrack, at: currentTime)
                           currentTime = CMTimeAdd(currentTime, audioDuration);
                           if(CMTimeCompare(currentTime, videoDuration) == 1 || CMTimeCompare(currentTime, videoDuration) == 0){
                               break;
                           }
                     }
                }
            }
        }
        catch {
            print("Load track error")
        }
        
        // Init layer instruction
        let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!,
                                                                   asset: video,
                                                                   standardSize: outputSize,
                                                                   atTime: insertTime)
        arrayLayerInstructions.append(layerInstruction)
        
        // Init main instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: insertTime, duration: videoDuration)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Init layer composition
        let layerComposition = AVMutableVideoComposition()
        layerComposition.instructions = [mainInstruction]
        layerComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layerComposition.renderSize = outputSize
        
        if let logo = watermark {
            
            let imageLayer = CALayer()
            imageLayer.frame = logo.frame
            imageLayer.contents = logo.image.cgImage
            imageLayer.opacity = 1
            imageLayer.backgroundColor = UIColor.clear.cgColor
            imageLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
            
            let videoLayer = CALayer()
            videoLayer.frame = CGRect.init(x: 0, y: 0, width: outputSize.width, height: outputSize.height)

            let parentlayer = CALayer()
            parentlayer.frame = CGRect.init(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
            
            parentlayer.addSublayer(videoLayer)
            parentlayer.addSublayer(imageLayer)
            
            layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentlayer)
        }
        
        
        let path = NSTemporaryDirectory().appending("mergedVideo1.mp4")
        let exportURL = URL.init(fileURLWithPath: path)
        
        // Check exist and remove old file
        FileManager.default.removeItemIfExisted(exportURL)
        
        // Init exporter
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = layerComposition
        
        // Do export
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: completion)
            }
        })
    }
    
    func mergeVideos(arrayVideos:[AVAsset], animation:Bool, completion:@escaping Completion) -> Void {
        var insertTime = CMTime.zero
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        let outputSize = defaultSize
        
        // Silence sound (in case of video has no sound track)
        let silenceURL = Bundle.main.url(forResource: "silence", withExtension: "mp3")
        let silenceAsset = AVAsset(url:silenceURL!)
        let silenceSoundTrack = silenceAsset.tracks(withMediaType: AVMediaType.audio).first
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        var index = 0
        for videoAsset in arrayVideos {
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            // Get audio track
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            else {
                audioTrack = silenceSoundTrack
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = CMTime.zero
                let duration = videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                // Add instruction for video track
                let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!,
                                                                           asset: videoAsset,
                                                                           standardSize: outputSize,
                                                                           atTime: insertTime)
                
                // Hide video track before changing to new track
                let endTime = CMTimeAdd(insertTime, duration)
                
                if animation {
                    let timeScale = videoAsset.duration.timescale
                    let durationAnimation = CMTime.init(seconds: 1, preferredTimescale: timeScale)
                    
                    layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange.init(start: endTime, duration: durationAnimation))
                }
                else {
                    layerInstruction.setOpacity(0, at: endTime)
                }
                
                arrayLayerInstructions.append(layerInstruction)
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
            index += 1
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = outputSize
        
        // Export to file
        let path = NSTemporaryDirectory().appending("mergedVideoWithTrimPoints.mp4")
        let exportURL = URL.init(fileURLWithPath: path)
        
        // Remove file if existed
        FileManager.default.removeItemIfExisted(exportURL)
        
        // Init exporter
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainComposition
        
        // Do export
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: completion)
            }
        })
        
    }
    
}

// MARK:- Private methods
extension VideoManager {
    
    fileprivate func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, standardSize:CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
    
        let size = __CGSizeApplyAffineTransform(assetTrack.naturalSize, transform)
        
        let fr = __CGPointApplyAffineTransform(CGPoint(x: 0, y: 0), transform)
        
        let videoSize = CGSize(width: abs(size.width), height: abs(size.height))
        
//        var ratio : CGFloat = 1.0
//        if videoSize.height > standardSize.height, videoSize.height > videoSize.width {
//            ratio = standardSize.height / videoSize.height
//        }
//
//        if videoSize.width > standardSize.width, videoSize.width > videoSize.height {
//            ratio = standardSize.width/videoSize.width
//        }
        
        var ratio : CGFloat = standardSize.height / videoSize.height
        
        if standardSize.width/videoSize.width < ratio {
            ratio = standardSize.width/videoSize.width
        }
        
        let scaleFactor = CGAffineTransform(scaleX: ratio, y: ratio)
        
        var posX = standardSize.width/2 - (videoSize.width * ratio)/2
        var posY = standardSize.height/2 - (videoSize.height * ratio)/2
        
        if size.width < 0 {
            posX += ( abs(size.width) * ratio )
        }
        
        if size.height < 0 {
            posY += ( abs(size.height) * ratio )
        }
        
        if fr.x != 0 {
            posX = posX - ( fr.x * ratio )
        }
        
        if fr.y != 0 {
            posY = posY - ( fr.y * ratio )
        }
        
        let moveFactor = CGAffineTransform(translationX: posX, y: posY)
        
        let concat = transform.concatenating(scaleFactor).concatenating(moveFactor)
        
        instruction.setTransform(concat, at: atTime)
    
        return instruction
    }
    
    fileprivate func setOrientation(image:UIImage?, onLayer:CALayer, outputSize:CGSize) -> Void {
        guard let image = image else { return }

        if image.imageOrientation == UIImage.Orientation.up {
            // Do nothing
        }
        else if image.imageOrientation == UIImage.Orientation.left {
            let rotate = CGAffineTransform(rotationAngle: .pi/2)
            onLayer.setAffineTransform(rotate)
        }
        else if image.imageOrientation == UIImage.Orientation.down {
            let rotate = CGAffineTransform(rotationAngle: .pi)
            onLayer.setAffineTransform(rotate)
        }
        else if image.imageOrientation == UIImage.Orientation.right {
            let rotate = CGAffineTransform(rotationAngle: -.pi/2)
            onLayer.setAffineTransform(rotate)
        }
    }
    
    fileprivate func exportDidFinish(exporter:AVAssetExportSession?, videoURL:URL, completion:@escaping Completion) -> Void {
        if exporter?.status == AVAssetExportSession.Status.completed {
            print("Exported file: \(videoURL.absoluteString)")
            completion(videoURL,nil)
        }
        else if exporter?.status == AVAssetExportSession.Status.failed {
            completion(videoURL,exporter?.error)
        }
    }
}

extension FileManager {
    func removeItemIfExisted(_ url:URL) -> Void {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            }
            catch {
                print("Failed to delete file")
            }
        }
    }
}
