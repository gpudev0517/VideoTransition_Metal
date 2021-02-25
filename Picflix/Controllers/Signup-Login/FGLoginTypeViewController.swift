//
//  FGLoginTypeViewController.swift
//  InstaTags
//
//  Created by Mehrooz on 27/07/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import Parse
import GoogleSignIn
import FBSDKLoginKit


class FGLoginTypeViewController: UIViewController {
    
    @IBOutlet var googleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        googleButton.dropShadow(color: UIColor.black.withAlphaComponent(0.1), opacity: 1, offSet: CGSize(width: 0, height: 5), radius: 20, scale: true, cornerRadius: 10)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func showDimensionSelectionScreen() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "DimensionSelectionVC")
            self.show(controller, sender: self)
        }
    }
    
    func dismissView() {
        UserDefaults.standard.set(true, forKey: "isLogin")
        self.dismiss(animated: true, completion: nil)
    }
    
    private func fetchFBUserData() {
        if let token = AccessToken.current {
            FGGlobalAlert.shared.showLoading()
            let r = GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: token.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
            r.start(completionHandler: { (test, result, error) in
                
                guard let json = result as? [String: Any] else {
                    self.showInformationalAlert(title: "An unknown error occurred.", message: "", action: nil)
                    FGGlobalAlert.shared.hideLoading()
                    return
                }
        
                let newUser = PFUser()
                newUser.username = (json["email"] as? String) ?? "private_email@fb.com"
                newUser.password = "123456"
                newUser.email = (json["email"] as? String) ?? "private_email@fb.com"
                newUser["Name"] = (json["name"] as? String) ?? "Unknown"
                newUser["Type"] = "facebook"
                self.parseSignup(newUser)
            })

        }
    }
    
    @IBAction func facebookLoginTapped(_ sender: Any) {
        
        let loginManager = LoginManager()
        print(Settings.sdkVersion)
        loginManager.logIn(permissions: [ "public_profile", "email" ], from: self) { (result, error) in
            if result != nil {
                self.fetchFBUserData()
            }
            else if let error = error {
                self.showInformationalAlert(title: error.localizedDescription, message: "", action: nil)
            }
        }
    }
    
    @IBAction func gmailLoginTapped(_ sender: Any) {
        
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    private func parseSignup(_ user: PFUser) {
        user.signUpInBackground(block: { (succeed, error) -> Void in
            FGGlobalAlert.shared.hideLoading()
            guard error == nil, succeed == true else {
                self.parseLogin(user)
                return
            }
            self.dismissView()
        })
    }
    
    private func parseLogin(_ user: PFUser) {
        PFUser.logInWithUsername(inBackground: user.username ?? "", password: user.password ?? "", block: { (user, error) -> Void in
            FGGlobalAlert.shared.hideLoading()
            self.dismissView()
        })
    }
    @IBAction func continueWithoutLoginTapped(_ sender: Any) {
        self.dismissView()
    }
}

extension FGLoginTypeViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil, let user = user else {
            self.showInformationalAlert(title: error?.localizedDescription ?? "", message: "", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        let newUser = PFUser()
        newUser.username = user.profile.email
        newUser.password = "123456"
        newUser.email = user.profile.email
        newUser["Name"] = user.profile.name
        newUser["Type"] = "gmail"
        parseSignup(newUser)
    }
}
