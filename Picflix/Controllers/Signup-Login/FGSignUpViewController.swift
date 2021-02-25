//
//  ITMainViewController.swift
//  InstaTags
//
//  Created by Mehrooz on 27/07/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import Parse


class FGSignUpViewController: UIViewController {
    
    @IBOutlet var confirmPasswordTextField: JVFloatLabeledTextField!
    @IBOutlet var passwordTextField: JVFloatLabeledTextField!
    @IBOutlet var emailTextField: JVFloatLabeledTextField!
    @IBOutlet var nameTextField: JVFloatLabeledTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
       setTextFields()
    }
    
    private func setTextFields(){
        nameTextField.addBorder(style: .bottom, color: .FGPurple)
        emailTextField.addBorder(style: .bottom, color: .FGPurple)
        passwordTextField.addBorder(style: .bottom, color: .FGPurple)
        confirmPasswordTextField.addBorder(style: .bottom, color: .FGPurple)
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        var error: String?
        if nameTextField.text ?? "" == "" {
            error = "Please enter name"
        }
        else if emailTextField.text ?? "" == "" {
            error = "Please enter email addres"
        }
        else if !FGConstants.isValidEmail(emailStr: emailTextField.text ?? "") {
            error = "Please enter valid email address"
        }
        else if passwordTextField.text ?? "" == "" {
            error = "Please enter password"
        }
        else if (passwordTextField.text ?? "").count < 5 {
            error = "Password must be greater than 5 characters"
        }
        else if confirmPasswordTextField.text ?? "" == "" {
            error = "Please enter confirm password"
        }
        
        guard error == nil else {
            self.showInformationalAlert(title: error ?? "", message: "", action: nil)
            return
        }
        
        let newUser = PFUser()
        newUser.username = emailTextField.text ?? ""
        newUser.password = passwordTextField.text ?? ""
        newUser.email = emailTextField.text ?? ""
        newUser["Name"] = nameTextField.text ?? ""
        FGGlobalAlert.shared.showLoading()
        newUser.signUpInBackground(block: { (succeed, error) -> Void in
            FGGlobalAlert.shared.hideLoading()
            guard error == nil, succeed == true else {
                self.showInformationalAlert(title: error?.localizedDescription ?? "", message: "", action: nil)
                return
            }
            PFUser.logOutInBackground()
            let alertController = UIAlertController(title: "Email address verification",
                                                    message: "We have sent you an email that contains a link - you must click this link before you can continue.",
                                                    preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OKAY",
                                                    style: .default,
                                                    handler: { alertController in self.loginTapped(self)})
            )
            self.present(alertController, animated: true, completion: nil)
            //self.showAccountTypeScreen()
        })
        
    }
    @IBAction func loginTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "LoginSegue", sender: self)
    }
    
}

extension FGSignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        case confirmPasswordTextField:
            self.view.endEditing(true)
        default:
            break
        }
        return true
    }
}

