//
//  FGImportSuccessViewController.swift
//  Picflix
//
//  Created by Khalid Khan on 30/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGImportSuccessViewController: UIViewController {
    @IBOutlet weak var successLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

    @IBAction func okTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
    

}
