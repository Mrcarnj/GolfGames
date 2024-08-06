//
//  GameSelectionView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/2/24.
//

import SwiftUI

struct GameSelectionView: View {
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    var onBeginRound: () -> Void

    var body: some View {
        VStack {
            Toggle("Match Play", isOn: $sharedViewModel.isMatchPlay)
                .padding()
                .onChange(of: sharedViewModel.isMatchPlay) { _ in
                    printDebugInfo()
                }

            if sharedViewModel.isMatchPlay && sharedViewModel.golfers.count == 2 {
                let matchPlayHandicap = sharedViewModel.matchPlayHandicap
                let golfer1 = sharedViewModel.golfers[0]
                let golfer2 = sharedViewModel.golfers[1]
                
                Text("\(golfer1.fullName) vs \(golfer2.fullName)")
                    .font(.headline)
                    .padding()
                
                Text("\(golfer2.fullName) gets \(matchPlayHandicap) strokes")
                    .font(.subheadline)
                    .padding()
            }
            Spacer ()

            Button("Begin Round") {
                onBeginRound()
                presentationMode.wrappedValue.dismiss()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .background(Color(.systemTeal))
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.headline)
            .padding(.horizontal)
        }
        .navigationTitle("Select Games")
        .onAppear {
            printDebugInfo()
        }
    }
    
    private func printDebugInfo() {
        print("Debug: GameSelectionView - Match Play: \(sharedViewModel.isMatchPlay)")
        print("Debug: GameSelectionView - Match Play Handicap: \(sharedViewModel.matchPlayHandicap)")
        print("Debug: GameSelectionView - Golfers: \(sharedViewModel.golfers.map { "\($0.fullName) (Handicap: \($0.handicap), Playing Handicap: \($0.playingHandicap ?? 0))" })")
    }
}