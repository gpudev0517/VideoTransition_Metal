//
//  FGVideoPreviewViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 02/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

import UIKit
import AVKit
import RappleProgressHUD

class FGVideoPreviewViewController: UIViewController {

    var mediaAssets: [MediaAsset] = []
    var theme: VideoTheme = .none
    var songURL: URL?
    var songStart: Double = 0
    var duration: Double = 0
    
    var currentProgress: CGFloat = 0
    
    var watermark: FGWatermark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            RappleActivityIndicatorView.startAnimatingWithLabel("Processing...", attributes: RappleModernAttributes)
            var asset: AVAsset? = nil
            if let surl = self.songURL {
                asset = AVAsset(url: surl)
            }
            FGConstants.cropAsset(asset: asset, startTime: self.songStart, duration: self.duration, isAudio: true) { (url) in
                self.videoMergingProgress(10)
                VideoMergerHelper.shared.mergeVideoClips(self.mediaAssets, theme: self.theme, songURL: url, watermark: self.watermark, delegate: self)
            }
        }

    }
    
    private func playVideo(url: URL){
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.delegate = self
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
}

extension FGVideoPreviewViewController: AVPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension FGVideoPreviewViewController: VideoMergerDelegate {
    func videosMergingSuccessfullyCompleted(url: URL) {
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: 1)
            self.playVideo(url: url)
        }
    }
    
    func videosMergingFailed() {
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation()
            self.showInformationalAlert(title: "Error!", message: "An unknown error occurred while generating preview") {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func videoMergingProgress(_ progress: CGFloat) {
        var i = currentProgress
        var total = currentProgress + progress
        if total > 100 {
            total = 100
        }
        while i <= total {
            RappleActivityIndicatorView.setProgress(i/100)
            i += 1
            Thread.sleep(forTimeInterval: 0.01)
        }
        currentProgress += progress
    }
    
}
