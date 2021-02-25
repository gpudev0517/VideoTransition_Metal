//
//  FGConstants.swift
//  Picflix
//
//  Created by Khalid on 27/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import UIKit
import Photos

let photoMinValue = 3.0
let photoMaxValue = 6.0
let videoMinTrimValue = 5.0

class FGConstants {
    static func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
    }
    
    static func resizeImage(_ image: UIImage, targetRect: CGRect) -> UIImage? {
        let aspect = image.size.width / image.size.height
        let rect: CGRect
        if targetRect.size.width / aspect > targetRect.size.height {
            let height = targetRect.size.width / aspect
            rect = CGRect(x: 0, y: (targetRect.size.height - height) / 2,
                          width: targetRect.size.width, height: height)
        } else {
            let width = targetRect.size.height * aspect
            rect = CGRect(x: (targetRect.size.width - width) / 2, y: 0,
                          width: width, height: targetRect.size.height)
        }
        UIGraphicsBeginImageContextWithOptions(targetRect.size, false, 0)
        if UIGraphicsGetCurrentContext() != nil {
          image.draw(in: rect)
          let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          
          return scaledImage
        }
        return nil
    }
    
    static func getImageFrom(_ asset: PHAsset, size: CGSize, mode: PHImageContentMode, completion: @escaping(UIImage?) -> Void) {
        
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.resizeMode = .fast
        
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: mode, options: option) { (image, info) in
            completion(image)
        }
    }
    
    static func getOriginalImage(_ asset: PHAsset, completion: @escaping(UIImage?) -> Void) {
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.resizeMode = .none
        
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: option) { (image, info) in
            completion(image)
        }
    }
    
    static func getAssetDuration(_ asset: PHAsset) -> Double? {
        guard asset.mediaType == PHAssetMediaType.video else {
            return nil
        }
        return  asset.duration.rounded()
    }
    
    static func getTrackName(file:URL) -> String {
        //Get data from track
        let urlAsset = AVURLAsset(url: file)
        for format in urlAsset.availableMetadataFormats {
            for metadata in urlAsset.metadata(forFormat: format) {
                if let commonKey = metadata.commonKey, commonKey.rawValue == "title" {
                    if let title = metadata.stringValue, !title.isEmpty {
                       return title
                    }
                }

            }
        }
        return file.deletingPathExtension().lastPathComponent
    }
    
    static func secondsToUITime(_ seconds: Double, style: DateComponentsFormatter.UnitsStyle, pad: Bool = true) -> String? {
        let formatter = DateComponentsFormatter()
        if seconds < 3600 {
            formatter.allowedUnits = [.minute, .second]
        }
        else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }
        if pad {
            formatter.zeroFormattingBehavior = .pad
        }
        formatter.unitsStyle = style
        guard let formattedString = formatter.string(from: seconds) else { return nil }
        return formattedString
    }
    
    static func calculateVideoLength(_ assets: [MediaAsset]) -> (Double, Double) {
        var min = 0.0
        var max = 0.0
        for asset in assets {
            if asset.type == .video {
                min += asset.duration
                max += asset.duration
            }
            else {
                min += photoMinValue
                max += photoMaxValue
            }
        }
        return (min, max)
    }
    
    static func getURL(_ mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
    
    static func convertPHAssetToAVAsset(_ asset: PHAsset, completion: @escaping(AVAsset?)->Void) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (newAsset, audioMix, info) in
            completion(newAsset)
        })
    }
    
    static func isInstagramInstalled() -> Bool {
        guard let appURL = URL(string: "instagram://app"),  UIApplication.shared.canOpenURL(appURL) else {
            return false
        }
        return true
    }
    static func isFacebookInstalled() -> Bool {
        guard let appURL = URL(string: "fb://"),  UIApplication.shared.canOpenURL(appURL) else {
            return false
        }
        return true
    }
    
    static func isSnapchatInstalled() -> Bool {
        guard let appURL = URL(string: "snapchat://"),  UIApplication.shared.canOpenURL(appURL) else {
            return false
        }
        return true
    }
    
    static func increaseExports() {
        let exports = UserDefaults.standard.integer(forKey: "numberOfExports")
        UserDefaults.standard.set(exports + 1, forKey: "numberOfExports")
    }
    
    static func shouldShowReviewPopup() -> Bool {
        if !UserDefaults.standard.bool(forKey: "ReviewPopupShowed"), UserDefaults.standard.integer(forKey: "numberOfExports") >= 3 {
            return true
        }
        else {
            return false
        }
    }
    
    static func cropAsset(asset: AVAsset?, startTime: Double, duration: Double, isAudio: Bool = false, completion: @escaping(URL?) -> Void)
    {
        guard let mediaAsset = asset, let urlAsset = mediaAsset as? AVURLAsset else {
            completion(nil)
            return
        }
        let sourceURL = urlAsset.url
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let asset = AVAsset(url: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("video length: \(length) seconds")
        var ext = ".mp4"
        if isAudio {
            ext = ".m4a"
        }
        let outputURL = documentDirectory.appendingPathComponent(String(Int(Date().timeIntervalSince1970)) + ext)
//        do {
//            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
//            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent).mp4")
//        }catch let error {
//            print(error)
//        }

        //Remove existing file
        try? fileManager.removeItem(at: outputURL)
        var presetName = AVAssetExportPresetHighestQuality
        if isAudio {
            presetName = AVAssetExportPresetAppleM4A
        }
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else { return }
        exportSession.outputURL = outputURL
        if isAudio {
            exportSession.outputFileType = .m4a
        }
        else {
            exportSession.outputFileType = .mp4
        }
        
        
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 1000), duration: CMTime(seconds: duration, preferredTimescale: 1000))

        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                completion(outputURL)
            case .failed:
                print("failed \(exportSession.error.debugDescription)")
                completion(nil)
            case .cancelled:
                print("cancelled \(exportSession.error.debugDescription)")
                completion(nil)
            default: break
            }
        }
    }
    
    static func getSelectedVideoSize() -> CGSize {
        let videoType = UserDefaults.standard.integer(forKey: "Dimension")
        if videoType == 1 {
            return CGSize(width: 1080, height: 1920)
        }
        else if videoType == 2 {
            return CGSize(width: 1080, height: 566)
        }
        else {
            return CGSize(width: 1080, height: 1080)
        }
    }
}

