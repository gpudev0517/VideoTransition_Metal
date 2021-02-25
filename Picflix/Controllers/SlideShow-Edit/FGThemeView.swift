//
//  FGThemeView.swift
//  Picflix
//
//  Created by Khalid on 24/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGThemeCell: UICollectionViewCell {
    
    @IBOutlet weak var imageBGView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var proLabel: UILabel!
    
    func setCellContents(theme: VideoTheme, selected: Bool, premium: Bool) {
        titleLabel.text = theme.rawValue.capitalized
        if theme.isPremium() {
            proLabel.isHidden = premium
        }
        else {
            proLabel.isHidden = true
        }
        if selected {
            imageView.image = UIImage(named: "\(theme.rawValue)-selected")
            imageBGView.backgroundColor = UIColor.FGLightPurple
        }
        else {
            imageView.image = UIImage(named: theme.rawValue)
            imageBGView.backgroundColor = UIColor.FGLightGrey
        }
    }
    
}


//@IBDesignable
class FGThemeView: UIView {

    var view: UIView!
    @IBOutlet var collectionView: UICollectionView!
    
    let themes = VideoTheme.allCases
    
    var selectedTheme: VideoTheme = .none
    var isPremium = false
    
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
        
        let clipCell = UINib(nibName: "FGThemeCell", bundle:nil)
        collectionView.register(clipCell, forCellWithReuseIdentifier: "ThemeCell")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        FGPurchaseHelper.isPremiumUser { (premium) in
            self.isPremium = premium
            self.collectionView.reloadData()
        }
        
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of:self))
        let nib = UINib(nibName: "FGThemeView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func selectItemFor(_ theme: VideoTheme) {
        if let index = themes.firstIndex(of: selectedTheme) {
            if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FGThemeCell {
                cell.setCellContents(theme: selectedTheme, selected: false, premium: isPremium)
            }
            else {
                collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
            
        }
        if let index = themes.firstIndex(of: theme), let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FGThemeCell {
            cell.setCellContents(theme: theme, selected: true, premium: isPremium)
        }
        selectedTheme = theme
        
    }
    
    func isUsingPremium() -> Bool {
        return selectedTheme.isPremium()
    }
    
}

extension FGThemeView : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeCell", for: indexPath as IndexPath) as! FGThemeCell
        cell.setCellContents(theme: themes[indexPath.item], selected: selectedTheme == themes[indexPath.item], premium: isPremium)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItemFor(themes[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 76, height: 111)
        
    }
}
