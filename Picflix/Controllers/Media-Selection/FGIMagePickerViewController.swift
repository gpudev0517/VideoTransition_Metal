//
//  FGIMagePickerViewController.swift
//  Picflix
//
//  Created by Khalid on 15/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Photos

extension FileManager {
    func clearDocumentDirectory() {
        guard let documentsUrl =  self.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        do {
            let fileURLs = try contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
    }
    func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch {
           //catch the error somehow
        }
    }
}

protocol ImagePickerCellDelegate: class {
    func imageTapped(_ selected: Bool, item: Int)
}

class ImagePickerCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageButton: UIButton!
    @IBOutlet var selectedView: UIView!
    
    var item: Int = 0
    weak var delegate: ImagePickerCellDelegate?
    
    func setCellContentsWith(_ asset: PHAsset?, selected: Bool) {
        imageView.image = nil
        selectedView.isHidden = !selected
        if let asset = asset {
            FGConstants.getImageFrom(asset, size: self.contentView.frame.size, mode: .aspectFill) { (image) in
                self.imageView.image = image
            }
        }
        else {
            
        }
        
    }
    @IBAction func imageTapped(_ sender: Any) {
        imageButton.isSelected = !imageButton.isSelected
        selectedView.isHidden = !imageButton.isSelected
        delegate?.imageTapped(imageButton.isSelected, item: item)
    }
}

class FGIMagePickerViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var bottomActionView: UIView!
    @IBOutlet var itemsSelectedLabel: UILabel!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    var selectedItems: [Int] = []
    
    fileprivate var assets: PHFetchResult<PHAsset>?
    
    fileprivate let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAssets), name: Notification.Name("ReloadGallery"), object: nil)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.dropShadow(color: UIColor.lightGray.withAlphaComponent(0.3), opacity: 1, offSet: CGSize(width: 0, height: 2.0), radius: 2, scale: true, cornerRadius: 0.0)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 25, bottom: 10, right: 25)
        self.collectionView!.alwaysBounceVertical = true
        refreshControl.addTarget(self, action: #selector(reloadAssets), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        bottomActionView.dropShadow(color: UIColor.lightGray.withAlphaComponent(0.1), opacity: 1, offSet: CGSize(width: 0, height: -2.0), radius: 2, scale: true, cornerRadius: 0)
        itemsSelectedLabel.text = ""
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            reloadAssets()
        } else {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.reloadAssets()
                    }
                }
                
            })
        }
        
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        FileManager.default.clearTmpDirectory()
        FileManager.default.clearDocumentDirectory()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FGConstants.shouldShowReviewPopup() {
            self.showReviewPopup()
        }
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
            DispatchQueue.main.async {
                if status != .authorized {
                    self.showNeedAccessMessage()
                }
            }
        })
    }
    
    func showReviewPopup() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "RatingVC") as? FGRatingViewController else {
            return
        }
        controller.modalPresentationStyle = .overCurrentContext
        self.present(controller, animated: true) {
            controller.transparentView.isHidden = false
            UserDefaults.standard.set(true, forKey: "ReviewPopupShowed")
        }
    }
    
    fileprivate func showNeedAccessMessage() {
        let alert = UIAlertController(title: "Image picker", message: "App need get access to photos", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }))
        self.present(alert, animated: true) {
            
        }
    }
    
    @objc fileprivate func reloadAssets() {
        FGGlobalAlert.shared.showLoading()
        assets = nil
        selectedItems.removeAll()
        collectionView.reloadData()
        itemsSelectedLabel.text = ""
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        assets = PHAsset.fetchAssets(with: fetchOptions)
        collectionView.reloadData()
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        if collectionView.numberOfItems(inSection: 0) > 0 {
            UIView.animate(withDuration: 0.1) {
                self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
        FGGlobalAlert.shared.hideLoading()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? FGImageSelectionViewController {
            var selectedAssets: [PHAsset?] = []
            for item in selectedItems { selectedAssets.append(assets?[item]) }
            controller.assets = selectedAssets.compactMap({$0})
        }
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "ImageSelectionSegue", sender: self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        selectedItems.removeAll()
        collectionView.reloadData()
        itemsSelectedLabel.text = ""
        startButton.isEnabled = false
        cancelButton.isEnabled = false
        cancelButton.setTitleColor(UIColor.lightGray, for: .normal)
    }
}

extension FGIMagePickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickerCell", for: indexPath) as! ImagePickerCell
        cell.delegate = self
        cell.item = indexPath.item
        let selected = selectedItems.firstIndex(of: indexPath.item) == nil ? false : true
        cell.setCellContentsWith(assets?[indexPath.item], selected: selected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.size.width - 114) / 5
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
}

extension FGIMagePickerViewController: ImagePickerCellDelegate {
    func imageTapped(_ selected: Bool, item: Int) {
        if selected {
            selectedItems.append(item)
        }
        else {
            selectedItems.removeAll(where: { $0 == item })
        }
        if selectedItems.count == 0 {
            itemsSelectedLabel.text = ""
            startButton.isEnabled = false
            cancelButton.isEnabled = false
            cancelButton.setTitleColor(UIColor.lightGray, for: .normal)
        }
        else {
            let text = selectedItems.count > 1 ? "items selected" : "item selected"
            itemsSelectedLabel.text = "\(selectedItems.count) \(text)"
            startButton.isEnabled = true
            cancelButton.isEnabled = true
            cancelButton.setTitleColor(UIColor.black, for: .normal)
        }
    }
}

fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
