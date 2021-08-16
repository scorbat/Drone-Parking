//
//  MapViewController.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit
import MapKit
import DJISDK

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, DJIFlightControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIButton!
    
    let mapService = MapService()
    let locationManager = CLLocationManager()
    
    var isSimulating = false
    
    var isEditingPoints = false
    var userLocation: CLLocationCoordinate2D?
    var droneLocation: CLLocationCoordinate2D?
    var waypointMission: DJIMutableWaypointMission?
    
    var missionRunning = false
    var waypointPointer = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create tap gesture for map view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoint(tapGesture:)))
        mapView.addGestureRecognizer(tapGesture)
        //enable location updating
        enableLocationTracking()
        //set flight controller delegate
        if let flightController = fetchFlightController() {
            flightController.delegate = self
        } else {
            showAlert(from: self, title: "Flight Controller", message: "Flight controller not connected.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    //MARK: - My methods
    
    @objc func addWaypoint(tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .ended && isEditingPoints {
            let point = tapGesture.location(in: mapView)
            mapService.add(point: point, for: mapView)
        }
    }
    
    //focuses map to user's current location
    func focusMap() {
        guard let location = droneLocation else {
            print("Drone Location not valid!")
            return
        }
        
        if CLLocationCoordinate2DIsValid(location) {
            let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func enableLocationTracking() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 0.1
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            showAlert(from: self, title: "Location Service", message: "Location is not enabled")
        }
    }
    
    func loadMission() {
        //add locations to waypoint mission
        let waypoints = mapService.points
        if waypoints.count < 2 {
            showAlert(from: self, title: "Load Mission", message: "Not enough waypoints for mission")
            return
        }
        
        //reset or create mission
        if let mission = waypointMission {
            mission.removeAllWaypoints()
        } else {
            waypointMission = DJIMutableWaypointMission()
        }
        
        //set mission parameters
        waypointMission!.autoFlightSpeed = 8
        waypointMission!.maxFlightSpeed = 10
        waypointMission!.headingMode = .auto
        waypointMission!.finishedAction = .noAction
        
        for location in waypoints {
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                let waypoint = DJIWaypoint(coordinate: location.coordinate)
                waypoint.altitude = 20
                waypointMission!.add(waypoint)
            }
        }
    }
    
    func generateFlightData() -> DJIVirtualStickFlightControlData? {
        guard let currentLocation = droneLocation, let dest = waypointMission?.waypoint(at: UInt(waypointPointer)) else {
            return nil
        }
        
        //TODO: temporary constant
        let SPEED = 8.0
        
        let longitudeDelta = dest.coordinate.longitude - currentLocation.longitude
        let latitudeDelta = dest.coordinate.latitude - currentLocation.latitude
        
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
            //determine if positive or negative velocity is needed
            longitudeVelocity = longitudeDelta < 0 ? SPEED : -SPEED
        }
        
        if !latitudeDone {
            latitudeVelocity = latitudeDelta < 0 ? SPEED : -SPEED
        }
        
        if K.DEBUG {
            print("Angle: \(angle)")
            print("Longitude Velocity: \(longitudeVelocity)")
            print("Latitude Velocity: \(latitudeVelocity)")
        }
        
        let controlData = DJIVirtualStickFlightControlData(
            pitch: Float(longitudeVelocity),
            roll: Float(latitudeVelocity),
            yaw: Float(angle),
            verticalThrottle: 0
        )
        
        return controlData
    }
    
    //MARK: - IBActions
    
    @IBAction func focusPressed(_ sender: UIButton) {
        focusMap()
    }
    
    @IBAction func editPressed(_ sender: UIButton) {
        isEditingPoints.toggle()
        //update button text
        editButton.setTitle(isEditingPoints ? "Finish" : "Edit", for: .normal)
    }
    
    @IBAction func clearPressed(_ sender: UIButton) {
        mapService.cleanPoints(in: mapView)
        waypointMission?.removeAllWaypoints()
    }
    
    @IBAction func loadPressed(_ sender: UIButton) {
        loadMission()
    }
    
    @IBAction func startPressed(_ sender: UIButton) {
        fetchFlightController()?.setVirtualStickModeEnabled(true) { error in
            if let error = error {
                showAlert(from: self, title: "Virtual Stick failed", message: error.localizedDescription)
            }
        }
        
        missionRunning = true
        showAlert(from: self, title: "Mission started", message: nil)
    }
    
    @IBAction func stopPressed(_ sender: UIButton) {
        fetchFlightController()?.setVirtualStickModeEnabled(false, withCompletion: nil)
        
        missionRunning = false
        showAlert(from: self, title: "Mission stopped", message: nil)
    }
    
    @IBAction func takeoffPressed(_ sender: UIButton) {
        fetchFlightController()?.startTakeoff(completion: { error in
            let title = "Start Takeoff \(error == nil ? "Success" : "Failed")"
            showAlert(from: self, title: title, message: error?.localizedDescription)
        })
    }
    
    @IBAction func simulatorPressed(_ sender: UIBarButtonItem) {
        guard let fc = fetchFlightController() else {
            showAlert(from: self, title: "Flight controller not found", message: nil)
            return
        }
        
        if isSimulating {
            fc.simulator?.stop(completion: { error in
                var status = "Success"
                if let _ = error {
                    status = "Failed"
                } else {
                    self.isSimulating = false
                }
                
                showAlert(from: self, title: "Stop Simulator \(status)", message: error?.localizedDescription)
            })
        } else {
            fc.simulator?.start(withLocation: K.HOME_LOCATION, updateFrequency: 20, gpsSatellitesNumber: 10, withCompletion: { error in
                var status = "Success"
                if let _ = error {
                    status = "Failed"
                } else {
                    self.isSimulating = true
                }
                
                showAlert(from: self, title: "Start Simulator \(status)", message: error?.localizedDescription)
            })
        }
    }
    
    //MARK: - MKMapViewDelegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: AircraftAnnotation.self) {
            //create custom annotation for aircraft
            let aircraft = AircraftAnnotationView(annotation: annotation, reuseIdentifier: "aircraft_annotation")
            (annotation as! AircraftAnnotation).annotationView = aircraft
            return aircraft
        } else if annotation.isKind(of: MKPointAnnotation.self) {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "waypoint_annotation")
            return pin
        }
        
        return nil
    }
    
    //MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }
    
    //MARK: - DJIFlightControllerDelegate methods
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        droneLocation = state.aircraftLocation?.coordinate
        
        //update aircraft location and heading on map
        if let location = droneLocation {
            mapService.updateAircraft(location: location, on: mapView)
        }
        
        let yawRadian = state.attitude.yaw * (Double.pi / 180) //convert to radians
        mapService.updateAircraft(heading: Float(yawRadian))
        
        //generate data for mission
        if missionRunning, let flightData = generateFlightData() {
            fc.send(flightData, withCompletion: nil)
        }
    }

}
