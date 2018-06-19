//
//  ViewController.swift
//  udacity-virtual-tourist
//
//  Created by Edno Fedulo on 05/06/18.
//  Copyright © 2018 Fedulo. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {

    var dataController:DataController!
    let flickrClient = FlickrClient()
    var pins:[Pin]?
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        pins = try? dataController.viewContext.fetch(fetchRequest)
        
        mapView.delegate = self
        configureMapGestureRecognizer()
        loadPins()
    }

    func configureMapGestureRecognizer(){
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin(press:)))
        longPressGestureRecognizer.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func loadPins(){
        for pin in pins! {
            let annotation = MKPointAnnotation()
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
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
        pin.creationDate = Date()
        
        flickrClient.loadGallery(latitude: pin.latitude, longitude: pin.longitude) { (urls) in
            guard urls.count == 21 else {
                print("incorrect item count")
                return
            }
            
            let album = Album(context: self.dataController.viewContext)
            for url in urls {
                let photo = Photo(context: self.dataController.viewContext)
                photo.url = url.absoluteString
                photo.image = try? Data(contentsOf: url)
                
                album.addToPhotos(photo)
            }
            
            pin.album = album
            try? self.dataController.viewContext.save()
        }
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
