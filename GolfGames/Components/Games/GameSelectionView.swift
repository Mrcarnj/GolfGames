//
//  GameSelectionView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/2/24.
//

import SwiftUI

struct GameSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    var onBeginRound: () -> Void
    
    @State private var showingMatchPlayInfo = false
    @State private var showingBetterBallInfo = false
    @State private var selectedMatchPlayGolfers: [Golfer] = []
    @State private var refreshID = UUID()
    @State private var isBetterBall = false
    @State private var betterBallTeamAssignments: [String: String] = [:]
    @State private var isNinePoint = false
    @State private var showingNinePointInfo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                gameSelectionHeader
                
                gameToggleSection
                
                if sharedViewModel.isMatchPlay {
                    
                        matchPlayGolferSelectionSection
                        matchPlayInfoSection
                    
                }
                if isBetterBall {
                betterBallInfoSection
            }
                if isNinePoint {
                    ninePointInfoSection
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
                initializeTeamAssignments()
            }
            .alert(isPresented: $showingMatchPlayInfo) {
                Alert(
                    title: Text("What is Match Play?"),
                    message: Text("Select this for 18-hole match play between 2 golfers. Match Play is a scoring format where players compete against each other hole-by-hole. The player with the lowest net score on a hole wins that hole. The match continues until one player is ahead by more holes than there are remaining to play."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingBetterBallInfo) {
                Alert(
                    title: Text("What is Better Ball?"),
                    message: Text("Select this for 18-hole better ball between 3 or more golfers. Better Ball is a scoring format where players compete as two person teams against each other hole-by-hole. The team with the lowest net score on a hole wins that hole. The match continues until one team is ahead by more holes than there are remaining to play."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingNinePointInfo) {
                Alert(
                    title: Text("What is 9 Point?"),
                    message: Text("9 Point is a 3-player game where each hole is worth 9 points. Points are distributed based on net scores: 5 for lowest, 3 for middle, and 1 for highest. Ties split points evenly. The player with the most points at the end of the round wins."),
                    dismissButton: .default(Text("OK"))
                )
            }
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
            
            // Match Play toggle
            gameToggle(isOn: $sharedViewModel.isMatchPlay,
                       imageName: "flag.fill",
                       text: "Match Play",
                       action: showMatchPlayInfo)
                .onChange(of: sharedViewModel.isMatchPlay) { newValue in
                }
            
            // Better Ball toggle
            if sharedViewModel.golfers.count >= 3 {
                gameToggle(isOn: $isBetterBall,
                           imageName: "person.3.fill",
                           text: "Better Ball",
                           action: showBetterBallInfo)
                    .onChange(of: isBetterBall) { newValue in
                    }
            }
            
            // Nine Point toggle
            if sharedViewModel.golfers.count == 3 {
                gameToggle(isOn: $isNinePoint,
                           imageName: "9.alt.square.fill",
                           text: "9 Point (Baseball)",
                           action: showNinePointInfo)
                    .onChange(of: isNinePoint) { newValue in
                    }
            }
        }
    }

    private func gameToggle(isOn: Binding<Bool>, imageName: String, text: String, action: @escaping () -> Void) -> some View {
        HStack {
            Toggle(isOn: isOn) {
                HStack(alignment: .center) {
                    Image(systemName: imageName)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(text)
                        .font(.subheadline)
                }
            }
            
            Button(action: action) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var matchPlayGolferSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select 2 Golfers for Match Play")
                .font(.headline)
            
            ForEach(sharedViewModel.golfers) { golfer in
                HStack {
                    Text("\(golfer.firstName) \(golfer.lastName.prefix(1)).")
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
            let matchPlayHandicaps = calculateGameHandicaps(for: selectedMatchPlayGolfers)
            let golfer1 = selectedMatchPlayGolfers[0]
            let golfer2 = selectedMatchPlayGolfers[1]
            
            VStack(alignment: .center, spacing: 15) {
                Text("Match Play Details")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    PlayerAvatar(name: "\(golfer1.firstName) \(golfer1.lastName.prefix(1)).")
                    Text("vs")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    PlayerAvatar(name: "\(golfer2.firstName) \(golfer2.lastName.prefix(1)).")
                }
                
                if let handicap1 = matchPlayHandicaps[golfer1.id],
                   let handicap2 = matchPlayHandicaps[golfer2.id] {
                    if handicap1 > 0 {
                        Text("\(golfer1.firstName) \(golfer1.lastName) gets \(handicap1) stroke\(handicap1 == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else if handicap2 > 0 {
                        Text("\(golfer2.firstName) \(golfer2.lastName) gets \(handicap2) stroke\(handicap2 == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("No strokes given")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
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
    private var betterBallInfoSection: some View {
        Group {
            if isBetterBall {
                let betterBallHandicaps = calculateGameHandicaps(for: sharedViewModel.golfers)
                let lowestHandicapGolfer = sharedViewModel.golfers.min { betterBallHandicaps[$0.id] ?? 0 < betterBallHandicaps[$1.id] ?? 0 }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Better Ball Teams")
                        .font(.headline)
                    
                    ForEach(sharedViewModel.golfers, id: \.id) { golfer in
                        HStack {
                            Text(roundViewModel.formattedGolferName(for: golfer))
                                .font(.subheadline)
                            
                            if golfer.id == lowestHandicapGolfer?.id {
                                Text("0 strokes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let handicap = betterBallHandicaps[golfer.id], handicap > 0 {
                                Text("\(handicap) stroke\(handicap == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()

                            Picker("Team", selection: Binding(
                                get: { self.betterBallTeamAssignments[golfer.id] ?? "Not Playing" },
                                set: { self.betterBallTeamAssignments[golfer.id] = $0 }
                            )) {
                                Text("Team A").tag("Team A")
                                Text("Team B").tag("Team B")
                                Text("Not Playing").tag("Not Playing")
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }

    private var ninePointInfoSection: some View {
        Group {
            if isNinePoint {
                let ninePointHandicaps = calculateGameHandicaps(for: sharedViewModel.golfers)
                let lowestHandicapGolfer = sharedViewModel.golfers.min { ninePointHandicaps[$0.id] ?? 0 < ninePointHandicaps[$1.id] ?? 0 }
                
                VStack(alignment: .center, spacing: 10) {
                    Text("9 Point Players")
                        .font(.headline)
                    
                    ForEach(sharedViewModel.golfers, id: \.id) { golfer in
                        HStack {
                            Text(roundViewModel.formattedGolferName(for: golfer))
                                .font(.subheadline)
                            
                            if golfer.id == lowestHandicapGolfer?.id {
                                Text("0 strokes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let handicap = ninePointHandicaps[golfer.id], handicap > 0 {
                                Text("\(handicap) stroke\(handicap == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }

    private var beginRoundButton: some View {
    Button(action: {
        // Update roundViewModel with the selected game types
        roundViewModel.isMatchPlay = sharedViewModel.isMatchPlay
        roundViewModel.isBetterBall = isBetterBall
        roundViewModel.isNinePoint = isNinePoint
        
        // Set up Match Play if selected
        if sharedViewModel.isMatchPlay && selectedMatchPlayGolfers.count == 2 {
            roundViewModel.setMatchPlayGolfers(golfer1: selectedMatchPlayGolfers[0], golfer2: selectedMatchPlayGolfers[1])
        }
        
        // Set up Better Ball if selected
        if isBetterBall {
            let validAssignments = betterBallTeamAssignments.filter { $0.value != "Not Playing" }
            roundViewModel.setBetterBallTeams(validAssignments)
        }
        
        // Set up Nine Point if selected
        if isNinePoint {
            roundViewModel.initializeNinePoint()
        }
        
        // Ensure all selected golfers are included in the round
        roundViewModel.golfers = sharedViewModel.golfers
        
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
    .disabled(
        (sharedViewModel.isMatchPlay && selectedMatchPlayGolfers.count != 2) ||
        (isBetterBall && !isValidBetterBallSetup()) ||
        (isNinePoint && sharedViewModel.golfers.count != 3) ||
        (!sharedViewModel.isMatchPlay && !isBetterBall && !isNinePoint) // Disable if no game type is selected
    )
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
    
private func calculateGameHandicaps(for golfers: [Golfer]) -> [String: Int] {
    let golfersWithHandicaps = golfers.map { golfer -> (String, Float) in
        let handicap: Float
        if let courseHandicap = golfer.courseHandicap {
            handicap = Float(courseHandicap)
        } else {
            handicap = golfer.handicap
        }
        return (golfer.id, handicap)
    }
    
    guard let lowestHandicap = golfersWithHandicaps.min(by: { $0.1 < $1.1 }) else { return [:] }
    let lowestHandicapValue = lowestHandicap.1
    
    var gameHandicaps: [String: Int] = [:]
    
    for (golferId, handicap) in golfersWithHandicaps {
        let handicapDifference = max(0, handicap - lowestHandicapValue)
        gameHandicaps[golferId] = Int(round(handicapDifference))
    }
    
    return gameHandicaps
}

    
    private func printDebugInfo() {
        print("Debug: GameSelectionView - Match Play: \(sharedViewModel.isMatchPlay)")
        print("Debug: GameSelectionView - Match Play Handicap: \(sharedViewModel.matchPlayHandicap)")
        print("Debug: GameSelectionView - Golfers: \(sharedViewModel.golfers.map { "\($0.firstName) \($0.lastName) (Handicap: \($0.handicap), Course Handicap: \($0.courseHandicap ?? 0))" })")
    }
    
    private func showMatchPlayInfo() {
        showingMatchPlayInfo = true
    }
    private func showBetterBallInfo() {
        showingBetterBallInfo = true
    }
    private func showNinePointInfo() {
        showingNinePointInfo = true
    }

    private func initializeTeamAssignments() {
        let golfers = sharedViewModel.golfers
        for (index, golfer) in golfers.enumerated() {
            if index == 0 {
                betterBallTeamAssignments[golfer.id] = "Team A"
            } else if index < 3 {
                betterBallTeamAssignments[golfer.id] = "Team B"
            } else if index == 3 {
                betterBallTeamAssignments[golfer.id] = "Team B"
            } else {
                betterBallTeamAssignments[golfer.id] = "Not Playing"
            }
        }
    }

    private func isValidBetterBallSetup() -> Bool {
        let teamACounts = betterBallTeamAssignments.values.filter { $0 == "Team A" }.count
        let teamBCounts = betterBallTeamAssignments.values.filter { $0 == "Team B" }.count
        return (teamACounts == 1 && teamBCounts == 2) || 
               (teamACounts == 2 && teamBCounts == 1) || 
               (teamACounts == 1 && teamBCounts == 3) ||
               (teamACounts == 2 && teamBCounts == 2)
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
