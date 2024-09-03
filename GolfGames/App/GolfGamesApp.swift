//
//  GolfGamesApp.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import SwiftUI
import Firebase

@main
struct GolfGamesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var singleRoundViewModel = SingleRoundViewModel()
    @StateObject private var roundViewModel = RoundViewModel()
    @StateObject private var sharedViewModel = SharedViewModel()
    @StateObject private var locationManager = LocationManager()
    
    init() {
        FirebaseApp.configure()
        let shared = SharedViewModel()
        _sharedViewModel = StateObject(wrappedValue: shared)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(singleRoundViewModel)
                .environmentObject(roundViewModel)
                .environmentObject(sharedViewModel)
                .environmentObject(locationManager)
                .onAppear {
                    Task {
                        await authViewModel.performAutoSignOutIfNeeded()
                    }
                    // Set initial orientation lock to portrait
                    AppDelegate.lockOrientation(.portrait)
                    // Request location permission
                    locationManager.requestLocation()
                }
        }
    }
}
