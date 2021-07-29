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
    
    let mapService = MapService()
    let locationManager = CLLocationManager()
    
    var userLocation: CLLocationCoordinate2D?
    var droneLocation: CLLocationCoordinate2D?
    
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
        if tapGesture.state == .ended {
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
    
    //MARK: - IBActions
    
    @IBAction func focusPressed(_ sender: UIButton) {
        focusMap()
    }
    
    //MARK: - MKMapViewDelegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "waypoint_annotation")
            return pin
        } else if annotation is AircraftAnnotation {
            //create custom annotation for aircraft
            let aircraft = AircraftAnnotationView(annotation: annotation, reuseIdentifier: "aircraft_annotation")
            (annotation as! AircraftAnnotation).annotationView = aircraft
            return aircraft
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
