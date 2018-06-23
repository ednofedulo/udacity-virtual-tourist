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

    var dataController:DataController!
    var pin:Pin!
    var photos:[Photo]!
    var isEditingGallery:Bool = false
    let flickrClient:FlickrClient = FlickrClient()
    
    var loadingIndicator:UIAlertController?
    
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var reloadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
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
    
    func showLoading(){
        loadingIndicator = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        indicator.hidesWhenStopped = true
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        indicator.startAnimating();
        
        loadingIndicator!.view.addSubview(indicator)
        present(loadingIndicator!, animated: true, completion: nil)
    }
    
    func dismissLoading(){
        if loadingIndicator != nil {
            loadingIndicator?.dismiss(animated: true, completion: nil)
        }
    }
    
    func reloadGallery(){
        
        showLoading()
        
        dataController.viewContext.delete(pin.album!)
        try? dataController.viewContext.save()
        
        flickrClient.loadGallery(latitude: pin.latitude, longitude: pin.longitude) { (urls) in
            
            let backgroundContext:NSManagedObjectContext! = self.dataController?.backgroundContext
            
            let album = Album(context: self.dataController.viewContext)
            self.pin.album = album
            
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
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.dismissLoading()
                }
                
            }
            
            try? self.dataController.viewContext.save()
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if (collectionView.indexPathsForSelectedItems?.count)! > 0 {
            removeItems()
        } else {
            reloadGallery()
        }
    }
    
    func removeItems(){
        guard collectionView.indexPathsForSelectedItems != nil, (collectionView.indexPathsForSelectedItems?.count)! > 0, let indexes = collectionView.indexPathsForSelectedItems else {
            return
        }
        
        for i in 0...indexes.count - 1{
            let indexPath = indexes[i]
            let row = indexPath.row
            
            let photo = pin.album?.photos!.allObjects[row] as! Photo
            
            pin.managedObjectContext?.delete(photo)
        }
        
        try? pin.managedObjectContext?.save()
        
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        reloadButton.setTitle("Reload Gallery", for: .normal)
        reloadButton.backgroundColor = UIButton().backgroundColor
        reloadButton.tintColor = UIButton().tintColor
        
        collectionView.reloadData()
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedIndexes = collectionView.indexPathsForSelectedItems {
            
            if selectedIndexes.count > 0 {
                reloadButton.setTitle("Remove Selected Photos", for: .normal)
                reloadButton.backgroundColor = UIColor.red
                reloadButton.tintColor = UIColor.white
            }
            
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 5.0
            cell?.layer.borderColor = UIColor.red.cgColor
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if let selectedIndexes = collectionView.indexPathsForSelectedItems {
            
            if selectedIndexes.count == 0 {
                reloadButton.setTitle("Reload Gallery", for: .normal)
                reloadButton.backgroundColor = UIButton().backgroundColor
                reloadButton.tintColor = UIButton().tintColor
            }
            
            let cell = collectionView.cellForItem(at: indexPath)
            
            cell?.layer.borderWidth = UICollectionViewCell().layer.borderWidth
            cell?.layer.borderColor = UICollectionViewCell().layer.borderColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let album = pin.album else {
            return 0
        }
        
        guard let photos = album.photos else {
            return 0
        }
        
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! CustomCollectionViewCell
        
        let photo = pin.album?.photos!.allObjects[indexPath.row] as! Photo
        
        if photo.image != nil, let image = photo.image, image != UIImagePNGRepresentation(#imageLiteral(resourceName: "image-placeholder")) {
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
        
        if cell.isSelected {
            cell.layer.borderWidth = 5.0
            cell.layer.borderColor = UIColor.red.cgColor
        } else {
            cell.layer.borderWidth = UICollectionViewCell().layer.borderWidth
            cell.layer.borderColor = UICollectionViewCell().layer.borderColor
        }
        
        return cell
    }
}
