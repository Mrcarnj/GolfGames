//
//  TeeSelectionView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/24/24.
//

import SwiftUI

struct SelectedGames {
    var isMatchPlay: Bool = false
    var isBetterBall: Bool = false
    var isNinePoint: Bool = false
    var isStablefordGross: Bool = false
    var isStablefordNet: Bool = false
    var isBlindDrawBetterBall: Bool = false
    var matchPlayGolfers: [Golfer] = []
    var betterBallTeams: [String: String] = [:]
    var blindDrawScoresToUse: Int = 1
    var blindDrawBetterBallTeams: [String: String] = [:]
}

struct TeeSelectionView: View {
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @State private var navigateToRoundView = false
    @State private var currentHoleIndex = 0
    @State private var showGameSelection = false
    @State private var selectedRoundType: RoundType = .full18
    @State private var selectedStartingHole: Int = 1
    @State private var selectedGames = SelectedGames()
    @State private var isGameSelectionPresented = false

    var allTeesSelected: Bool {
        sharedViewModel.golfers.allSatisfy { golfer in
            sharedViewModel.golferTeeSelections[golfer.id] != nil
        }
    }

    var body: some View {
        VStack {
            Picker("Round Type", selection: $selectedRoundType) {
                Text("18 Holes").tag(RoundType.full18)
                Text("Front 9").tag(RoundType.front9)
                Text("Back 9").tag(RoundType.back9)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            HStack {
                Text("Starting Hole:")
                    .font(.headline)
                Picker("", selection: $selectedStartingHole) {
                    ForEach(availableStartingHoles, id: \.self) { hole in
                        Text("Hole \(hole)").tag(hole)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            List {
                ForEach($sharedViewModel.golfers) { $golfer in
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(golfer.firstName) \(String(golfer.lastName.prefix(1))).")
                                .font(.headline)
                            Spacer ()
                            Text("HCP:")
                                .font(.headline)
                                .fontWeight(.regular)
                            Text(formatHandicap(golfer.handicap))
                                .font(.headline)
                            if let courseHandicap = sharedViewModel.courseHandicaps[golfer.id] {
                                Text(" CH:")
                                    .font(.headline)
                                    .fontWeight(.regular)
                                Text("\(courseHandicap)")
                                    .font(.headline)
                            }
                        }

                        TeePickerView(
                            selectedTee: Binding(
                                get: {
                                    if let teeId = sharedViewModel.golferTeeSelections[golfer.id],
                                       let tee = singleRoundViewModel.tees.first(where: { $0.id == teeId }) {
                                        return tee
                                    }
                                    return nil
                                },
                                set: { newValue in
                                    guard let tee = newValue else { return }
                                    DispatchQueue.main.async {
                                        sharedViewModel.golferTeeSelections[golfer.id] = tee.id
                                        let courseHandicap = HandicapCalculator.calculateCourseHandicap(
                                            handicapIndex: golfer.handicap,
                                            slopeRating: tee.slope_rating,
                                            courseRating: tee.course_rating,
                                            par: tee.course_par
                                        )
                                        sharedViewModel.courseHandicaps[golfer.id] = courseHandicap
                                        
                                        // Update the golfer's tee and courseHandicap
                                        if let index = sharedViewModel.golfers.firstIndex(where: { $0.id == golfer.id }) {
                                            sharedViewModel.golfers[index].tee = tee
                                            sharedViewModel.golfers[index].courseHandicap = courseHandicap
                                        }
                                    }
                                }
                            ),
                            courseHandicap: Binding(
                                get: { sharedViewModel.courseHandicaps[golfer.id] ?? 0 },
                                set: { newValue in
                                    sharedViewModel.courseHandicaps[golfer.id] = newValue
                                }
                            ),
                            currentGolfer: $golfer
                        )
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(sharedViewModel)
                    }
                }
            }

            if sharedViewModel.golfers.count > 1 {
                Button(action: {
                    isGameSelectionPresented = true
                }) {
                    Text("Add Games")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBlue))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.horizontal)
            }

            Button(action: {
                beginRound()
                let updatedNamedAssignments = roundViewModel.blindDrawBetterBallTeamAssignments.mapValues { teamName in
                    let teamMembers = roundViewModel.golfers
                        .filter { roundViewModel.blindDrawBetterBallTeamAssignments[$0.id] == teamName }
                        .map { "\($0.firstName) \($0.lastName)" }
                        .joined(separator: ", ")
                    return "\(teamName): \(teamMembers)"
                }
                print("Debug: TeeSelectionView - Blind Draw teams after setting: \(updatedNamedAssignments)")
            }) {
                Text("Begin Round")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemTeal))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .padding(.horizontal)
            .disabled(!allTeesSelected)

            NavigationLink(
                destination: HoleView(
                    teeId: roundViewModel.selectedTee?.id ?? "",
                    holeNumber: roundViewModel.getStartingHoleNumber(),
                    roundType: roundViewModel.roundType
                )
                .environmentObject(authViewModel)
                .environmentObject(roundViewModel)
                .environmentObject(sharedViewModel)
                .environmentObject(singleRoundViewModel)
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true),
                isActive: $navigateToRoundView
            ) {
                EmptyView()
            }
            .isDetailLink(false)
        }
        .sheet(isPresented: $isGameSelectionPresented) {
            GameSelectionView(isPresented: $isGameSelectionPresented, selectedGames: $selectedGames)
                .environmentObject(sharedViewModel)
                .environmentObject(roundViewModel)
                .environmentObject(authViewModel)
        }
        .onAppear {
            setDefaultTees()
           // print("Default tees set: \(sharedViewModel.golfers.map { "\($0.fullName) (Tee: \($0.tee?.tee_name ?? "N/A"), CH: \($0.playingHandicap ?? 0))" })")
        }
        .onChange(of: selectedRoundType) { newValue in
            roundViewModel.roundType = newValue
            updateDefaultStartingHole(for: newValue)
        }
    }

    private var availableStartingHoles: [Int] {
        switch selectedRoundType {
        case .full18:
            return Array(1...18)
        case .front9:
            return Array(1...9)
        case .back9:
            return Array(10...18)
        }
    }
    
    private func updateDefaultStartingHole(for roundType: RoundType) {
        switch roundType {
        case .full18, .front9:
            selectedStartingHole = 1
        case .back9:
            selectedStartingHole = 10
        }
    }
    
    private func beginRound() {
        // Update RoundViewModel with the selected game types
        roundViewModel.isMatchPlay = selectedGames.isMatchPlay
        roundViewModel.isBetterBall = selectedGames.isBetterBall
        roundViewModel.isNinePoint = selectedGames.isNinePoint
        roundViewModel.isStablefordGross = selectedGames.isStablefordGross
        roundViewModel.isStablefordNet = selectedGames.isStablefordNet
        
        // Set up Match Play if selected
        if selectedGames.isMatchPlay && selectedGames.matchPlayGolfers.count == 2 {
            roundViewModel.setMatchPlayGolfers(golfer1: selectedGames.matchPlayGolfers[0], golfer2: selectedGames.matchPlayGolfers[1])
        }
        
        // Set up Better Ball if selected
        if selectedGames.isBetterBall {
            let validAssignments = selectedGames.betterBallTeams.filter { $0.value != "Not Playing" }
            roundViewModel.setBetterBallTeams(validAssignments)
        }
        
        // Set up Blind Draw Better Ball if selected
        if selectedGames.isBlindDrawBetterBall {
            let validAssignments = selectedGames.blindDrawBetterBallTeams.filter { $0.value != "Not Playing" }
            roundViewModel.setBlindDrawBetterBallTeams(validAssignments)
            roundViewModel.blindDrawScoresToUse = selectedGames.blindDrawScoresToUse
        }
        
        // Set up Nine Point if selected
        if selectedGames.isNinePoint {
            roundViewModel.initializeNinePoint()
        }
        
        // Set up Stableford Gross if selected
        if selectedGames.isStablefordGross {
            roundViewModel.initializeStablefordGross(quotas: calculateStablefordGrossQuotas())
        }
        
        // Set up Stableford Net if selected
        if selectedGames.isStablefordNet {
            roundViewModel.initializeStablefordNet(quotas: calculateStablefordNetQuotas())
        }
        
        // Update RoundViewModel with the latest golfer information
        roundViewModel.golfers = sharedViewModel.golfers
        roundViewModel.selectedCourse = sharedViewModel.selectedCourse
        roundViewModel.isMatchPlay = sharedViewModel.isMatchPlay
        roundViewModel.isNinePoint = roundViewModel.isNinePoint // Make sure this is set
        roundViewModel.isBlindDrawBetterBall = selectedGames.isBlindDrawBetterBall
        roundViewModel.blindDrawScoresToUse = selectedGames.blindDrawScoresToUse
        roundViewModel.startingHole = selectedStartingHole
        
        // Ensure all golfers have course handicaps and tees set
        for (index, golfer) in roundViewModel.golfers.enumerated() {
            if let teeId = sharedViewModel.golferTeeSelections[golfer.id],
               let tee = singleRoundViewModel.tees.first(where: { $0.id == teeId }) {
                let courseHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: golfer.handicap,
                    slopeRating: tee.slope_rating,
                    courseRating: tee.course_rating,
                    par: tee.course_par
                )
                roundViewModel.golfers[index].tee = tee
                roundViewModel.golfers[index].courseHandicap = courseHandicap
                roundViewModel.courseHandicaps[golfer.id] = courseHandicap
                
                print("Debug TeeSelectionView: Set course handicap for \(golfer.fullName): \(courseHandicap)")
            } else {
                print("Warning: No tee selected for golfer \(golfer.fullName)")
            }
        }
        
        if let firstGolfer = roundViewModel.golfers.first,
           let firstGolferTee = firstGolfer.tee {
            roundViewModel.selectedTee = firstGolferTee
        }
        
        // Calculate stroke holes for all game types
        loadHolesData()
    }

    private func loadHolesData() {
        guard let courseId = sharedViewModel.selectedCourse?.id else { return }
        
        let group = DispatchGroup()
        
        for golfer in roundViewModel.golfers {
            if let teeId = sharedViewModel.golferTeeSelections[golfer.id] {
                group.enter()
                singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { holes in
                    DispatchQueue.main.async {
                        self.roundViewModel.holes[teeId] = holes
                        print("Loaded \(holes.count) holes for golfer \(golfer.fullName), tee ID: \(teeId)")
                    }
                    group.leave()
                }
            } else {
                print("Warning: No tee selected for golfer \(golfer.fullName)")
            }
        }
        
        group.notify(queue: .main) {
            self.calculateHandicapsAndStrokeHoles()
            self.createRound()
        }
    }

    private func calculateHandicapsAndStrokeHoles() {
        for golfer in roundViewModel.golfers {
            if let tee = golfer.tee,
               let teeId = tee.id,
               let courseHandicap = roundViewModel.courseHandicaps[golfer.id],
               let holes = roundViewModel.holes[teeId] {
                let strokeHoles = HandicapCalculator.determineStrokePlayStrokeHoles(courseHandicap: courseHandicap, holes: holes)
                roundViewModel.strokeHoles[golfer.id] = strokeHoles
                print("Calculated stroke holes for \(golfer.fullName): \(strokeHoles)")
            } else {
                print("Warning: Missing data for calculating stroke holes for \(golfer.fullName)")
            }
        }
        
        print("Stroke play stroke holes after calculation: \(roundViewModel.strokeHoles)")
        
        if sharedViewModel.isMatchPlay {
            StrokesModel.calculateGameStrokeHoles(roundViewModel: roundViewModel, golfers: roundViewModel.golfers)
        }
        
        if roundViewModel.isNinePoint {
            StrokesModel.calculateNinePointStrokeHoles(roundViewModel: roundViewModel)
        }
        
        roundViewModel.initializeBetterBallAfterHandicapsSet()
        roundViewModel.initializeBlindDrawBetterBallAfterHandicapsSet()
    }

    private func createRound() {
        if let user = authViewModel.currentUser {
            roundViewModel.beginRound(
                for: user,
                additionalGolfers: Array(roundViewModel.golfers.dropFirst()),
                isMatchPlay: sharedViewModel.isMatchPlay
            ) { roundId, error, additionalInfo in
                if let roundId = roundId {
                    print("Round created with ID: \(roundId)")
                    if let courseId = additionalInfo?["courseId"] as? String,
                       let teeId = additionalInfo?["teeId"] as? String {
                        print("Course ID: \(courseId), Tee ID: \(teeId)")
                    }
                    self.navigateToRoundView = true
                } else if let error = error {
                    print("Failed to create round: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setDefaultTees() {
        guard let firstTee = singleRoundViewModel.tees.first else { return }
        for golfer in sharedViewModel.golfers {
            if sharedViewModel.golferTeeSelections[golfer.id] == nil {
                sharedViewModel.golferTeeSelections[golfer.id] = firstTee.id
                let courseHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: golfer.handicap,
                    slopeRating: firstTee.slope_rating,
                    courseRating: firstTee.course_rating,
                    par: firstTee.course_par
                )
                sharedViewModel.courseHandicaps[golfer.id] = courseHandicap
                
                // Update the golfer's tee and courseHandicap in the sharedViewModel
                if let index = sharedViewModel.golfers.firstIndex(where: { $0.id == golfer.id }) {
                    sharedViewModel.golfers[index].tee = firstTee
                    sharedViewModel.golfers[index].courseHandicap = courseHandicap
                }
            }
        }
        // Force a UI update
        sharedViewModel.objectWillChange.send()
    }
    
    private func formatHandicap(_ handicap: Float) -> String {
        if handicap < 0 {
            return String(format: "+%.1f", abs(handicap))
        } else {
            return String(format: "%.1f", handicap)
        }
    }

    private func calculateStablefordGrossQuotas() -> [String: Int] {
        var quotas: [String: Int] = [:]
        for golfer in sharedViewModel.golfers {
            if let courseHandicap = sharedViewModel.courseHandicaps[golfer.id] {
                quotas[golfer.id] = 36 - courseHandicap
            }
        }
        return quotas
    }

    private func calculateStablefordNetQuotas() -> [String: Int] {
        var quotas: [String: Int] = [:]
        for golfer in sharedViewModel.golfers {
            if let courseHandicap = sharedViewModel.courseHandicaps[golfer.id] {
                quotas[golfer.id] = 36 - courseHandicap
            }
        }
        return quotas
    }
}

struct TeeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGolfer = Golfer(id: UUID().uuidString, firstName: "Mock", lastName: "Golfer", handicap: 10.0)
        let mockCourse = Course(id: "courseId", name: "Mock Course", location: "Mock Location")

        return TeeSelectionView()
            .environmentObject(SharedViewModel())
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
    }
}
