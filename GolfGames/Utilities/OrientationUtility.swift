//
//  OrientationUtility.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import UIKit

struct OrientationUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        // Use the new method for iOS 16 and later
        if #available(iOS 16.0, *) {
            UIViewController().setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
