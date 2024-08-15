//
//  ContentView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var matchPlayViewModel: MatchPlayViewModel

    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                LoginView()
            } else {
                InititalView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
       static var previews: some View {
           ContentView()
               .environmentObject(AuthViewModel())
               .environmentObject(SharedViewModel())
               .environmentObject(MatchPlayViewModel(player1Id: "", player2Id: "", matchPlayHandicap: 0))
       }
   }
