//
//  UIViewExtension.swift
//  InstaTags
//
//  Created by Muhammad Khalid on 9/13/18.
//  Copyright © 2018 Black Ace Media. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true, cornerRadius: CGFloat = 0.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offSet
        self.layer.shadowRadius = radius
        
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func anchor(leading: NSLayoutXAxisAnchor? = nil, top: NSLayoutYAxisAnchor? = nil, trailing: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, leadingConstant: CGFloat = 0, topConstant: CGFloat = 0, trailingConstant: CGFloat = 0, bottomConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint]
    {
        translatesAutoresizingMaskIntoConstraints = false
        var anchors = [NSLayoutConstraint]()
        
        if let leading = leading {
            anchors.append(leadingAnchor.constraint(equalTo: leading, constant: leadingConstant))
        }
        
        if let top = top {
            anchors.append(topAnchor.constraint(equalTo: top, constant: topConstant))
        }
        
        if let trailing = trailing {
            anchors.append(trailingAnchor.constraint(equalTo: trailing, constant: trailingConstant))
        }
        
        if let bottom = bottom {
            anchors.append(bottomAnchor.constraint(equalTo: bottom, constant: bottomConstant))
        }
        
        if widthConstant > 0 {
            anchors.append(widthAnchor.constraint(equalToConstant: widthConstant))
        }
        
        if heightConstant > 0 {
            anchors.append(heightAnchor.constraint(equalToConstant: heightConstant))
        }
        
        anchors.forEach({$0.isActive = true})
        
        return anchors
    }
    
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func addBorder(style: BorderStyle, color: UIColor) {
        let borderView = UIView()
        borderView.backgroundColor = color
        borderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(borderView)
        switch style {
        case .left, .right:
            borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            borderView.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
            if style == .left {
                borderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                borderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        default:
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            borderView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
            if style == .top {
                borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            } else {
                borderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            }
        }
        bringSubviewToFront(borderView)
    }
    
    func addSubviewFullscreen(subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subView)
        subView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        subView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        subView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    
    func insertSubviewFullscreen(subview: UIView, behind: UIView) {
        addSubviewFullscreen(subView: subview)
        bringSubviewToFront(behind)
    }
}
