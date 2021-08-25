//
//  MapViewController.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit
import MapKit
import DJISDK

class MapViewController: UIViewController, MKMapViewDelegate, DJIFlightControllerDelegate, DJISimulatorDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var simulatorButton: UIBarButtonItem!
    @IBOutlet weak var simulatorPanel: UIStackView!
    @IBOutlet weak var flyingLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var zLabel: UILabel!
    
    let mapService = MapService()
    let flightService = FlightService()
    
    var isSimulating = false
    var isEditingPoints = false
    
    var droneLocation: CLLocationCoordinate2D?
    
    var missionRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        
        //create tap gesture for map view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoint(tapGesture:)))
        mapView.addGestureRecognizer(tapGesture)
        //set flight controller delegate
        if let flightController = fetchFlightController() {
            flightController.delegate = self
            flightController.simulator?.delegate = self
        } else {
            showAlert(from: self, title: "Flight Controller", message: "Flight controller not connected.")
        }
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
    
    func loadMission() {
        //add locations to waypoint mission
        let waypoints = mapService.points
        if waypoints.count < 2 {
            showAlert(from: self, title: "Load Mission", message: "Not enough waypoints for mission")
            return
        }
        
        //reset or create mission
        if let mission = flightService.waypointMission {
            mission.removeAllWaypoints()
        } else {
            flightService.waypointMission = DJIMutableWaypointMission()
        }
        
        //set mission parameters
        flightService.waypointMission!.autoFlightSpeed = 8
        flightService.waypointMission!.maxFlightSpeed = 10
        flightService.waypointMission!.headingMode = .auto
        flightService.waypointMission!.finishedAction = .noAction
        
        for location in waypoints {
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                let waypoint = DJIWaypoint(coordinate: location.coordinate)
                waypoint.altitude = 20
                flightService.waypointMission!.add(waypoint)
            }
        }
    }
    
    func updateUI() {
        simulatorPanel.isHidden = !isSimulating
        simulatorButton.title = isSimulating ? "Stop Sim" : "Start Sim"
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
        flightService.waypointMission?.removeAllWaypoints()
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
                    self.updateUI()
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
                    self.updateUI()
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
    
    //MARK: - DJIFlightControllerDelegate methods
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        droneLocation = state.aircraftLocation?.coordinate
        guard let location = droneLocation else {
            return
        }
        
        //update aircraft location and heading on map
        mapService.updateAircraft(location: location, on: mapView)
        
        let yawRadian = state.attitude.yaw * (Double.pi / 180) //convert to radians
        mapService.updateAircraft(heading: Float(yawRadian))
        
        //generate data for mission
        if missionRunning, let flightData = flightService.generateFlightData(at: location) {
            fc.send(flightData, withCompletion: nil)
        }
    }
    
    //MARK: - DJISimulatorDelegate methods
    
    func simulator(_ simulator: DJISimulator, didUpdate state: DJISimulatorState) {
        flyingLabel.text = "\(state.isFlying)"
        xLabel.text = "x: \(state.positionX)"
        yLabel.text = "y: \(state.positionY)"
        zLabel.text = "z: \(state.positionZ)"
    }

}
