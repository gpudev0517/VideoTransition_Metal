//
//  FGLoginViewController.swift
//  InstaTags
//
//  Created by Khalid on 27/07/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import Parse
//import Firebase

class FGLoginViewController: UIViewController {
    
    @IBOutlet var passwordTextField: JVFloatLabeledTextField!
    @IBOutlet var emailTextField: JVFloatLabeledTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextFields()
        // Do any additional setup after loading the view.
    }
    private func setTextFields(){
        emailTextField.addBorder(style: .bottom, color: .FGPurple)
        passwordTextField.addBorder(style: .bottom, color: .FGPurple)
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
        
    @IBAction func signupTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func loginButtonTapped(_ sender: Any) {
        var error: String?
        if emailTextField.text ?? "" == "" {
            error = "Please enter email addres"
        }
        else if !FGConstants.isValidEmail(emailStr: emailTextField.text ?? "") {
            error = "Please enter valid email address"
        }
        else if passwordTextField.text ?? "" == "" {
            error = "Please enter password"
        }
        guard error == nil else {
            self.showInformationalAlert(title: error ?? "", message: "", action: nil)
            return
        }
        FGGlobalAlert.shared.showLoading()
        PFUser.logInWithUsername(inBackground: emailTextField.text ?? "", password: passwordTextField.text ?? "", block: { (user, error) -> Void in
            FGGlobalAlert.shared.hideLoading()
            guard error == nil, let user = user else {
                self.showInformationalAlert(title: error?.localizedDescription ?? "", message: "", action: nil)
                return
            }
            guard user["emailVerified"] as? Bool == true else {
                PFUser.logOut()
                let alertController = UIAlertController(
                    title: "Email address verification",
                    message: "We have sent you an email that contains a link - you must click this link before you can continue.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OKAY",
                                                        style: .default,
                                                        handler: { alertController in })
                )
                self.present(alertController, animated: true, completion: nil)
                return
            }
            self.dismissView()
        })
        
    }
}

extension FGLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            self.view.endEditing(true)
        default:
            break
        }
        return true
    }
}
