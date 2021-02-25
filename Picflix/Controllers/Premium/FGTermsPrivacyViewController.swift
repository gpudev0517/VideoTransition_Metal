//
//  FGTermsPrivacyViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 23/01/2020.
//  Copyright © 2020 Black Ace Media. All rights reserved.
//

import UIKit

class FGTermsPrivacyViewController: UIViewController {
    
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var privacyTextView: UITextView!
    
    var isTerms = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        termsTextView.isHidden = !isTerms
        privacyTextView.isHidden = isTerms
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
