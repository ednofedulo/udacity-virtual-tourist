//
//  ViewController.swift
//  udacity-virtual-tourist
//
//  Created by Edno Fedulo on 05/06/18.
//  Copyright © 2018 Fedulo. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    var dataController:DataController!
    let flickrClient = FlickrClient()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        configureMapGestureRecognizer()
    }

    func configureMapGestureRecognizer(){
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin(press:)))
        longPressGestureRecognizer.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func loadPins(){
        
    }

    @objc
    func addPin(press:UILongPressGestureRecognizer){
        if press.state != .began {
            return
        }
        
        let location = press.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        
        savePin(latitude: Float(coordinates.latitude), longitude: Float(coordinates.longitude))
        
        mapView.addAnnotation(annotation)
    }
    
    func savePin(latitude:Float, longitude:Float){
        let pin = Pin(context: dataController.viewContext)
        
        pin.latitude = latitude
        pin.longitude = longitude
        
        let _ = flickrClient.loadGallery(latitude: pin.latitude, longitude: pin.longitude) { (album) in
            guard album.count == 21 else {
                print("incorrect item count")
                return
            }
            
            for url in album {
                print(url)
            }
        }
        
        try? dataController.viewContext.save()
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
        }
        return pinView
    }
    
}
