//
//  OrientationObserver.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import SwiftUI

struct OrientationObserver: ViewModifier {
    @Binding var isLandscape: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                    let orientation = UIDevice.current.orientation
                    if orientation.isLandscape {
                        isLandscape = true
                    } else if orientation.isPortrait {
                        isLandscape = false
                    }
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
            }
    }
}

extension View {
    func onOrientationChange(isLandscape: Binding<Bool>) -> some View {
        self.modifier(OrientationObserver(isLandscape: isLandscape))
    }
}
