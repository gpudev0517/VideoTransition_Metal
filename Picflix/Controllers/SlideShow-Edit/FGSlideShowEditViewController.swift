//
//  FGSlideShowEditViewController.swift
//  Picflix
//
//  Created by Mehrooz on 22/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Photos
import RappleProgressHUD
import AVKit
import Parse

class FGSlideShowEditViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var themeView: FGThemeView!
    @IBOutlet var musicView: FGMusicView!
    @IBOutlet var timelineView: FGTimelineView!
    @IBOutlet var bottomTabView: UIView!
    @IBOutlet var adjustButton: UIButton!
    @IBOutlet var musicButton: UIButton!
    @IBOutlet var stopWatchButton: UIButton!
    @IBOutlet var picflixWatermarkLabel: UILabel!
    @IBOutlet var taptoRemoveButton: UIButton!
    @IBOutlet weak var trialSuggestionView: UIView!
    
    @IBOutlet var themeViewLeadingConstraint: NSLayoutConstraint!
    var assets: [PHAsset] = []
    
    var currentProgress: CGFloat = 0
    var isPlayVideo = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomTabView.dropShadow(color: UIColor.lightGray.withAlphaComponent(0.1), opacity: 1, offSet: CGSize(width: 0, height: -2.0), radius: 2, scale: true, cornerRadius: 0)
        adjustButton.isSelected = true
        musicView.parentController = self
        timelineView.setSelectedAssets(self.assets, controller: self)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "import-icon").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(importTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-black-icon").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(closeTapped))
        
        let size = FGConstants.getSelectedVideoSize()
        imageView.addConstraint(NSLayoutConstraint(item: imageView as Any,
                                                   attribute: .height,
                                                   relatedBy: .equal,
                                                   toItem: imageView,
                                                   attribute: .width,
                                                   multiplier: size.height / size.width,
                                                   constant: 0))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if assets.count > 0, imageView.image == nil {
            FGConstants.getImageFrom(assets[0], size: imageView.frame.size, mode: .aspectFill) { (image) in
                self.imageView.image = image
            }
        }
        FGPurchaseHelper.isPremiumUser { (premium) in
            if premium {
                self.picflixWatermarkLabel.isHidden = true
                self.taptoRemoveButton.isHidden = true
            }
            else {
                self.picflixWatermarkLabel.isHidden = false
                self.taptoRemoveButton.isHidden = false
            }
        }
    }
    
    @objc func importTapped() {
        FGGlobalAlert.shared.showLoading()
        FGPurchaseHelper.isPremiumUser { (premium) in
            FGGlobalAlert.shared.hideLoading()
            if !premium && (self.themeView.isUsingPremium() || self.timelineView.isUsingPremium()) {
                let storyboard = UIStoryboard(name: "Premium", bundle: nil)
                guard let controller = storyboard.instantiateViewController(withIdentifier: "ProSubscription") as? FGProSubscriptionViewController else {
                    return
                }
                controller.isShowThemeView = self.themeView.isUsingPremium()
                controller.isShowTimerView = self.timelineView.isUsingPremium()
                controller.closeBlock = {
                    self.trialSuggestionView.isHidden = false
                }
                let navController = UINavigationController(rootViewController: controller)
                navController.isNavigationBarHidden = true
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
            }
            else {
                self.showReviewPopup(premium)
            }
        }
    }
    
    func importSlideShow(_ showWatermark: Bool) {
        self.isPlayVideo = false
        var watermark: FGWatermark?
        if showWatermark, let font = UIFont(name: "Lato-Bold", size: self.getWatermarkFontSizeOnVideo()), let watermarkImage = self.getWatermarkWith("Picflix", font: font) {
            watermark = FGWatermark(frame: self.getWatermarkFrameOnVideo(watermarkImage.size), image: watermarkImage)
        }
        self.generateSlideShow(watermark)
    }
    
    func showReviewPopup(_ premium: Bool) {
        guard !premium, !UserDefaults.standard.bool(forKey: "ReviewPopupShowed") else {
            var showWatermark = !premium
            if showWatermark {
                showWatermark = !UserDefaults.standard.bool(forKey: "hideWatermark")
                UserDefaults.standard.set(false, forKey: "hideWatermark")
            }
            importSlideShow(showWatermark)
            return
        }
        FGGlobalAlert.shared.showLoading()
        let query = PFQuery(className: "ReviewPopup")
        query.getFirstObjectInBackground { (object, error) in
            FGGlobalAlert.shared.hideLoading()
            guard let object = object, let text = object.object(forKey: "popupText") as? String, let show = object.object(forKey: "show") as? Bool , show == true else {
                self.importSlideShow(!premium)
                return
            }
            UserDefaults.standard.set(true, forKey: "ReviewPopupShowed")
            let alert = UIAlertController(title: "", message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                guard let url = URL(string: "itms-apps://itunes.apple.com/app/id843201980?action=write-review") else  {
                    return
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                UserDefaults.standard.set(true, forKey: "hideWatermark")
            }))
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                
            }))
            if let controller = self.presentedViewController {
                controller.present(alert, animated: true, completion: nil)
            }
            else {
                self.present(alert, animated: true, completion: nil)
            }
            
        }
    }
    
    func showSuccessMessage(_ message: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "ImportSuccessVC") as? FGImportSuccessViewController else {
            return
        }
        controller.modalPresentationStyle = .overCurrentContext
        
        self.present(controller, animated: false) {
            controller.successLabel.text = message
        }
    }
    
    @IBAction func trialSuggestionCloseTapped(_ sender: Any) {
        trialSuggestionView.isHidden = true
    }
    
    @IBAction func trialTapped(_ sender: Any) {
        trialSuggestionView.isHidden = true
        let storyboard = UIStoryboard(name: "Premium", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "TrialSubscription") as? FGTrialSubscriptionViewController else {
            return
        }
        let navController = UINavigationController(rootViewController: controller)
        navController.isNavigationBarHidden = true
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func closeTapped() {
        navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: Notification.Name("ReloadGallery"), object: nil)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        isPlayVideo = true
        generateSlideShow(nil)
//        let storyboard = UIStoryboard(name: "Image", bundle: nil)
//        guard let controller = storyboard.instantiateViewController(withIdentifier: "VideoPreviewVC") as? FGVideoPreviewViewController else {
//            return
//        }
//        controller.mediaAssets = self.timelineView.mediaAssets
//        controller.theme = self.themeView.selectedTheme
//        controller.songURL = self.musicView.songURL
//        controller.songStart = self.musicView.startSeconds
//        controller.duration = self.musicView.duration
//        controller.modalPresentationStyle = .fullScreen
//        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func taptoRemoveTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Premium", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "Subscription") as? FGSubscriptionViewController else {
            return
        }
        let navController = UINavigationController(rootViewController: controller)
        navController.isNavigationBarHidden = true
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    @IBAction func adjustTapped(_ sender: Any) {
        tabSelected(tab: adjustButton, leadingConstraint: 0)
        
    }
    
    @IBAction func musicTapped(_ sender: Any) {
        tabSelected(tab: musicButton, leadingConstraint: -self.view.frame.size.width)
    }
    
    @IBAction func stopWatchTapped(_ sender: Any) {
        tabSelected(tab: stopWatchButton, leadingConstraint: -(self.view.frame.size.width * 2))
    }
    
}

