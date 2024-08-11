//
//  OrientationControl.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/11/24.
//

import SwiftUI
import UIKit

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct OrientationLockedControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return OrientationLockedController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class OrientationLockedController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}