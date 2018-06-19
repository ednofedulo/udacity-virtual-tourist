//
//  DetailViewController.swift
//  udacity-virtual-tourist
//
//  Created by Edno Fedulo on 18/06/18.
//  Copyright © 2018 Fedulo. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {

    var pin:Pin!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        loadMap()
        loadGallery()
    }
    
    func loadMap(){
        
    }
    
    func loadGallery(){
        
    }

}

/*extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
}

extension DetailViewController: NSFetchedResultsControllerDelegate {
    
}*/
