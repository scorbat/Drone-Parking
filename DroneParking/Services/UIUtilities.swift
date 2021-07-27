//
//  UIUtilities.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit


func showAlert(from viewController: UIViewController, title: String?, message: String?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    
    viewController.present(alert, animated: true, completion: nil)
}
