//
//  AppDelegate.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var orientationLock = UIInterfaceOrientationMask.all // Default orientation lock

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
}
