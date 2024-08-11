//
//  AppDelegate.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    static var orientationLock = UIInterfaceOrientationMask.portrait // Default to portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
        UIViewController.attemptRotationToDeviceOrientation()
    }

    static func setOrientation(to orientation: UIInterfaceOrientation) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation == .portrait ? .portrait : .landscape))
        }
        AppDelegate.lockOrientation(orientation == .portrait ? .portrait : .landscape)
    }
}