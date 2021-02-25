//
//  FGImageSelectionViewController.swift
//  Picflix
//
//  Created by Khalid on 19/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Photos

protocol ImageSelectionCellDelegate {
    func deleteItemFor(_ asset: PHAsset?)
    func selectItemFor(_ asset: PHAsset?)
}

class ImageSelectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedView: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var asset: PHAsset?
    var delegate: ImageSelectionCellDelegate?
    
    func setCellContentsWith(_ asset: PHAsset, selected: Bool) {
        imageView.image = nil
        self.asset = asset
        selectedView.isHidden = !selected
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
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.deleteItemFor(self.asset)
    }
    
    @IBAction func imageTapped(_ sender: Any) {
        delegate?.selectItemFor(self.asset)
    }
    
}

class FGImageSelectionViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var selectedLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tutorialView1: UIView!
    @IBOutlet var tutorialView2: UIView!
    
    
    var selectedAsset: PHAsset?
    
    var assets: [PHAsset] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        bottomView.dropShadow(color: UIColor.lightGray.withAlphaComponent(0.1), opacity: 1, offSet: CGSize(width: 0, height: -2.0), radius: 2, scale: true, cornerRadius: 0)
        tutorialView1.dropShadow(color: UIColor.black.withAlphaComponent(0.15), opacity: 1, offSet: CGSize(width: 0, height: 4.0), radius: 25, scale: true, cornerRadius: 0)
        tutorialView2.dropShadow(color: UIColor.black.withAlphaComponent(0.15), opacity: 1, offSet: CGSize(width: 0, height: 4.0), radius: 25, scale: true, cornerRadius: 0)
        setSelectedItemText()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.assets.count > 0 {
                self.selectedAsset = self.assets[0]
                self.selectItemFor(self.assets[0])
            }
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        
        let size = FGConstants.getSelectedVideoSize()
        imageView.addConstraint(NSLayoutConstraint(item: imageView as Any,
                                                   attribute: .height,
                                                   relatedBy: .equal,
                                                   toItem: imageView,
                                                   attribute: .width,
                                                   multiplier: size.height / size.width,
                                                   constant: 0))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tutorialView1.isHidden = true
        tutorialView2.isHidden = true
        if !UserDefaults.standard.bool(forKey: "TutorialShowed") {
            tutorialView1.isHidden = false
        }
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }

    func setSelectedItemText() {
        guard assets.count > 0 else {
            selectedLabel.text = ""
            return
        }
        let text = assets.count > 1 ? "items selected" : "item selected"
        selectedLabel.text = "\(assets.count) \(text)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? FGSlideShowEditViewController {
            controller.assets = self.assets
        }
    }
    
    @IBAction func tutorialCloseTapped(_ sender: UIButton) {
        if sender.tag == 1 {
            tutorialView1.isHidden = true
            UserDefaults.standard.set(true, forKey: "TutorialShowed")
            //tutorialView2.isHidden = false
        }
        else {
            tutorialView2.isHidden = true
            UserDefaults.standard.set(true, forKey: "TutorialShowed")
        }
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "SlideShowEditSegue", sender: self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension FGImageSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageSelectionCell", for: indexPath) as! ImageSelectionViewCell
        cell.setCellContentsWith(assets[indexPath.item], selected: assets[indexPath.item] == selectedAsset)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 88, height: 88)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let asset = assets[sourceIndexPath.item]
        assets.remove(at: sourceIndexPath.item)
        assets.insert(asset, at: destinationIndexPath.item)
    }
    
}

extension FGImageSelectionViewController: ImageSelectionCellDelegate {
    func deleteItemFor(_ asset: PHAsset?) {
        guard let asset = asset, let index = self.assets.firstIndex(of: asset) else {
            return
        }
        self.assets.remove(at: index)
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        setSelectedItemText()
        if assets.count == 0 {
            self.navigationController?.popViewController(animated: true)
        }
        else if selectedAsset == asset {
            var newAsset: PHAsset? = nil
            if index < assets.count {
                newAsset = assets[index]
            }
            else if index-1 >= 0 {
                newAsset = assets[index-1]
            }
            selectItemFor(newAsset)
        }
    }
    
    func selectItemFor(_ asset: PHAsset?) {
        if let asset = selectedAsset, let index = assets.firstIndex(of: asset) {
            if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageSelectionViewCell {
                cell.selectedView.isHidden = true
            }
            else {
                collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
            
        }
        if let asset = asset, let index = assets.firstIndex(of: asset), let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageSelectionViewCell {
            cell.selectedView.isHidden = false
        }
        selectedAsset = asset
        guard let asset = asset else {
            return
        }
        activityIndicator.startAnimating()
        FGConstants.getImageFrom(asset, size: imageView.frame.size, mode: .aspectFill) { (image) in
            self.activityIndicator.stopAnimating()
            self.imageView.image = image
        }
    }

}