//MARK: Private Functions
extension FGSlideShowEditViewController {
    func tabSelected(tab: UIButton, leadingConstraint: CGFloat) {
        adjustButton.isSelected = false
        musicButton.isSelected = false
        stopWatchButton.isSelected = false
        tab.isSelected = true
        
        themeViewLeadingConstraint.constant = leadingConstraint
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func getWatermarkFrameOnVideo(_ size: CGSize) -> CGRect {
        let widthRatio = VideoMergerHelper.shared.outputVideoSize.width / imageView.frame.width
        //let heightRatio = VideoMergerHelper.shared.outputVideoSize.height / imageView.frame.height
        
        //let height = picflixWatermarkLabel.frame.size.height * heightRatio
        let Y = size.height / 2
        
        let X = abs(VideoMergerHelper.shared.outputVideoSize.width - (25 * widthRatio) - size.width)
        
        let newFrame = CGRect(x: X, y: Y, width: size.width , height: size.height)
        return newFrame
    }
    
    func getWatermarkFontSizeOnVideo() -> CGFloat {
        let heightRatio = VideoMergerHelper.shared.outputVideoSize.height / imageView.frame.height
        let size = picflixWatermarkLabel.font.pointSize
        return size * heightRatio
    }
    
    func getWatermarkWith(_ text: String, font: UIFont) -> UIImage? {
        let textFontAttributes = [
        .font: font,
        .foregroundColor: UIColor.white] as [NSAttributedString.Key : Any]
        let size = (text as NSString).size(withAttributes: textFontAttributes)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        text.draw(in: CGRect(origin: .zero, size: size), withAttributes: textFontAttributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func generateSlideShow(_ watermark: FGWatermark?) {
        currentProgress = 0
        RappleActivityIndicatorView.startAnimatingWithLabel("Processing...", attributes: RappleModernAttributes)
        var asset: AVAsset? = nil
        if let surl = self.musicView.songURL {
            asset = AVAsset(url: surl)
        }
        FGConstants.cropAsset(asset: asset, startTime: self.musicView.startSeconds, duration: self.musicView.duration, isAudio: true) { (url) in
            self.videoMergingProgress(10)
            VideoMergerHelper.shared.mergeVideoClips(self.timelineView.mediaAssets, theme: self.themeView.selectedTheme, songURL: url, watermark: watermark, delegate: self)
        }
    }
    
    private func playVideo(_ url: URL){
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
    
    private func showImportScreen(_ url: URL) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "ImportVC") as? FGImportViewController else {
            return
        }
        controller.videoURL = url
        controller.closeBlock = { message in
            self.showSuccessMessage(message)
        }
        self.present(controller, animated: true, completion: nil)
    }
}

extension FGSlideShowEditViewController: VideoMergerDelegate {
    func videosMergingSuccessfullyCompleted(url: URL) {
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .success, completionLabel: "Completed.", completionTimeout: 1)
            if self.isPlayVideo {
                self.playVideo(url)
            }
            else {
                self.showImportScreen(url)
            }
        }
    }
    
    func videosMergingFailed() {
        DispatchQueue.main.async {
            RappleActivityIndicatorView.stopAnimation()
            self.showInformationalAlert(title: "Error!", message: "An unknown error occurred.") {
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
