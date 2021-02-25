//
//  FGTrialSubscriptionViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 29/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGTrialSubscriptionViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        let regularText = NSMutableAttributedString(attributedString: textView.attributedText)
        if let policyRange = regularText.string.range(of: "privacy policy")?.nsRange(in: regularText.string), let termsRange = regularText.string.range(of: "terms of service.")?.nsRange(in: regularText.string)  {
            regularText.addAttribute(NSAttributedString.Key.link, value: "policy", range: policyRange)
            regularText.addAttribute(NSAttributedString.Key.link, value: "terms", range: termsRange)
            textView.attributedText = regularText
            textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "979797")]
        }
        
    }
    
    @IBAction func restoreTapped(_ sender: Any) {
        FGGlobalAlert.shared.showLoading()
        FGPurchaseHelper.restoreSubscription(controller: self) { (success) in
            FGGlobalAlert.shared.hideLoading()
            if success {
                self.closeTapped(self)
            }
        }
    }
    
    @IBAction func trialTapped(_ sender: Any) {
        FGGlobalAlert.shared.showLoading()
        FGPurchaseHelper.subscribeFor(.Trial, controller: self) { (success) in
            FGGlobalAlert.shared.hideLoading()
            if success {
                self.closeTapped(self)
            }
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension FGTrialSubscriptionViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.absoluteString == "policy" || URL.absoluteString == "terms" {
            let storyboard = UIStoryboard(name: "Premium", bundle: nil)
            guard let controller = storyboard.instantiateViewController(withIdentifier: "TermsPrivacyControllerID") as? FGTermsPrivacyViewController else {
                return true
            }
            if URL.absoluteString == "policy" {
                controller.isTerms = false
            }
            else if URL.absoluteString == "terms" {
                controller.isTerms = true
            }
            self.navigationController?.pushViewController(controller, animated: true)
            return false
        }
        
        else {
            return true
        }
    }
}
