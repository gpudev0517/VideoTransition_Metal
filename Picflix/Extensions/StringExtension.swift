//
//  StringExtensions.swift
//  Cosplay
//
//  Created by Khalid on 20/10/2017.
//  Copyright © 2017 Muhammad Khalid. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let rect = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.width)
    }
    
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont, lineSpacing: CGFloat? = nil) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        var boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        if let lineSpacing = lineSpacing {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font, .paragraphStyle: paragraphStyle], context: nil)
        }
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func toBool() -> Bool? {
        switch self.lowercased() {
        case "true", "t", "y", "yes", "1":
            return true
        case "false", "f", "n", "no", "0":
            return false
        default:
            return nil
        }
    }
    
    func doubleValue() -> Double? {
        return Double(self)
    }
    
    func fileExtension() -> String? {
        return NSURL(fileURLWithPath: self).pathExtension
    }
}
