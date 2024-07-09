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
    @StateObject private var viewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
