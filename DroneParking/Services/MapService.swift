//
//  MapService.swift
//  DroneParking
//
//  Created by admin on 7/28/21.
//

import Foundation
import MapKit


class MapService: NSObject {
    
    var points = [CLLocation]()
    var aircraftAnnotation: AircraftAnnotation?
    
    //MARK: Annotation methods
    
    func add(point: CGPoint, for mapView: MKMapView) {
        //get coordinate and add it to points list
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        points.append(location)
        
        //add annotation for point
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func cleanPoints(in mapView: MKMapView) {
        points.removeAll()
        
        for annotation in mapView.annotations {
            //dont want to remove the aircraft annotation
            if annotation !== aircraftAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    //MARK: Aircraft Annotation methods
    
    func updateAircraft(location: CLLocationCoordinate2D, on mapView: MKMapView) {
        if let annotation = aircraftAnnotation {
            annotation.coordinate = location
        } else {
            aircraftAnnotation = AircraftAnnotation(coordinate: location)
            mapView.addAnnotation(aircraftAnnotation!)
        }
    }
    
    func updateAircraft(heading: Float) {
        if let annotation = aircraftAnnotation {
            annotation.update(heading: heading)
        }
    }
    
}
