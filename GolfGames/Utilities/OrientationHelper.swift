//
//  OrientationHelper.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/11/24.
//

import SwiftUI

enum OrientationHelper {
    static func setOrientation(to orientation: UIInterfaceOrientation) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation == .portrait ? .portrait : .landscape))
        }
    }
}
