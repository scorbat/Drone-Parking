//
//  FlightService.swift
//  DroneParking
//
//  Created by admin on 8/24/21.
//

import Foundation
import MapKit
import DJISDK

class FlightService {
    
    var waypointMission: DJIMutableWaypointMission?
    var waypointPointer = 0
    
    //variables to keep track of total distance that is going to be traveled to next waypoint
    var totalLongDelta = -1.0
    var totalLatDelta = -1.0

    func generateFlightData(at droneLocation: CLLocationCoordinate2D) -> DJIVirtualStickFlightControlData? {
        guard let waypoint = waypointMission?.waypoint(at: UInt(waypointPointer)) else {
            return nil
        }
        
        //TODO: temporary constant
        let SPEED = 8.0
        let MIN_SPEED = 0.5
        
        let longitudeDelta = waypoint.coordinate.longitude - droneLocation.longitude
        let latitudeDelta = waypoint.coordinate.latitude - droneLocation.latitude
        
        //total deltas used to proportionally slow aircraft as it approaches waypoint
        if abs(longitudeDelta) > totalLongDelta {
            totalLongDelta = abs(longitudeDelta)
        }
        
        if abs(latitudeDelta) > totalLatDelta {
            totalLatDelta = abs(latitudeDelta)
        }
        
        if K.DEBUG {
            print("Generate flight data::")
            print("Latitude Delta: \(latitudeDelta)")
            print("Longitude Delta: \(longitudeDelta)")
        }
        
        //booleans to determine if these directions are needed
        let longitudeDone = abs(longitudeDelta) < 0.000002
        let latitudeDone = abs(latitudeDelta) < 0.000002
        
        //pythagorean math (want hypotenuse velocity to be SPEED)
        let angle = atan(latitudeDelta / longitudeDelta)
        //calculate needed velocities
        var longitudeVelocity = 0.0
        var latitudeVelocity = 0.0
        
        if !longitudeDone {
            //speed determined by ratio of current delta to total delta
            let speed = max(SPEED * (longitudeDelta / totalLongDelta), MIN_SPEED)
            //determine if positive or negative velocity is needed
            longitudeVelocity = longitudeDelta < 0 ? -speed : speed
        }
        
        if !latitudeDone {
            let speed = max(SPEED * (latitudeDelta / totalLatDelta), MIN_SPEED)
            latitudeVelocity = latitudeDelta < 0 ? speed : -speed
        }
        
        if K.DEBUG {
            print("Angle: \(angle)")
            print("Longitude Velocity: \(longitudeVelocity)")
            print("Latitude Velocity: \(latitudeVelocity)")
        }
        
        let controlData = DJIVirtualStickFlightControlData(
            pitch: Float(latitudeVelocity),
            roll: Float(longitudeVelocity),
            yaw: Float(angle),
            verticalThrottle: 0
        )
        
        if longitudeDone && latitudeDone {
            totalLongDelta = 0.0
            totalLatDelta = 0.0
            waypointPointer += 1
        }
        
        return controlData
    }
    
}

