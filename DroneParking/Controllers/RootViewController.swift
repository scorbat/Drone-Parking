//
//  RootViewController.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit
import DJISDK

class RootViewController: UIViewController, DJISDKManagerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!
    
    var product: DJIBaseProduct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register app with SDK key
        updateUI() //intialize UI
        DJISDKManager.registerApp(with: self)
    }
    
    //function to update UI based on if a product is connected
    func updateUI() {
        if let product = product {
            statusLabel.text = "Product Connected"
            modelLabel.text = "Model: \(product.model ?? "Not available")"
            openButton.isEnabled = true
        } else {
            statusLabel.text = "No Product Connected"
            modelLabel.text = "Model: N/A"
            openButton.isEnabled = K.DEBUG //if debug is on, allow bypassing the root controller
        }
    }
    
    //MARK: - SDKManagerDelegate methods
    
    func appRegisteredWithError(_ error: Error?) {
        var message = "Successful registration"
        if let error = error {
            message = "Registration error, \(error.localizedDescription)"
        }
        
        showAlert(from: self, title: "Register app", message: message)
        
        if K.USE_BRIDGE {
            DJISDKManager.enableBridgeMode(withBridgeAppIP: K.BRIDGE_IP)
        } else {
            DJISDKManager.startConnectionToProduct()
        }
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {  }
    
    func productConnected(_ product: DJIBaseProduct?) {
        self.product = product
        updateUI()
    }
    
    func productChanged(_ product: DJIBaseProduct?) {
        self.product = product
        updateUI()
    }
    
    func productDisconnected() {
        self.product = nil
        updateUI()
    }

}
