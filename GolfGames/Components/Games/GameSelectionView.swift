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
    @State private var selectedMatchPlayGolfers: [Golfer] = []
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            gameSelectionHeader
            
            gameToggleSection
            
            if sharedViewModel.isMatchPlay {
                if sharedViewModel.golfers.count > 2 {
                    matchPlayGolferSelectionSection
                }
                matchPlayInfoSection
            }
            
            Spacer()
            
            beginRoundButton
        }
        .id(refreshID) // Force view refresh
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Select Games")
        .onAppear { 
            printDebugInfo()
            initializeSelectedGolfers()
        }
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
//                    roundViewModel.matchPlayViewModel = nil
                }
            }
        }
    }
    
    private var matchPlayGolferSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select 2 Golfers for Match Play")
                .font(.headline)
            
            ForEach(sharedViewModel.golfers) { golfer in
                HStack {
                    Text(golfer.fullName)
                    Spacer()
                    if selectedMatchPlayGolfers.contains(where: { $0.id == golfer.id }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleGolferSelection(golfer)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var matchPlayInfoSection: some View {
        Group {
            if selectedMatchPlayGolfers.count == 2 {
                let matchPlayHandicap = calculateMatchPlayHandicap()
                let golfer1 = selectedMatchPlayGolfers[0]
                let golfer2 = selectedMatchPlayGolfers[1]
                
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
                    
                    if matchPlayHandicap > 0 {
                        let lowerHandicapGolfer = golfer1.handicap < golfer2.handicap ? golfer1 : golfer2
                        let higherHandicapGolfer = golfer1.handicap < golfer2.handicap ? golfer2 : golfer1
                        Text("\(higherHandicapGolfer.fullName) gets \(matchPlayHandicap) stroke\(matchPlayHandicap == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("No strokes given")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
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
            if sharedViewModel.isMatchPlay && selectedMatchPlayGolfers.count == 2 {
                roundViewModel.setMatchPlayGolfers(golfer1: selectedMatchPlayGolfers[0], golfer2: selectedMatchPlayGolfers[1])
            }
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
        .disabled(sharedViewModel.isMatchPlay && selectedMatchPlayGolfers.count != 2)
    }
    
    private func initializeSelectedGolfers() {
        if sharedViewModel.golfers.count >= 2 {
            selectedMatchPlayGolfers = Array(sharedViewModel.golfers.prefix(2))
        }
    }
    
    private func toggleGolferSelection(_ golfer: Golfer) {
        if let index = selectedMatchPlayGolfers.firstIndex(where: { $0.id == golfer.id }) {
            selectedMatchPlayGolfers.remove(at: index)
        } else if selectedMatchPlayGolfers.count < 2 {
            selectedMatchPlayGolfers.append(golfer)
        }
        refreshID = UUID()  // Force view refresh
    }
    
    private func calculateMatchPlayHandicap() -> Int {
        guard selectedMatchPlayGolfers.count == 2 else { return 0 }
        
        let handicap1: Float
        if let courseHandicap = selectedMatchPlayGolfers[0].courseHandicap {
            handicap1 = Float(courseHandicap)
        } else {
            handicap1 = selectedMatchPlayGolfers[0].handicap
        }
        
        let handicap2: Float
        if let courseHandicap = selectedMatchPlayGolfers[1].courseHandicap {
            handicap2 = Float(courseHandicap)
        } else {
            handicap2 = selectedMatchPlayGolfers[1].handicap
        }
        
        return Int(round(abs(handicap1 - handicap2)))
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
