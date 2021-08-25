//
//  AircraftAnnotationView.swift
//  DroneParking
//
//  Created by admin on 7/28/21.
//

import UIKit
import MapKit

//MARK: - AircraftAnnotation

class AircraftAnnotation: NSObject, MKAnnotation {
    
    //must be marked as dynamic for annotation to move
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var annotationView: AircraftAnnotationView?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    func update(heading: Float) {
        annotationView?.update(heading: heading)
    }
    
}

//MARK: - AircraftAnnotationView

class AircraftAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        isEnabled = false
        isDraggable = false
        image = UIImage(named: K.AIRCRAFT_IMAGE_NAME)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //updates the heading (which way the drone is facing)
    func update(heading: Float) {
        transform = .identity
        //icon may have some amount of rotation already, so offset that
        transform = CGAffineTransform(rotationAngle: CGFloat(heading + K.AIRCRAFT_IMAGE_ROTATION_OFFSET))
    }
    
}
