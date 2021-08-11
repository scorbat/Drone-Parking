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
    
    var isEditingPoints = false
    var userLocation: CLLocationCoordinate2D?
    var droneLocation: CLLocationCoordinate2D?
    var waypointMission: DJIMutableWaypointMission?
    
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
        
        //load and upload mission
        let missionOperator = fetchMissionOperator()
        //LOAD MISSION can return error
        if let error = missionOperator?.load(waypointMission!) {
            showAlert(from: self, title: "Mission load fail", message: error.localizedDescription)
            return
        }
        
        missionOperator?.addListener(toFinished: self, with: .main, andBlock: { error in
            if let error = error {
                showAlert(from: self, title: "Mission execution fail", message: error.localizedDescription)
            } else {
                showAlert(from: self, title: "Mission execution finished", message: nil)
            }
        })
        
        missionOperator?.uploadMission(completion: { error in
            if let error = error {
                showAlert(from: self, title: "Mission upload fail", message: error.localizedDescription)
            } else {
                showAlert(from: self, title: "Mission upload success", message: nil)
            }
        })
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
    }
    
    @IBAction func loadPressed(_ sender: UIButton) {
        loadMission()
    }
    
    @IBAction func startPressed(_ sender: UIButton) {
        //start the mission
        fetchMissionOperator()?.startMission(completion: { error in
            if let error = error {
                showAlert(from: self, title: "Start Mission", message: "Mission start failed, \(error.localizedDescription)")
            } else {
                showAlert(from: self, title: "Start Mission", message: "Mission start success")
            }
        })
    }
    
    @IBAction func stopPressed(_ sender: UIButton) {
        fetchMissionOperator()?.stopMission(completion: { error in
            if let error = error {
                showAlert(from: self, title: "Stop Mission", message: "Mission stop failed, \(error.localizedDescription)")
            } else {
                showAlert(from: self, title: "Stop Mission", message: "Mission stop success")
            }
        })
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
        
        if let location = droneLocation {
            mapService.updateAircraft(location: location, on: mapView)
        }
        
        let yawRadian = state.attitude.yaw * (Double.pi / 180) //convert to radians
        mapService.updateAircraft(heading: Float(yawRadian))
    }

}
