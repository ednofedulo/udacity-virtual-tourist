//
//  DetailViewController.swift
//  udacity-virtual-tourist
//
//  Created by Edno Fedulo on 18/06/18.
//  Copyright © 2018 Fedulo. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class DetailViewController: UIViewController {

    var pin:Pin!
    var photos:[Photo]!
    
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var reloadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        loadMap()
    }
    
    func loadMap(){
        let annotation = CustomMKPointAnnotation()
        
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        annotation.coordinate = coordinate
        annotation.objectID = pin.objectID
        
        mapView.addAnnotation(annotation)
        
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        
        mapView.setRegion(region, animated: false)
    }

}

extension DetailViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = false
        }
        return pinView
    }
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let album = pin.album else {
            return 0
        }
        
        guard let photos = album.photos else {
            return 0
        }
        print(photos.count)
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! CustomCollectionViewCell
        
        let photo = pin.album?.photos!.allObjects[indexPath.row] as! Photo
        
        if let image = photo.image, image != UIImagePNGRepresentation(#imageLiteral(resourceName: "image-placeholder")) {
            cell.cellImage.image = UIImage(data: image)
        } else {
            cell.cellImage.image = #imageLiteral(resourceName: "image-placeholder")
            DispatchQueue.main.async {
                let url = URL(string: photo.url!)
                let data = try? Data(contentsOf: url!)
                photo.image = data!
                try? photo.managedObjectContext?.save()
                cell.cellImage.image = UIImage(data: data!)
            }
        }
        
        return cell
    }
}
