//
//  ViewController.swift
//  Picflix
//
//  Created by Mehrooz on 10/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    var videoURLArray = [URL]()
    var transitionNameArray: [TransitionType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fillArray()
        
        
        //VideoMergerHelper.shared.mergeVideoClips(delegate: self, urlArray: videoURLArray, transitions: transitionNameArray)
        
//        VideoMergerHelper.shared.generateVideoFromImage(image: image) { (url) in
//            guard let url = url else {
//                return
//            }
//            print(url.videoFrameCount)
//            self.playVideo(url: url)
//        }
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func fillArray(){
        guard let url1 = Bundle.main.url(forResource: "sample_clip1", withExtension: "m4v") else {
            print("Impossible to find the video.")
            return
        }
        guard let url2 = Bundle.main.url(forResource: "sample_clip2", withExtension: "mov") else {
            print("Impossible to find the video.")
            return
        }
//        guard let image = Bundle.main.url(forResource: "yolo", withExtension: "png") else {
//            print("Impossible to find the video.")
//            return
//        }
        //videoURLArray.append(image)
        videoURLArray.append(url2)
        videoURLArray.append(url1)
        //videoURLArray.append(image)
        transitionNameArray.append(.transition_simplezoom)
        //transitionNameArray.append("transition_dreamy")
        //transitionNameArray.append("transition_morph")
    }

    private func playVideo(url: URL){
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }

}

extension ViewController: VideoMergerDelegate {
    func videoMergingProgress(_ progress: CGFloat) {
        
    }
    
    func videosMergingSuccessfullyCompleted(url: URL) {
        DispatchQueue.main.async {
            let player = AVPlayer(url: url)
            let playerController = AVPlayerViewController()
            playerController.player = player
            
            self.present(playerController, animated: true, completion: {
                player.play()
            })
        }
        
    }
    func videosMergingFailed() {
        
    }
}

extension URL {
    var videoFrameCount: Int? {
        let asset = AVAsset(url: self)
        guard let assetTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        var assetReader: AVAssetReader?
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        let assetReaderOutputSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        let assetReaderOutput = AVAssetReaderTrackOutput(track: assetTrack,
                                                         outputSettings: assetReaderOutputSettings)
        assetReaderOutput.alwaysCopiesSampleData = false
        assetReader?.add(assetReaderOutput)
        assetReader?.startReading()
        
        var frameCount = 0
        var sample: CMSampleBuffer? = assetReaderOutput.copyNextSampleBuffer()
        while (sample != nil) {
            frameCount += 1
            sample = assetReaderOutput.copyNextSampleBuffer()
        }
        
        return frameCount
    }
}


