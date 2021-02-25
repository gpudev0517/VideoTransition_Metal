//
//  AppDelegate.swift
//  Picflix
//
//  Created by Mehrooz on 10/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import Purchases
import FBSDKCoreKit
import Parse
import SCSDKCreativeKit
import AppsFlyerLib
import iAd
import AdSupport

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.set(true, forKey: "isShowDimensionScreen")
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let configuration = ParseClientConfiguration {
            $0.applicationId = "jzbhWsHlhNxappXTMC06XLkQNSHpszOj7QNKVcPR"
            $0.clientKey = "6shwchyhKILHPbX2n56ultPsnzc7NOJTsRVQNpVj"
            $0.server = "https://pg-app-apgex7dqo6vlyzeifzceuty64dpk64.scalabl.cloud/1/"
        }
        Parse.initialize(with: configuration)
        
        UINavigationBar.appearance().barTintColor = UIColor.white
        let font = UIFont(name: "Lato-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "979797"), NSAttributedString.Key.font: font]
        
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "PTMFJdGbGruqYJpODJMWYTcZnhRBMbhW", appUserID: nil)
        Purchases.addAttributionData([:], from: .facebook)
        
        AppsFlyerTracker.shared().appsFlyerDevKey = "cyk38JtiPjvZc5P9swRMkf"
        AppsFlyerTracker.shared().appleAppID = "843201980"
        
        AppsFlyerTracker.shared().delegate = self
        
        /* Set isDebug to true to see AppsFlyer debug logs */
        AppsFlyerTracker.shared().isDebug = true
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerTracker.shared().trackAppLaunch()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        AppsFlyerTracker.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        return ApplicationDelegate.shared.application(
            application,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation
        )
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        AppsFlyerTracker.shared().handleOpen(url, options: options)
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
        
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerTracker.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
}

extension AppDelegate: AppsFlyerTrackerDelegate {
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        let data = installData
        print("\(data)")
        if let status = data["af_status"] as? String{
            if(status == "Non-organic"){
                if let sourceID = data["media_source"] , let campaign = data["campaign"]{
                    print("This is a Non-Organic install. Media source: \(sourceID)  Campaign: \(campaign)")
                }
            } else {
                print("This is an organic install.")
            }
        }
        
        if let is_first_launch = data["is_first_launch"] , let launch_code = is_first_launch as? Int {
            if(launch_code == 1){
                print("First Launch")
            } else {
                print("Not First Launch")
            }
        }
        Purchases.addAttributionData(installData, from: .appsFlyer, forNetworkUserId: AppsFlyerTracker.shared().getAppsFlyerUID())
    }
    
    func onConversionDataFail(_ error: Error) {
        print("\(error)")
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        let data = attributionData
        if let link = data["link"]{
            print("link:  \(link)")
        }
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
    }
    // Reports app open from a Universal Link for iOS 9 or later
    
}
