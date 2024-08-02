//
//  HoleView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI

struct HoleView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @State private var navigateToInitialView = false
    
    let teeId: String
    let initialHoleIndex: Int
    
    @State private var currentHoleIndex: Int
    @State private var scoreInputs: [String: String] = [:]
    @FocusState private var focusedGolferId: String?
    @State private var showMissingScores = false
    @State private var missingScores: [String: [Int]] = [:]
    @State private var holesLoaded = false
    @State private var orientation = UIDeviceOrientation.unknown

    init(teeId: String, holeNumber: Int) {
        self.teeId = teeId
        self.initialHoleIndex = holeNumber - 1
        self._currentHoleIndex = State(initialValue: holeNumber - 1)
    }

    var hole: Hole? {
        guard currentHoleIndex < singleRoundViewModel.holes.count else {
            print("Error: currentHoleIndex (\(currentHoleIndex)) is out of range. Total holes: \(singleRoundViewModel.holes.count)")
            return nil
        }
        return singleRoundViewModel.holes[currentHoleIndex]
    }

    var body: some View {
        Group {
            if orientation.isLandscape {
                LandscapeScorecardView(navigateToInitialView: $navigateToInitialView)
                    .environmentObject(roundViewModel)
                    .environmentObject(singleRoundViewModel)
                    .environmentObject(authViewModel)
            } else {
                if holesLoaded {
                    portraitHoleContent
                } else {
                    ProgressView("Loading hole data...")
                }
            }
        }
        .onAppear {
            print("HoleView appeared")
            print("Round ID: \(roundViewModel.roundId ?? "nil")")
            print("Selected Course: \(roundViewModel.selectedCourse?.name ?? "nil")")
            print("Selected Tee: \(roundViewModel.selectedTee?.tee_name ?? "nil")")
            print("Number of golfers: \(roundViewModel.golfers.count)")
            print("Golfers: \(roundViewModel.golfers.map { $0.fullName })")
            
            if roundViewModel.roundId == nil {
                print("Warning: No round has been started yet!")
            }
            
            loadHoleData()
            initializeScores()
        }
           .onRotate { newOrientation in
               orientation = newOrientation
           }
           .navigationBarBackButtonHidden(true)
           .background(
               NavigationLink(destination: InititalView()
                   .environmentObject(authViewModel)
                   .environmentObject(roundViewModel),
               isActive: $navigateToInitialView) {
                   EmptyView()
               }
           )
       }
    

    private var portraitHoleContent: some View {
        VStack {
            // Navigation Arrows at the Top
            HStack {
                if currentHoleIndex > 0 {
                    Button(action: {
                        currentHoleIndex -= 1
                        updateScoresForCurrentHole()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Hole \(currentHoleIndex)")
                        }
                        .fontWeight(.bold)
                    }
                    .padding()
                }

                Spacer()

                if currentHoleIndex < singleRoundViewModel.holes.count - 1 {
                    Button(action: {
                        currentHoleIndex += 1
                        updateScoresForCurrentHole()
                    }) {
                        HStack {
                            Text("Hole \(currentHoleIndex + 2)")
                            Image(systemName: "arrow.right")
                        }
                        .fontWeight(.bold)
                    }
                    .padding()
                }
            }

            // Hole Details
            VStack {
                Text("Hole \(hole?.holeNumber ?? 0)")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(3)
                    .background(Color(.systemTeal).opacity(0.3))

                Text("\(hole?.yardage ?? 0) Yards")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)

                Text("Par \(hole?.par ?? 0)")
                    .font(.system(size: 19))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
                    .background(Color.gray.opacity(0.3))

                Text("Handicap \(hole?.handicap ?? 0)")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
            }
            .frame(width: UIScreen.main.bounds.width - 32)
            .padding(5)
            .border(Color.secondary)
            .cornerRadius(10)

            ScrollView {
                VStack {
                    // Scores for each golfer
                    HStack {
                        Text("Golfer")
                        Spacer()
                        Text("Score")
                    }
                    .frame(maxWidth: .infinity, maxHeight: 30)
                    .padding(.leading)
                    .padding(.trailing, 52)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)
                    .background(Color.secondary)

                    ForEach(roundViewModel.golfers, id: \.id) { golfer in
                        VStack {
                            HStack {
                                Text(golfer.fullName)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack {
                                    TextField("", text: Binding(
                                        get: { scoreInputs[golfer.id] ?? "" },
                                        set: { newValue in
                                            scoreInputs[golfer.id] = newValue
                                            updateScore(for: golfer.id, score: newValue)
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .focused($focusedGolferId, equals: golfer.id)
                                    .frame(width: 50, height: 50)
                                    .background(colorScheme == .dark ? Color.white : Color.gray.opacity(0.2))
                                    .foregroundColor(colorScheme == .dark ? .black : .primary)
                                    .cornerRadius(5)
                                    .multilineTextAlignment(.center)

                                    let isStrokeHole = roundViewModel.strokeHoles[golfer.id]?.contains(hole?.holeNumber ?? 0) ?? false
                                    if isStrokeHole {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 6, height: 6)
                                            .offset(x: -20, y: -17)
                                    }
                                    Text(isStrokeHole ? "Stroke" : "No Stroke")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()

                            if showMissingScores, let missingHoles = missingScores[golfer.id], !missingHoles.isEmpty {
                                Text("Golfer \(golfer.fullName) is missing scores for holes: \(missingHoles.map(String.init).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            Spacer()

            if hole?.holeNumber == 18 {
                Button("Check Scores") {
                    checkScores()
                }
                .padding()

                if showMissingScores && roundViewModel.allScoresEntered() {
                    NavigationLink(destination: ScorecardView()
                        .environmentObject(roundViewModel)
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(authViewModel)) {
                        Text("Review")
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                            .foregroundColor(.white)
                            .background(Color(.systemTeal))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    let threshold: CGFloat = 50
                    if gesture.translation.width > threshold && currentHoleIndex > 0 {
                        currentHoleIndex -= 1
                        updateScoresForCurrentHole()
                    } else if gesture.translation.width < -threshold && currentHoleIndex < singleRoundViewModel.holes.count - 1 {
                        currentHoleIndex += 1
                        updateScoresForCurrentHole()
                    }
                }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    if let golferId = focusedGolferId,
                       let golfer = roundViewModel.golfers.first(where: { $0.id == golferId }) {
                        let score = scoreInputs[golferId] ?? ""
                        updateScore(for: golferId, score: score)
                    }
                    focusedGolferId = nil
                }
            }
        }
    }

    private func loadHoleData() {
        print("loadHoleData called")
        guard let courseId = roundViewModel.selectedCourse?.id,
              let teeId = roundViewModel.selectedTee?.id else {
            print("Course or Tee not selected in RoundViewModel")
            return
        }
        
        print("Loading holes for Course ID: \(courseId), Tee ID: \(teeId)")
        singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { loadedHoles in
            self.holesLoaded = true
            print("Holes loaded in HoleView: \(loadedHoles.count)")
            print("Holes: \(loadedHoles.map { "Hole \($0.holeNumber): Par \($0.par)" }.joined(separator: ", "))")
        }
    }

    private func initializeScores() {
        updateScoresForCurrentHole()
    }

    private func updateScoresForCurrentHole() {
        let currentHoleNumber = currentHoleIndex + 1
        scoreInputs = roundViewModel.grossScores[currentHoleNumber]?.mapValues { String($0) } ?? [:]
        
        // Ensure all golfers have an entry in scoreInputs
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""
            }
        }

        print("Updated scores for Hole \(currentHoleNumber): \(scoreInputs)")
    }

    private func updateScore(for golferId: String, score: String) {
        let currentHoleNumber = currentHoleIndex + 1
        if let scoreInt = Int(score) {
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = scoreInt
            roundViewModel.updateNetScores()
            
            let netScore = roundViewModel.netScores[currentHoleNumber]?[golferId] ?? scoreInt
            let isStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
            
            print("Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.fullName ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Net Score: \(netScore), Stroke Hole: \(isStrokeHole)")
        } else {
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = nil
            roundViewModel.netScores[currentHoleNumber, default: [:]][golferId] = nil
        }
    }

    private func checkScores() {
        showMissingScores = true
        for golfer in roundViewModel.golfers {
            missingScores[golfer.id] = roundViewModel.getMissingScores(for: golfer.id)
        }
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        HoleView(teeId: "mockTeeId", holeNumber: 1)
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
            .environmentObject(SharedViewModel())
    }
}
