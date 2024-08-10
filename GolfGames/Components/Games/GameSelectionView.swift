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
    
    @State private var showingMatchPlayInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            gameSelectionHeader
            
            gameToggleSection
            
            if sharedViewModel.isMatchPlay {
                matchPlayInfoSection
            }
            
            Spacer()
            
            beginRoundButton
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Select Games")
        .onAppear { printDebugInfo() }
        .alert(isPresented: $showingMatchPlayInfo) {
            Alert(
                title: Text("What is Match Play?"),
                message: Text("Select this for 18-hole match play between 2 golfers. Match Play is a scoring format where players compete against each other hole-by-hole. The player with the lowest net score on a hole wins that hole. The match continues until one player is ahead by more holes than there are remaining to play."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var gameSelectionHeader: some View {
        Text("Game Selection")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top)
    }
    
    private var gameToggleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Games")
                .font(.headline)
            
            HStack {
                Toggle(isOn: $sharedViewModel.isMatchPlay) {
                    HStack (alignment: .center) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.blue)
                        Text("Match Play")
                            .font(.subheadline)
                    }
                }
                
                Button(action: {
                    showMatchPlayInfo()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .onChange(of: sharedViewModel.isMatchPlay) { newValue in
                if newValue {
                    roundViewModel.initializeMatchPlay()
                } else {
                    roundViewModel.matchPlayViewModel = nil
                }
            }
        }
    }
    
    private var matchPlayInfoSection: some View {
        Group {
            if sharedViewModel.golfers.count == 2 {
                let matchPlayHandicap = sharedViewModel.matchPlayHandicap
                let golfer1 = sharedViewModel.golfers[0]
                let golfer2 = sharedViewModel.golfers[1]
                
                VStack(alignment: .center, spacing: 15) {
                    Text("Match Play Details")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        PlayerAvatar(name: golfer1.fullName)
                        Text("vs")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        PlayerAvatar(name: golfer2.fullName)
                    }
                    
                    Text("\(golfer2.fullName) gets \(matchPlayHandicap) stroke\(matchPlayHandicap == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            } else {
                Text("Please select 2 golfers for Match Play")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var beginRoundButton: some View {
        Button(action: {
            onBeginRound()
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Begin Round")
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
        }
    }
    
    private func printDebugInfo() {
        print("Debug: GameSelectionView - Match Play: \(sharedViewModel.isMatchPlay)")
        print("Debug: GameSelectionView - Match Play Handicap: \(sharedViewModel.matchPlayHandicap)")
        print("Debug: GameSelectionView - Golfers: \(sharedViewModel.golfers.map { "\($0.fullName) (Handicap: \($0.handicap), Course Handicap: \($0.courseHandicap ?? 0))" })")
    }
    
    private func showMatchPlayInfo() {
        showingMatchPlayInfo = true
    }
}

struct PlayerAvatar: View {
    let name: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
            
            Text(name.prefix(1).uppercased())
                .foregroundColor(.white)
                .font(.headline)
        }
    }
}
