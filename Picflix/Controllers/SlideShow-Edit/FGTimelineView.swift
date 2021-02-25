//
//  FGTimelineView.swift
//  Picflix
//
//  Created by Khalid on 24/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView

class FGTimelineCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    func setCellContentsWith(_ asset: PHAsset, selected: Bool, displayTime: Double) {
        imageView.image = nil
        selectedView.isHidden = !selected
        titleLabel.text = FGConstants.secondsToUITime(displayTime, style: .abbreviated, pad: false)
        FGConstants.getImageFrom(asset, size: CGSize(width: 78, height: 78), mode: .aspectFill) { (image) in
            self.imageView.image = image
        }
        if let duration = FGConstants.getAssetDuration(asset), let time = FGConstants.secondsToUITime(duration, style: .positional) {
            timeView.isHidden = false
            timeLabel.text = time
        }
        else {
            timeView.isHidden = true
        }
    }
    
}

//@IBDesignable
class FGTimelineView: UIView {

    var view: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var setDurationButton: UIButton!
    @IBOutlet weak var setDurationLabel: UILabel!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var proLabel1: UILabel!
    @IBOutlet weak var proLabel2: UILabel!
    @IBOutlet weak var proLabel3: UILabel!
    @IBOutlet weak var sliderMinTimeLabel: UILabel!
    @IBOutlet weak var sliderMaxTimeLabel: UILabel!
    @IBOutlet weak var trimmingSuperView: UIView!
    @IBOutlet weak var trimmingView: TrimmerView!
    
    var parentController: UIViewController?
    var mediaAssets: [MediaAsset] = []
    var videoIndexes: [Int] = []
    
    var isPremium = false
    var timelineType: SelectedTimelineType = .video
    
    var videoMinTime = 0.0
    var videoMaxTime = 0.0
    
    var totalImages = 0
    
    var sliderOldValue = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        let clipCell = UINib(nibName: "FGTimelineCell", bundle:nil)
        collectionView.register(clipCell, forCellWithReuseIdentifier: "TimelineCell")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        
        FGPurchaseHelper.isPremiumUser { (premium) in
            self.isPremium = premium
            self.setViewContents()
        }
        trimmingView.delegate = self
        trimmingView.minDuration = videoMinTrimValue
        trimmingView.maxDuration = 400.0
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of:self))
        let nib = UINib(nibName: "FGTimelineView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }

    func setSelectedAssets(_ assets: [PHAsset], controller: UIViewController) {
        parentController = controller
        for (index, asset) in assets.enumerated() {
            if let duration = FGConstants.getAssetDuration(asset) {
                let mediaAsset = MediaAsset(asset: asset, duration: duration, startTime: nil, endTime: nil, type: .video)
                mediaAssets.append(mediaAsset)
                videoIndexes.append(index)
            }
            else {
                let mediaAsset = MediaAsset(asset: asset, duration: photoMinValue, startTime: nil, endTime: nil, type: .image)
                mediaAssets.append(mediaAsset)
                totalImages += 1
            }
        }
        let (min, max) = FGConstants.calculateVideoLength(mediaAssets)
        videoMinTime = min
        videoMaxTime = max
        setViewContents()
        collectionView.reloadData()
        setControllerTitle()
    }
    
    func setControllerTitle() {
        let videoTime = mediaAssets.reduce(0) { $0 + $1.duration }
        parentController?.title = FGConstants.secondsToUITime(videoTime, style: .positional, pad: true)
    }
    
    func isUsingPremium() -> Bool {
        if case .video = timelineType {
            return false
        }
        else {
            return true
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let newValue = Float(Int(sender.value))
        sender.value = newValue
        guard newValue != Float(sliderOldValue) else {
            return
        }
        if case .asset(let item) = timelineType {
            mediaAssets[item].duration = Double(newValue)
            reloadCellFor(item)
        }
        else {
            setAssetsTimeFor(Double(newValue))
            self.collectionView.reloadData()
        }
        setControllerTitle()
        sliderOldValue = Int(newValue)
    }
    
    @IBAction func setClipDurationTapped(_ sender: Any) {
        timelineType = .video
        setViewContents()
    }
    
}

extension FGTimelineView : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimelineCell", for: indexPath as IndexPath) as! FGTimelineCell
        cell.setCellContentsWith(mediaAssets[indexPath.item].asset, selected: indexPath.item == selectedItemIndex(), displayTime: mediaAssets[indexPath.item].duration)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItemFor(indexPath.item)
        setViewContents()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 95)
    }
}

//Private functions
extension FGTimelineView {
    
    private func selectedItemIndex() -> Int {
        if case .asset(let item) = timelineType {
            return item
        }
        else {
            return -1
        }
    }
    
