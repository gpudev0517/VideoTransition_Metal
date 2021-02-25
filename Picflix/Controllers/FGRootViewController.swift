//
//  FGRootViewController.swift
//  InstaTags
//
//  Created by Mehrooz on 01/08/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGRootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.bool(forKey: "isLogin") {
            if UserDefaults.standard.bool(forKey: "isShowDimensionScreen") {
                UserDefaults.standard.set(false, forKey: "isShowDimensionScreen")
                showDimensionSelectionScreen()
            }
            else {
                self.performSegue(withIdentifier: "ImagePickerViewSegue", sender: self)
            }
        }
        else {
            self.performSegue(withIdentifier: "LoginSegue", sender: self)
        }
    }
    
    func showDimensionSelectionScreen()
    {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "DimensionSelectionVC")
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true) {
            
        }
        //self.show(controller, sender: self)
    }
}
