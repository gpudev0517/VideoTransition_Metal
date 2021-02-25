//
//  FGDimensionSelectionViewController.swift
//  Picflix
//
//  Created by Khalid on 28/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGDimensionSelectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func dismissView() {
        UserDefaults.standard.set(true, forKey: "isLogin")
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func storyTapped(_ sender: Any) {
        UserDefaults.standard.set(1, forKey: "Dimension")
        self.dismissView()
    }
    
    @IBAction func landscapeTapped(_ sender: Any) {
        UserDefaults.standard.set(2, forKey: "Dimension")
        self.dismissView()
    }
    
    @IBAction func squareTapped(_ sender: Any) {
        UserDefaults.standard.set(0, forKey: "Dimension")
        self.dismissView()
    }
    
}
