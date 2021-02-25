//
//  FGResetPasswordViewController.swift
//  InstaTags
//
//  Created by Khalid on 27/07/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import Parse

class FGResetPasswordViewController: UIViewController {
    
    
    @IBOutlet var emailTextField: JVFloatLabeledTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextFields()
        
    }
    private func setTextFields(){
        emailTextField.addBorder(style: .bottom, color: .FGPurple)
    }
    @IBAction func resetPasswordTapped(_ sender: Any) {
        var error: String?
        if emailTextField.text ?? "" == "" {
            error = "Please enter email addres"
        }
        else if !FGConstants.isValidEmail(emailStr: emailTextField.text ?? "") {
            error = "Please enter valid email address"
        }
        
        guard error == nil else {
            self.showInformationalAlert(title: error ?? "", message: "", action: nil)
            return
        }
        let email = emailTextField.text ?? ""
        PFUser.requestPasswordResetForEmail(inBackground: email)
        let alert = UIAlertController (title: "Password Reset", message: "An email containing information on how to reset your password has been sent to " + email + ".", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}

extension FGResetPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
