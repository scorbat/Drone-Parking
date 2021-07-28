//
//  MapViewController.swift
//  DroneParking
//
//  Created by admin on 7/27/21.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let mapService = MapService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create tap gesture for map view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addWaypoint(tapGesture:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func addWaypoint(tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .ended {
            let point = tapGesture.location(in: mapView)
            mapService.add(point: point, for: mapView)
        }
    }
    
    //MARK: - MKMapViewDelegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "waypoint_annotation")
            return pin
        }
        
        return nil
    }

}
