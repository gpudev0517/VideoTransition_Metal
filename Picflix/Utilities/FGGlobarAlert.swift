//
//  FGGlobarAlert.swift
//  Picflix
//
//  Created by Mehrooz on 27/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

class FGGlobalAlert: NSObject {

    static let shared = FGGlobalAlert()

    var view: UIView?

    func showLoading() {
        guard let window = UIApplication.shared.keyWindow, view == nil else {
            return
        }
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        window.addSubviewFullscreen(subView: view)
        let activityView = UIActivityIndicatorView(style: .whiteLarge)
        activityView.startAnimating()
        view.addSubviewFullscreen(subView: activityView)
        self.view = view
    }

    func hideLoading() {
        view?.removeFromSuperview()
        view = nil
    }
    

}
