//
//  AppDelegate.swift
//  udacity-virtual-tourist
//
//  Created by Edno Fedulo on 05/06/18.
//  Copyright © 2018 Fedulo. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "udacity_virtual_tourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        dataController.load()
        
        let navController = window?.rootViewController as! UINavigationController
        let mapViewController = navController.topViewController as! MapViewController
        
        mapViewController.dataController = dataController
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        self.saveContext()
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        try? dataController.viewContext.save()
    }

}

