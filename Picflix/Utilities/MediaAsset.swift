//
//  MediaAsset.swift
//  Picflix
//
//  Created by Khalid Khan on 01/12/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import Photos

struct VideoAsset {
    var mediaSource: Any
    var transition: TransitionType
    var duration: Int
}

struct MediaAsset: Equatable {
    var asset: PHAsset
    var duration: Double
    var startTime: CMTime?
    var endTime: CMTime?
    var type: PHAssetMediaType
    var assetURL: URL?
    
    var startTimeSeconds: Double {
        guard let sTime = startTime else {
            return 0
        }
        return Double(CMTimeGetSeconds(sTime))
    }
    
    var endTimeSeconds: Double {
        guard let eTime = endTime else {
            return duration
        }
        return Double(CMTimeGetSeconds(eTime))
    }
    
    func videoNeedToCrop() -> Bool {
        guard type == .video else {
            return false
        }
        if let sTime = startTime, CMTimeGetSeconds(sTime) > 0 {
            return true
        }
        else if let eTime = endTime, CMTimeGetSeconds(eTime) < duration {
            return true
        }
        return false
    }
}

extension MediaAsset {
    static func ==(lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        return lhs.asset == rhs.asset
    }
}
