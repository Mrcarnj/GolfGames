//
//  TeeSelectionView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/24/24.
//

import SwiftUI

struct TeeSelectionView: View {
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @State private var navigateToRoundView = false
    @State private var currentHoleIndex = 0
    @State private var showGameSelection = false
    @State private var selectedRoundType: RoundType = .full18

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
                Text("Course Handicap reflects off 18 holes. When the round begins, turn horizontal to see stroke holes for 18 or 9 holes, whichever was selected.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 10))
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                    .padding(.horizontal)
            List {
                ForEach($sharedViewModel.golfers) { $golfer in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(golfer.fullName)
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
                                Text(formatHandicap(Float(courseHandicap)))
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
                                  //  print("\(golfer.fullName) selected \(tee.tee_name)")
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
                    showGameSelection = true
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
                .environmentObject(singleRoundViewModel),
                isActive: $navigateToRoundView
            ) {
                EmptyView()
            }
        }
        .sheet(isPresented: $showGameSelection) {
            GameSelectionView(onBeginRound: beginRound)
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
        }
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
    
    private func beginRound() {
        // Update RoundViewModel with the latest golfer information
        roundViewModel.golfers = sharedViewModel.golfers
        roundViewModel.selectedCourse = sharedViewModel.selectedCourse
        roundViewModel.isMatchPlay = sharedViewModel.isMatchPlay
        
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
                roundViewModel.golfers[index].courseHandicap = courseHandicap // Changed from playingHandicap to courseHandicap
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
        roundViewModel.initializeBetterBallAfterHandicapsSet()
        loadHolesData()
    }

    private func formatHandicap(_ handicap: Float) -> String {
        if handicap < 0 {
            return String(format: "+%.1f", abs(handicap))
        } else {
            return String(format: "%.1f", handicap)
        }
    }
}

struct TeeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGolfer = Golfer(id: UUID().uuidString, fullName: "Mock Golfer", handicap: 10.0)
        let mockCourse = Course(id: "courseId", name: "Mock Course", location: "Mock Location")

        return TeeSelectionView()
            .environmentObject(SharedViewModel())
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
    }
}
