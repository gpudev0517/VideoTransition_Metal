//
//  FGImportViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 29/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Photos
import FBSDKCoreKit
import FBSDKShareKit
import AVKit
import SCSDKCreativeKit
import RappleProgressHUD

class FGImportViewController: UIViewController {

    
    var mediaAssets: [MediaAsset] = []
    var theme: VideoTheme = .none
    var songURL: URL?
    var songStart: Double = 0
    var duration: Double = 0
    
    var watermark: FGWatermark?
    
    var videoURL: URL?
    
    var currentProgress: CGFloat = 0
    
    var closeBlock: (String) -> () = {_ in
        
    }
    
    fileprivate lazy var snapAPI = {
        return SCSDKSnapAPI()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            RappleActivityIndicatorView.startAnimatingWithLabel("Processing...", attributes: RappleModernAttributes)
//            var asset: AVAsset? = nil
//            if let surl = self.songURL {
//                asset = AVAsset(url: surl)
//            }
//            FGConstants.cropAsset(asset: asset, startTime: self.songStart, duration: self.duration, isAudio: true) { (url) in
//                self.videoMergingProgress(10)
//                VideoMergerHelper.shared.mergeVideoClips(self.mediaAssets, theme: self.theme, songURL: url, watermark: self.watermark, delegate: self)
//            }
//        }
    }
    
    @IBAction func saveToPhotosTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }
        FGGlobalAlert.shared.showLoading()
        saveVideoInGallery(url) { (success, videoURL) in
            DispatchQueue.main.async {
                FGGlobalAlert.shared.hideLoading()
                if success {
                    self.dismiss(animated: true) {
                        self.closeBlock("Your awesome video is succesully saved on your device")
                        FGConstants.increaseExports()
                    }
                }
                else {
                    self.showInformationalAlert(title: "Error", message: "An unknown error occurred please try again later.", action: nil)
                }
            }
        }
    }
    
    @IBAction func shareTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            DispatchQueue.main.async {
                if success {
                    self.dismiss(animated: true) {
                        self.closeBlock("Your awesome video is succesully shared")
                        FGConstants.increaseExports()
                    }
                }
                else if error != nil {
                    self.showInformationalAlert(title: "Error", message: "An unknown error occurred please try again later.", action: nil)
                }
            }
            
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func postToInstagramTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }
        guard FGConstants.isInstagramInstalled() else {
            self.showInformationalAlert(title: "Error!", message: "Instagram app is not installed.", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        saveVideoInGallery(url) { (success, asset) in
            DispatchQueue.main.async {
                FGGlobalAlert.shared.hideLoading()
                guard let videoAsset = asset, let urlScheme = URL(string: "instagram://library?LocalIdentifier=\(videoAsset.localIdentifier)") else {
                    self.showInformationalAlert(title: "Error!", message: "An unknown error occurred please try again later", action: nil)
                    return
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(urlScheme)
                }
                FGConstants.increaseExports()
            }
        }
    }
    @IBAction func postToInstagramStoriesTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }
        guard FGConstants.isInstagramInstalled() else {
            self.showInformationalAlert(title: "Error!", message: "Instagram app is not installed.", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        saveVideoInGallery(url) { (videoURL) in
            DispatchQueue.main.async {
                FGGlobalAlert.shared.hideLoading()
                guard let url = videoURL, let data = NSData(contentsOf: url), let appURL = URL(string: "instagram-stories://share") else {
                    self.showInformationalAlert(title: "Error!", message: "An unknown error occurred please try again later.", action: nil)
                    return
                }
                let pasteboardItems = [["com.instagram.sharedSticker.backgroundVideo": data]]
                let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(60 * 5)]

                UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(appURL)
                }
                FGConstants.increaseExports()
            }
        }
    }
    
    @IBAction func postInFacebookTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }
        guard FGConstants.isFacebookInstalled() else {
            self.showInformationalAlert(title: "Error!", message: "Facebook app is not installed.", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        saveVideoInGallery(url) { (success, videoAsset) in
            DispatchQueue.main.async {
                FGGlobalAlert.shared.hideLoading()
                guard let asset = videoAsset else {
                    self.showInformationalAlert(title: "Error", message: "An unknown error occurred please try again later.", action: nil)
                    return
                }
                let content: ShareVideoContent = ShareVideoContent()
                let video = ShareVideo()
                video.videoAsset = asset
                content.video = video

                let shareDialog = ShareDialog()
                shareDialog.shouldFailOnDataError = true
                shareDialog.shareContent = content
                shareDialog.mode = .native
                shareDialog.delegate = self
                shareDialog.show()
                FGConstants.increaseExports()
            }
        }
    }
    
    @IBAction func postInSnapchatTapped(_ sender: Any) {
        guard let url = videoURL else {
            return
        }
        guard FGConstants.isSnapchatInstalled() else {
            self.showInformationalAlert(title: "Error!", message: "Snapchat app is not installed.", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        saveVideoInGallery(url) { (videoURL) in
            DispatchQueue.main.async {
                
                guard let url = videoURL else {
                    FGGlobalAlert.shared.hideLoading()
                    self.showInformationalAlert(title: "Error!", message: "An unknown error occurred please try again later.", action: nil)
                    return
                }
                let snapVideo = SCSDKSnapVideo(videoUrl: url)
                let snapContent = SCSDKVideoSnapContent(snapVideo: snapVideo)
                self.snapAPI.startSending(snapContent) { (error: Error?) in
                    FGGlobalAlert.shared.hideLoading()
                    if let error = error {
                        self.showInformationalAlert(title: "Error!", message: error.localizedDescription, action: nil)
                    }
                    else {
                        self.dismiss(animated: true) {
                            self.closeBlock("Your awesome video is succesully shared on snapchat")
                            FGConstants.increaseExports()
                        }
                    }
                }
            }
        }
    }
}

extension FGImportViewController: SharingDelegate {
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        self.dismiss(animated: true) {
            self.closeBlock("Your awesome video is succesully shared on facebook")
        }
    }
    
    
    func sharerDidCancel(_ sharer: Sharing) {

    }
    
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        self.showInformationalAlert(title: "Error", message: error.localizedDescription, action: nil)
    }
}

//Private Functions
extension FGImportViewController {
    
    private func saveVideoInGallery(_ url: URL, completionBlock: @escaping(URL?)-> Void) {
        saveVideoInGallery(url) { (success, asset) in
            if let asset = asset {
                FGConstants.getURL(asset) { (url) in
                    completionBlock(url)
                }
            }
            else {
                completionBlock(nil)
            }
        }
    }
    
    private func saveVideoInGallery(_ url: URL, completionBlock: @escaping(Bool, PHAsset?)-> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                guard let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).firstObject else {
                    completionBlock(true, nil)
                    return
                }
                completionBlock(true, fetchResult)
            }
            else {
                completionBlock(false, nil)
            }
        }
    }
}

extension FGImportViewController: VideoMergerDelegate {
    
    func videosMergingSuccessfullyCompleted(url: URL) {
        self.videoURL = url
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: 1)
        }
    }
    
    func videosMergingFailed() {
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation()
            self.showInformationalAlert(title: "Error!", message: "An unknown error occurred while generating video") {
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
