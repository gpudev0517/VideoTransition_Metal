//
//  ITPurchaseHelper.swift
//  InstaTags
//
//  Created by Khalid on 31/08/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation
import Purchases

let SharedKey = "eea79be101fb4f9eb36ed5e782704549"

enum PurchaseType {
    case Trial
    case Monthly
    case Yearly
}


class FGPurchaseHelper {
    static func getPurchaseProduct(type: PurchaseType, completion: @escaping(SKProduct?) -> Void) {
        Purchases.shared.entitlements { (entitlements, error) in
            if let e = error {
                print(e.localizedDescription)
            }
            
            guard let pro = entitlements?["Pro"] else {
                completion(nil)
                return
            }
            guard let monthly = pro.offerings["Monthly"] else {
                completion(nil)
                return
            }
            guard let annual = pro.offerings["Yearly"] else {
                completion(nil)
                return
            }
            guard let trial = pro.offerings["Trial"] else {
                completion(nil)
                return
            }
            
            if let monthlyProduct = monthly.activeProduct, type == .Monthly {
                completion(monthlyProduct)
            }
            else if let annualProduct = annual.activeProduct, type == .Yearly {
                completion(annualProduct)
            }
            else if let trialProduct = trial.activeProduct, type == .Trial {
                completion(trialProduct)
            }
            else {
                completion(nil)
            }
        }
    }
    
    static func subscribeFor(_ type: PurchaseType, controller: UIViewController, completion: @escaping(Bool) -> Void) {
        
        FGPurchaseHelper.getPurchaseProduct(type: type) { (product) in
            guard let product = product else {
                controller.showInformationalAlert(title: "Error!", message: "An unknown error occurred. Please try again later.", action: nil)
                completion(false)
                return
            }
            Purchases.shared.makePurchase(product, { (transaction, purchaserInfo, error, userCancelled) in
                if let e = error {
                    controller.showInformationalAlert(title: "Error!", message: e.localizedDescription, action: nil)
                    completion(false)
                    
                } else if purchaserInfo?.entitlements.all["Pro"]?.isActive == true {
                    completion(true)
                }
                else {
                    controller.showInformationalAlert(title: "Error!", message: "An unknown error occurred. Please try again later.", action: nil)
                    completion(false)
                }
            })
        }
    }
    
    static func restoreSubscription(controller: UIViewController, completion: @escaping(Bool) -> Void) {
        Purchases.shared.restoreTransactions { (purchaserInfo, error) in
            if let e = error {
                controller.showInformationalAlert(title: "Error!", message: e.localizedDescription, action: nil)
                completion(false)
            }
            else {
                completion(true)
            }
        }
    }
    
    static func isPremiumUser(completion: @escaping(Bool) -> Void) {
        Purchases.shared.purchaserInfo { (purchaserInfo, error) in
            if purchaserInfo?.entitlements.all["Pro"]?.isActive == true || purchaserInfo?.entitlements.all["OldPro"]?.isActive == true {
                completion(true)
            }
            else {
                completion(false)
            }
        }
    }
}
