//
//  UIColorExtension.swift
//  InstaTags
//
//  Created by Muhammad Khalid on 9/14/18.
//  Copyright © 2018 Black Ace Media. All rights reserved.
//

import UIKit

public extension UIColor {
    convenience init(hex: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        var hex:   String = hex
        
        if hex.hasPrefix("#") {
            let index = hex.index(hex.startIndex, offsetBy: 1)
            hex         = String(hex[index...])
        }
        
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
            }
        } else {
            print("Scan hex error")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    class var FGPurple:UIColor {
        return UIColor(hex: "8B46F4")
    }
    
    class var FGYellow:UIColor {
        return UIColor(hex: "FAD775")
    }
    
    class var FGBlack:UIColor {
        return UIColor(hex: "272727")
    }
    
    class var FGGrey:UIColor {
        return UIColor(hex: "979797")
    }
    
    class var FGLightPurple:UIColor {
        return UIColor(hex: "F3EDFE")
    }
    
    class var FGLightGrey:UIColor {
        return UIColor(hex: "F5F5F5")
    }
    
    class var FGRed:UIColor {
        return UIColor(hex: "EC362D")
    }
    
    class var FGLighRed:UIColor {
        return UIColor(hex: "FEF5F5")
    }
    
}
