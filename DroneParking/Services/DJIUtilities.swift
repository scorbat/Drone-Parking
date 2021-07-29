//
//  DJIUtilities.swift
//  DroneParking
//
//  Created by admin on 7/29/21.
//

import Foundation
import DJISDK


func fetchFlightController() -> DJIFlightController? {
    return (DJISDKManager.product() as? DJIAircraft)?.flightController
}
