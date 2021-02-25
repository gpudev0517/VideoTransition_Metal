//
//  UILabelExtension.swift
//  Picflix
//
//  Created by Khalid on 18/11/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit

extension UIView {
    
    func applyGradientOn(_ color1: UIColor, color2: UIColor, startPoint: CGPoint, endPoint: CGPoint) {
        let gradient = CAGradientLayer()
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        if let view = self.superview {
            gradient.frame = view.bounds
            view.layer.addSublayer(gradient)
            view.mask = self
        }
    }
    
}

