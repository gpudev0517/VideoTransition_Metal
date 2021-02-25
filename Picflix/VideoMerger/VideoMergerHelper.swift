//
//  VideoMergerHelper.swift
//  Picflix
//
//  Created by Mehrooz on 11/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AVKit
import Photos

class VideoMergerHelper {
    static let shared = VideoMergerHelper()
    var delegate: VideoMergerDelegate?
    var videoAssets: [VideoAsset] = []
    var songURL: URL?
    var watermark: FGWatermark?
    var theme: VideoTheme = .none
    var transitionIndex: Int = 0
    
    var outputVideoSize = CGSize(width: 1080, height: 1080)
    var transitionTime: Double = 1
    
    var parentController: UIViewController?
    
    var progressUpdate1: CGFloat = 10
    var progressUpdate2: CGFloat = 10
    
    private func playVideo(url: URL){
        DispatchQueue.main.async {
            let player = AVPlayer(url: url)
            let playerController = AVPlayerViewController()
            playerController.player = player
            
            self.parentController?.present(playerController, animated: true, completion: {
                player.play()
            })
        }
    }
        
    func mergeVideoClips(_ assets: [MediaAsset], theme: VideoTheme, songURL: URL?, watermark: FGWatermark?, delegate: VideoMergerDelegate) {
        outputVideoSize = FGConstants.getSelectedVideoSize()
        VideoManager.shared.defaultSize = self.outputVideoSize
        self.videoAssets = []
        self.delegate = delegate
        self.theme = theme
        self.transitionIndex = 0
        self.songURL = songURL
        self.watermark = watermark
        self.progressUpdate1 = 24.0 / CGFloat(assets.count)
        self.progressUpdate2 = 64.0 / CGFloat(assets.count-1)
        generateAssetsToProcess(assets, index: 0) { (success) in
            if success {
                self.mergeVideos()
            }
            else {
                delegate.videosMergingFailed()
            }
        }
        
    }
    
    private func checkAssetArrayForProcessing() -> Bool {
        if self.videoAssets.count == 0 {
            delegate?.videosMergingFailed()
            return false
        }
        else if self.videoAssets.count == 1 {
            guard let url = self.videoAssets[0].mediaSource as? URL else {
                delegate?.videosMergingFailed()
                return false
            }
            self.addBackgroundMusic(url)
            return false
        }
        else {
            return true
        }
        
    }
    
    private func mergeVideos() {
        
        if checkAssetArrayForProcessing() == false {
            return
        }
        
        let source1 = videoAssets[0]
        let source2 = videoAssets[1]
        
        var mediaSource1: AnyObject? = nil
        var mediaSource2: AnyObject? = nil
        if let m = source1.mediaSource as? UIImage {
            mediaSource1 = m
        }
        else if let m = source1.mediaSource as? URL {
            mediaSource1 = AVAsset(url: m)
        }
        
        if let m = source2.mediaSource as? UIImage {
            mediaSource2 = m
        }
        else if let m = source2.mediaSource as? URL {
            mediaSource2 = AVAsset(url: m)
        }
        
        guard let ms1 = mediaSource1, let ms2 = mediaSource2 else {
            delegate?.videosMergingFailed()
            return
        }
        
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let docsURL = dirPaths[0]
        
        let exportURL = docsURL.appendingPathComponent(String(Int(Date().timeIntervalSince1970)) + ".mp4")
        //let exportURL = URL.init(fileURLWithPath: path)
        
        let transition = videoAssets[0].transition
        
        let videoMerger = VideoMerger(media1: ms1, media2: ms2, export: exportURL, delegate: self)
        videoMerger.startRendering(function: transition.rawValue, transitionSeconds: transitionTime, videoSize: outputVideoSize, duration: source1.duration, duration1: source2.duration)
        
    }
    
}

//MARK:- Private functions
extension VideoMergerHelper {
    
