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
    var editingMode:Bool = false
    
    @IBOutlet weak var editingModeMessage: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
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
            let annotation = CustomMKPointAnnotation()
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

            annotation.coordinate = coordinate
            annotation.objectID = pin.objectID
            
            mapView.addAnnotation(annotation)
        }
    }

    @IBAction func editButtonTapped(_ sender: Any) {
        editingMode = !editingMode
        
        if editingMode {
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                self.editingModeMessage.alpha = 1
            }, completion: { _ in
                self.editingModeMessage.isHidden = false
            })
            editButton.title = "Done"
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                self.editingModeMessage.alpha = 0
            }, completion: { _ in
                self.editingModeMessage.isHidden = true
            })
            
            editButton.title = "Edit"
        }
        
        
    }
    
    @objc
    func addPin(press:UILongPressGestureRecognizer){
        if press.state != .began {
            return
        }
        
        let location = press.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        
        let annotation = CustomMKPointAnnotation()
        annotation.coordinate = coordinates
        
        let objId = savePin(latitude: Float(coordinates.latitude), longitude: Float(coordinates.longitude))
        
        annotation.objectID = objId
        
        mapView.addAnnotation(annotation)
    }
    
    func savePin(latitude:Float, longitude:Float) -> NSManagedObjectID{
        let pin = Pin(context: dataController.viewContext)
        
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()
        
        try? dataController.viewContext.save()
        
        flickrClient.loadGallery(latitude: pin.latitude, longitude: pin.longitude) { (urls) in
            
            let backgroundContext:NSManagedObjectContext! = self.dataController?.backgroundContext
            
            let album = Album(context: self.dataController.viewContext)
            pin.album = album
            
            try? self.dataController.viewContext.save()
            
            let albumId = album.objectID
            
            self.dataController.backgroundContext.perform {
                let bgAlbum = backgroundContext.object(with: albumId) as! Album
                for url in urls {
                    let photo = Photo(context: backgroundContext)
                    photo.url = url.absoluteString
                    
                    bgAlbum.addToPhotos(photo)
                    try? backgroundContext.save()
                }
                
                print("finished loop")
            }
            
            try? self.dataController.viewContext.save()
        }
        
        return pin.objectID
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let annotation = sender as! CustomMKPointAnnotation
        
        let pin = dataController.viewContext.object(with: annotation.objectID!) as! Pin
        
        let detailVc:DetailViewController = segue.destination as! DetailViewController
        
        detailVc.pin = pin
        detailVc.dataController = dataController
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation as! CustomMKPointAnnotation
        
        if editingMode {
            
            let pin = dataController.viewContext.object(with: annotation.objectID!) as! Pin
            mapView.removeAnnotation(annotation)
            dataController.viewContext.delete(pin)
            try? dataController.viewContext.save()
            
        } else {
            performSegue(withIdentifier: "showDetailSegue", sender: annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
        }
        return pinView
    }
    
}
