//
//  FGRatingViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 29/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGRatingViewController: UIViewController {

    @IBOutlet weak var transparentView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func yeahTapped(_ sender: Any) {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/Picflix-Photo-Slideshow-Maker/id843201980?mt=8&action=write-review") else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        transparentView.isHidden = true
        self.dismiss(animated: true, completion: nil)
    }
    

}
