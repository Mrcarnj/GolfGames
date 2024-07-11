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
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var singleRoundViewModel = SingleRoundViewModel()
    @StateObject private var roundViewModel = RoundViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(singleRoundViewModel)
                .environmentObject(roundViewModel)
        }
    }
}