    private func setViewContents() {
        setProTextVisibility()
        videoDurationLabel.isHidden = true
        var isShowTrimmingView = false
        if case .asset(let item) = timelineType {
            setDurationButton.isHidden = false
            let asset = mediaAssets[item]
            if asset.type == .video {
                isShowTrimmingView = true
                setTrimmingViewValuesFor(item)
                proLabel2.isHidden = true
                videoDurationLabel.isHidden = false
                setDurationLabel.text = "Set duration of Video"
            }
            else {
                self.bringSubviewToFront(self.sliderView)
                proLabel3.isHidden = true
                setDurationLabel.text = "Set duration of Photo"
                setSliderViewValues(minValue: photoMinValue, maxValue: photoMaxValue, currentValue: mediaAssets[item].duration)
            }
        }
        else {
            self.bringSubviewToFront(self.sliderView)
            proLabel2.isHidden = true
            proLabel3.isHidden = true
            setDurationButton.isHidden = true
            setDurationLabel.text = "Set duration of Clip"
            let value = mediaAssets.reduce(0) { $0 + $1.duration }
            setSliderViewValues(minValue: videoMinTime, maxValue: videoMaxTime, currentValue: value)
        }
        UIView.animate(withDuration: 0.2) {
            self.sliderView.alpha = isShowTrimmingView ? 0 : 1
            self.trimmingSuperView.alpha = isShowTrimmingView ? 1 : 0
        }
    }
    
    private func setTrimmingViewValuesFor(_ item: Int) {
        var mAsset = mediaAssets[item]
        FGGlobalAlert.shared.showLoading()
        FGConstants.convertPHAssetToAVAsset(mAsset.asset) { (avAsset) in
            DispatchQueue.main.async {
                FGGlobalAlert.shared.hideLoading()
                self.videoDurationLabel.text = FGConstants.secondsToUITime(mAsset.duration, style: .positional, pad: true)
                self.trimmingView.asset = avAsset
                if mAsset.startTime == nil, mAsset.endTime == nil {
                    mAsset.startTime = self.trimmingView.startTime
                    mAsset.endTime = self.trimmingView.endTime
                }
                else if let startTime = mAsset.startTime, let endTime = mAsset.endTime {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.trimmingView.moveLeftHandle(to: startTime)
                        self.trimmingView.moveRightHandle(to: endTime)
                    }
                }
            }
            
        }
    }
    
    private func setSliderViewValues(minValue: Double, maxValue: Double, currentValue: Double) {
        sliderView.isHidden = false
        var pad = false
        var style: DateComponentsFormatter.UnitsStyle = .abbreviated
        
        if case .video = timelineType {
            pad = true
            style = .positional
        }
        sliderMinTimeLabel.text = FGConstants.secondsToUITime(minValue, style: style, pad: pad)
        sliderMaxTimeLabel.text = FGConstants.secondsToUITime(maxValue, style: style, pad: pad)
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(currentValue)
    }
    
    private func setAssetsTimeFor(_ value: Double) {
        var newValue = value
        for index in videoIndexes {
            newValue -= mediaAssets[index].duration
        }
        let photoTime = totalImages == 0 ? 0 :  Int(newValue / Double(totalImages))
        for i in 0..<mediaAssets.count {
            if videoIndexes.firstIndex(of: i) == nil {
                mediaAssets[i].duration = Double(photoTime)
            }
        }
        var toIncrease: Int = totalImages == 0 ? 0 : Int(newValue) % totalImages
        guard toIncrease > 0 else {
            return
        }
        for i in 0..<mediaAssets.count {
            if videoIndexes.firstIndex(of: i) == nil {
                mediaAssets[i].duration += 1
                toIncrease -= 1
            }
            if toIncrease <= 0 {
                break
            }
        }
    }
    
    private func reloadCellFor(_ item: Int) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? FGTimelineCell {
            cell.setCellContentsWith(mediaAssets[item].asset, selected: item == selectedItemIndex(), displayTime: mediaAssets[item].duration)
        }
        else {
            collectionView.reloadItems(at: [IndexPath(item: item, section: 0)])
        }
    }
    
    private func setProTextVisibility() {
        proLabel1.isHidden = isPremium
        proLabel2.isHidden = isPremium
        proLabel3.isHidden = isPremium
    }
    
    func selectItemFor(_ item: Int) {
        let selectedIndex = selectedItemIndex()
        if selectedIndex >= 0, selectedIndex < mediaAssets.count {
            if let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? FGTimelineCell {
                cell.selectedView.isHidden = true
            }
            else {
                collectionView.reloadItems(at: [IndexPath(item: selectedIndex, section: 0)])
            }
            
        }
        if let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? FGTimelineCell {
            cell.selectedView.isHidden = false
        }
        timelineType = .asset(item: item)
    }
}

extension FGTimelineView: TrimmerViewDelegate {
    
    func didChangePositionBar(_ playerTime: CMTime) {
        let selectedIndex = selectedItemIndex()
        if selectedIndex >= 0, selectedIndex < mediaAssets.count, let startTime = trimmingView.startTime, let endTime = trimmingView.endTime {
            mediaAssets[selectedIndex].startTime = startTime
            mediaAssets[selectedIndex].endTime = endTime
            mediaAssets[selectedIndex].duration = (CMTimeGetSeconds(endTime) - CMTimeGetSeconds(startTime)).rounded()
            videoDurationLabel.text = FGConstants.secondsToUITime(mediaAssets[selectedIndex].duration, style: .positional, pad: true)
            setControllerTitle()
        }
        
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        
    }
}
