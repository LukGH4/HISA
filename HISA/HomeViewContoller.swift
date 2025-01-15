//
//  HomeViewContoller.swift
//  HISA
//
//  Created by Hoyeon Kang on 11/16/24.
//

import UIKit

class HomeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        print("Home Screen Loaded")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // keyboard goes away after pressing return
        return true
    }
}