    private func addBackgroundMusic(_ url: URL) {
        var musicAsset: AVAsset? = nil
        if let surl = self.songURL {
            musicAsset = AVAsset(url: surl)
        }
        if musicAsset != nil || watermark != nil {
            VideoManager.shared.merge(video: AVAsset(url: url), withBackgroundMusic: musicAsset, watermark: watermark) { (videoURL, error) in
                guard let vurl = videoURL else {
                    self.delegate?.videosMergingFailed()
                    return
                }
                self.delegate?.videosMergingSuccessfullyCompleted(url: vurl)
            }
        }
        else {
            delegate?.videosMergingSuccessfullyCompleted(url: url)
        }
        
    }
    
    private func generateAssetsToProcess(_ assets: [MediaAsset], index: Int, completion: @escaping(Bool)->Void) {
        if index >= assets.count {
            completion(true)
        }
        else {
            mediaAssetToVideoAsset(assets[index]) { (mediaSource) in
                guard let source = mediaSource else {
                    completion(false)
                    return
                }
                self.delegate?.videoMergingProgress(self.progressUpdate1)
                let transition = TransitionType.getTransition(self.theme, index: self.transitionIndex)
                self.videoAssets.append(VideoAsset(mediaSource: source, transition: transition, duration: Int(assets[index].duration)))
                self.transitionIndex += 1
                self.generateAssetsToProcess(assets, index: index + 1, completion: completion)
            }
        }
    }
    
    private func mediaAssetToVideoAsset(_ asset: MediaAsset, completion: @escaping(Any?) -> Void) {
        if asset.type == .image {
            FGConstants.getOriginalImage(asset.asset) { (image) in
                guard let image = image else {
                    completion(nil)
                    return
                }
                completion(image)
            }
        }
        else {
            if asset.videoNeedToCrop() {
                FGConstants.convertPHAssetToAVAsset(asset.asset) { (avAsset) in
                    guard let avAsset = avAsset else {
                        completion(nil)
                        return
                    }
                    FGConstants.cropAsset(asset: avAsset, startTime: asset.startTimeSeconds, duration: asset.duration) { (url) in
                        completion(url)
                    }
                }
            }
            else {
                FGConstants.getURL(asset.asset) { (url) in
                    completion(url)
                }
            }
        }
    }
}

//MARK:- Images to video functions

extension VideoMergerHelper {
    func generateVideoFromImage(_ asset: MediaAsset, completion: @escaping(_ url: URL?) -> Void) {
        
        FGConstants.getImageFrom(asset.asset, size: outputVideoSize, mode: .aspectFill) { (image) in
            guard let image = image, let newImage = FGConstants.resizeImage(image, targetRect: CGRect(origin: .zero, size: self.outputVideoSize)) else {
                completion(nil)
                return
            }
            
            let fileName = String(Int(Date().timeIntervalSince1970))
            
            var settings = RenderSettings()
            settings.fps = 30
            settings.videoDuration = Int32(asset.duration)
            settings.videoFilename = fileName
            settings.width = Int(self.outputVideoSize.width)
            settings.height = Int(self.outputVideoSize.height)
            
            let imageAnimator = ImageAnimator(renderSettings: settings, image: newImage)
            imageAnimator.render {
                completion(imageAnimator.settings.outputURL as URL)
            }
        }
    }
    
}

extension VideoMergerHelper: VideoMergerDelegate {
    func videoMergingProgress(_ progress: CGFloat) {
        
    }
    
    func videosMergingSuccessfullyCompleted(url: URL) {
        self.delegate?.videoMergingProgress(self.progressUpdate2)
        if checkAssetArrayForProcessing() == false {
            return
        }
        
        let asset = VideoAsset(mediaSource: url, transition: videoAssets[1].transition, duration: 1)
        self.videoAssets.removeFirst(2)
        self.videoAssets.insert(asset, at: 0)
        mergeVideos()
    }
    func videosMergingFailed() {
        self.delegate?.videosMergingFailed()
    }
}
