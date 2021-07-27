//
//  RootViewController.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit
import DJISDK

class RootViewController: UIViewController, DJISDKManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register app with SDK key
        DJISDKManager.registerApp(with: self)
    }
    
    //MARK: - SDKManagerDelegate methods
    
    func appRegisteredWithError(_ error: Error?) {
        
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        
    }

}
