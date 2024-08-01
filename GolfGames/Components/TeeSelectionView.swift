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

    var allTeesSelected: Bool {
        sharedViewModel.golfers.allSatisfy { golfer in
            sharedViewModel.golferTeeSelections[golfer.id] != nil
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach($sharedViewModel.golfers) { $golfer in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(golfer.fullName)
                                .font(.headline)
                            Text("HCP: \(String(format: "%.1f", golfer.handicap))")
                                .font(.headline)
                            if let playingHandicap = sharedViewModel.playingHandicaps[golfer.id] {
                                Text("CH: \(playingHandicap)")
                                    .font(.headline)
                                    .fontWeight(.regular)
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
                                        sharedViewModel.playingHandicaps[golfer.id] = courseHandicap
                                        
                                        // Update the golfer's tee and playingHandicap
                                        if let index = sharedViewModel.golfers.firstIndex(where: { $0.id == golfer.id }) {
                                            sharedViewModel.golfers[index].tee = tee
                                            sharedViewModel.golfers[index].playingHandicap = courseHandicap
                                        }
                                    }
                                  //  print("\(golfer.fullName) selected \(tee.tee_name)")
                                }
                            ),
                            playingHandicap: Binding(
                                get: { sharedViewModel.playingHandicaps[golfer.id] ?? 0 },
                                set: { newValue in
                                    sharedViewModel.playingHandicaps[golfer.id] = newValue
                                }
                            ),
                            currentGolfer: $golfer
                        )
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(sharedViewModel)
                    }
                }
            }

            Button(action: {
                // Ensure all golfers have tees and playing handicaps set
                for (index, golfer) in sharedViewModel.golfers.enumerated() {
                    if golfer.tee == nil || golfer.playingHandicap == nil {
                        if let teeId = sharedViewModel.golferTeeSelections[golfer.id],
                           let tee = singleRoundViewModel.tees.first(where: { $0.id == teeId }) {
                            let courseHandicap = HandicapCalculator.calculateCourseHandicap(
                                handicapIndex: golfer.handicap,
                                slopeRating: tee.slope_rating,
                                courseRating: tee.course_rating,
                                par: tee.course_par
                            )
                            sharedViewModel.golfers[index].tee = tee
                            sharedViewModel.golfers[index].playingHandicap = courseHandicap
                        }
                    }
                }
                
                // Set the selected course and tee in roundViewModel
                roundViewModel.selectedCourse = sharedViewModel.selectedCourse
                if let firstGolfer = sharedViewModel.golfers.first,
                   let firstGolferTeeId = sharedViewModel.golferTeeSelections[firstGolfer.id],
                   let firstGolferTee = singleRoundViewModel.tees.first(where: { $0.id == firstGolferTeeId }) {
                    roundViewModel.selectedTee = firstGolferTee
                }
                
                // Initialize roundViewModel with selected golfers
                roundViewModel.golfers = sharedViewModel.golfers
                print("Initializing roundViewModel with golfers: \(roundViewModel.golfers.map { "\($0.fullName) (Tee: \($0.tee?.tee_name ?? "N/A"), CH: \($0.playingHandicap ?? 0))" })")
                loadHolesData()
            }) {
                Text("Begin Round")
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .foregroundColor(.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
            }
            .padding(.top)
            .disabled(!allTeesSelected)

            NavigationLink(
                destination: HoleView(
                    teeId: roundViewModel.selectedTee?.id ?? "",
                    holeNumber: 1
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
        .onAppear {
            setDefaultTees()
           // print("Default tees set: \(sharedViewModel.golfers.map { "\($0.fullName) (Tee: \($0.tee?.tee_name ?? "N/A"), CH: \($0.playingHandicap ?? 0))" })")
        }
    }

    private func loadHolesData() {
        guard let courseId = sharedViewModel.selectedCourse?.id else { return }
        
        let group = DispatchGroup()
        for (_, teeId) in sharedViewModel.golferTeeSelections {
            group.enter()
            singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { loadedHoles in
                // Store the loaded holes in roundViewModel
                roundViewModel.holes[teeId] = loadedHoles
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            calculateHandicapsAndStrokeHoles()
            
            // Set the selected course and tee in roundViewModel
            roundViewModel.selectedCourse = sharedViewModel.selectedCourse
            if let firstGolfer = sharedViewModel.golfers.first,
               let firstGolferTeeId = sharedViewModel.golferTeeSelections[firstGolfer.id],
               let firstGolferTee = singleRoundViewModel.tees.first(where: { $0.id == firstGolferTeeId }) {
                roundViewModel.selectedTee = firstGolferTee
            }
            
            // Start the round in roundViewModel
            roundViewModel.beginRound(
                for: authViewModel.currentUser!,
                additionalGolfers: sharedViewModel.golfers.filter { $0.id != authViewModel.currentUser?.id }
            ) { roundId, _, _ in
                if roundId != nil {
                    self.navigateToRoundView = true
                } else {
                    // Handle error
                    print("Failed to start round")
                }
            }
        }
    }

    private func calculateHandicapsAndStrokeHoles() {
        // Calculate course handicaps
        for golfer in roundViewModel.golfers {
            if let tee = golfer.tee {
                let courseHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: golfer.handicap,
                    slopeRating: tee.slope_rating,
                    courseRating: tee.course_rating,
                    par: tee.course_par
                )
                roundViewModel.courseHandicaps[golfer.id] = courseHandicap
             //   print("Calculated course handicap for \(golfer.fullName): \(courseHandicap)")
            } else {
              //  print("Warning: No tee selected for golfer \(golfer.fullName)")
            }
        }

        // Calculate stroke holes
        for golfer in roundViewModel.golfers {
            guard let courseHandicap = roundViewModel.courseHandicaps[golfer.id] else {
                print("Warning: No course handicap found for golfer \(golfer.fullName)")
                continue
            }
            let strokeHoles = HandicapCalculator.determineStrokeHoles(courseHandicap: courseHandicap, holes: singleRoundViewModel.holes)
            roundViewModel.strokeHoles[golfer.id] = strokeHoles
            
//            print("Calculated stroke holes for \(golfer.fullName): \(strokeHoles)")
        }

//        print("Course handicaps after calculation: \(roundViewModel.courseHandicaps)")
//        print("Stroke holes after calculation: \(roundViewModel.strokeHoles)")
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
                sharedViewModel.playingHandicaps[golfer.id] = courseHandicap
                
                // Update the golfer's tee and playingHandicap in the sharedViewModel
                if let index = sharedViewModel.golfers.firstIndex(where: { $0.id == golfer.id }) {
                    sharedViewModel.golfers[index].tee = firstTee
                    sharedViewModel.golfers[index].playingHandicap = courseHandicap
                }
            }
        }
        // Force a UI update
        sharedViewModel.objectWillChange.send()
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
