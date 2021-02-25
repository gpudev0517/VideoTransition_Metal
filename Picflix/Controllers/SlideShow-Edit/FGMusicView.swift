//
//  FGMusicView.swift
//  Picflix
//
//  Created by Khalid on 24/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import FDWaveformView
import MediaPlayer
import AVKit


//@IBDesignable
class FGMusicView: UIView {

    var view: UIView!
    
    @IBOutlet var waveformView: FDWaveformView!
    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet weak var trimmingSuperView: UIView!
    
    @IBOutlet weak var trimViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var trimViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trimmingView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
    var parentController: UIViewController?
    var songURL : URL?
    
    var audioPlayer : AVPlayer?
    var timeObserverToken: Any?
    
    var startSeconds: Double {
        let x = Double(trimmingView.frame.origin.x)
        guard let duration = selectedSongDuration(), x > 0 else {
            return 0
        }
        let width = Double(view.frame.size.width)
        return ((duration / width) * x).rounded()
    }
    
    var endSeconds: Double {
        guard let duration = selectedSongDuration() else {
            return 0
        }
        let width = Double(view.frame.size.width)
        let x = Double(trimmingView.frame.origin.x + trimmingView.frame.size.width)
        return ((duration / width) * x).rounded()
    }
    
    var duration: Double {
        guard let duration = selectedSongDuration() else {
            return 0
        }
        return duration - startSeconds
    }
    
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
        
        waveformView.doesAllowScrubbing = false
        waveformView.doesAllowStretch = false
        waveformView.doesAllowScroll = false
        waveformView.wavesColor = #colorLiteral(red: 0.5450980392, green: 0.2745098039, blue: 0.9568627451, alpha: 1)
        waveformView.delegate = self
        myMediaPickerVC.delegate = self
        guard let defaultsoundPath = Bundle.main.path(forResource: "default", ofType: "wav") else {
            songTitleLabel.text = ""
            return
        }
        let url = URL.init(fileURLWithPath: defaultsoundPath)
        songSelected(url)
    }
       
    func loadViewFromNib() -> UIView {
       let bundle = Bundle(for: type(of:self))
       let nib = UINib(nibName: "FGMusicView", bundle: bundle)
       let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
       return view
    }
    
    func selectedSongDuration() -> Double? {
        guard let url = songURL else {
            return nil
        }
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
    
    func songSelected(_ url: URL) {
        
        songTitleLabel.text = FGConstants.getTrackName(file: url)
        waveformView.audioURL = url
        songURL = url
    }
    
    @IBAction func selectDifferentMusicTapped(_ sender: Any) {
        myMediaPickerVC.allowsPickingMultipleItems = false
        myMediaPickerVC.popoverPresentationController?.sourceView = (sender as! UIView)
        parentController?.present(myMediaPickerVC, animated: true, completion: nil)
    }
    
    @IBAction func trimViewDragged(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            
            let translation = sender.translation(in: self.view)
            if let trimView = sender.view {
                let frame = trimView.frame
                var newX = frame.origin.x + translation.x
                if newX < 0 {
                    newX = 0.2
                }
                else if newX > trimmingSuperView.frame.size.width - trimViewWidthConstraint.constant {
                    newX = trimmingSuperView.frame.size.width - trimViewWidthConstraint.constant - 0.2
                }
                let newFrame = CGRect(origin: CGPoint(x: newX, y: frame.origin.y + trimmingSuperView.frame.origin.y), size: frame.size)
                
                if trimmingSuperView.frame.contains(newFrame) == true {
                    trimViewLeadingConstraint.constant = newX
                }
                sender.setTranslation(CGPoint.zero, in: self.view)
            }
        }
        audioPlayer?.pause()
        removePeriodicTimeObserver()
    }
    @IBAction func playTapped(_ sender: UIButton) {
        guard let url = self.songURL else {
            return
        }
        if audioPlayer?.timeControlStatus != .playing {
            audioPlayer = AVPlayer(url: url)
            audioPlayer?.play()
            addPeriodicTimeObserver()
            audioPlayer?.seek(to: CMTime(seconds: self.startSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        else {
            audioPlayer?.pause()
        }
    }
    
    func addPeriodicTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 1, preferredTimescale: timeScale)

        timeObserverToken = audioPlayer?.addPeriodicTimeObserver(forInterval: time, queue: .main)
        {   [weak self] time in
            if self?.audioPlayer?.currentTime().seconds ?? 0 >= self?.endSeconds ?? 0 {
                self?.audioPlayer?.pause()
                self?.removePeriodicTimeObserver()
            }
        }
    }

    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            audioPlayer?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}

extension FGMusicView: FDWaveformViewDelegate {
    func waveformViewDidRender(_ waveformView: FDWaveformView) {
        
        
    }
}

extension FGMusicView: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        //myMediaPickerVC.dismiss(animated: true, completion: nil)
        
        guard let mpMediaItem = mediaItemCollection.items.first, let url = mpMediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
            parentController?.showInformationalAlert(title: "Erro!", message: "An error occurred while fetching selected music. Please try selecting another file.", action: nil)
            return
        }
        songSelected(url)
        myMediaPickerVC.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        myMediaPickerVC.dismiss(animated: true, completion: nil)
    }
}
