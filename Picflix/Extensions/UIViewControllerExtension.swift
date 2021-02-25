//
//  UIViewControllerExtension.swift
//  Picflix
//
//  Created by Khalid on 27/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showInformationalAlert(title: String, message: String?, action: (() -> ())?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in
            action?()
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
}
