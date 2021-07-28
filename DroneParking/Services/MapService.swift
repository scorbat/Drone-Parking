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
            mapView.removeAnnotation(annotation)
        }
    }
    
}
