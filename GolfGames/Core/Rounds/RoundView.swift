//
//  RoundView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct RoundView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @State private var currentHoleNumber: Int = 1
    @State private var hole: Hole?
    @State private var showAlert = false
    @State private var missingHole: Int? = nil
    @State private var showScorecard = false
    @State private var isLandscape = false

    var roundId: String
    var selectedCourseId: String
    var selectedTeeId: String
    let totalHoles = 18

    var body: some View {
        VStack {
            if isLandscape {
                ScorecardView(showFinishButton: false)
                    .environmentObject(authViewModel)
                    .environmentObject(roundViewModel)
            } else {
                VStack {
                    if let hole = hole {
                        HoleView(
                            hole: hole,
                            onScoreChange: { golferId, newScore in
                                roundViewModel.scores[currentHoleNumber, default: [:]][golferId] = Int(newScore)
                            },
                            onNextHole: {
                                if allScoresEntered() {
                                    currentHoleNumber += 1
                                    fetchHoleData()
                                } else {
                                    showAlert = true
                                }
                            },
                            onPreviousHole: {
                                if currentHoleNumber > 1 {
                                    currentHoleNumber -= 1
                                    fetchHoleData()
                                }
                            },
                            currentHoleNumber: currentHoleNumber,
                            totalHoles: totalHoles
                        )
                    } else {
                        Text("Loading hole data...")
                            .font(.headline)
                            .padding()
                    }

                    if currentHoleNumber == totalHoles && !firstMissingScoreExists() {
                        Button(action: {
                            printScoresAndNetScores() // Print scores and net scores before showing the scorecard
                            showScorecard = true
                        }) {
                            Text("REVIEW")
                                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                                .foregroundColor(.white)
                                .background(Color(.systemTeal))
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 {
                                nextHole()
                            }
                            if value.translation.width > 50 {
                                previousHole()
                            }
                        }
                )
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    fetchHoleData()
                    print("Selected Course ID: \(selectedCourseId)")
                    print("Selected Tee ID: \(selectedTeeId)")

                    // Set the selected course in RoundViewModel
                    roundViewModel.selectedCourse = singleRoundViewModel.courses.first(where: { $0.id == selectedCourseId })
                    print("RoundViewModel Course ID: \(roundViewModel.selectedCourse?.id ?? "None")")

                    // Fetch and set the selected tee in RoundViewModel
                    singleRoundViewModel.fetchTees(for: roundViewModel.selectedCourse!) { tees in
                        roundViewModel.selectedTee = tees.first(where: { $0.id == selectedTeeId })
                        print("RoundViewModel Tee ID: \(roundViewModel.selectedTee?.id ?? "None")")

                        // Fetch pars for the selected tee
                        if let tee = roundViewModel.selectedTee, let user = authViewModel.currentUser {
                            roundViewModel.fetchPars(for: selectedCourseId, teeId: tee.id!, user: user) { pars in
                                roundViewModel.pars = pars
                                print("Fetched pars: \(pars)")
                            }
                        }
                    }
                }

                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("CAUTION - No Score Entered"),
                        message: Text("Please enter scores for all golfers before proceeding to the next hole."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .background(
                    NavigationLink(destination: ScorecardView(showFinishButton: true).environmentObject(roundViewModel), isActive: $showScorecard) {
                        EmptyView()
                    }
                )
            }
        }
        .onOrientationChange(isLandscape: $isLandscape)
    }

    func fetchHoleData() {
        guard let currentUser = authViewModel.currentUser else { return }

        let db = Firestore.firestore()
        let holeRef = db.collection("courses").document(selectedCourseId).collection("Tees").document(selectedTeeId).collection("Holes").whereField("hole_number", isEqualTo: currentHoleNumber)

        holeRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching hole data: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                print("No documents found for hole \(currentHoleNumber)")
                return
            }

            let document = snapshot.documents.first
            do {
                self.hole = try document?.data(as: Hole.self)
                print("Fetched hole data: \(String(describing: self.hole))")
            } catch {
                print("Error decoding hole data: \(error.localizedDescription)")
            }
        }
    }


    func allScoresEntered() -> Bool {
        for golfer in roundViewModel.golfers {
            if roundViewModel.scores[currentHoleNumber]?[golfer.id] == nil {
                return false
            }
        }
        return true
    }

    func firstMissingScoreExists() -> Bool {
        for hole in 1...totalHoles {
            if roundViewModel.scores[hole] == nil {
                return true
            }
        }
        return false
    }

    private func nextHole() {
        if allScoresEntered() {
            if currentHoleNumber < totalHoles {
                currentHoleNumber += 1
                fetchHoleData()
            }
        } else {
            showAlert = true
        }
    }

    private func previousHole() {
        if currentHoleNumber > 1 {
            currentHoleNumber -= 1
            fetchHoleData()
        }
    }
    
    private func printScoresAndNetScores() {
        print("Scores:")
        for (holeNumber, scoresDict) in roundViewModel.scores {
            for (golferId, score) in scoresDict {
                print("Hole \(holeNumber), Golfer \(golferId): Score \(score)")
            }
        }

        print("Net Scores:")
        for (holeNumber, netScoresDict) in roundViewModel.netScores {
            for (golferId, netScore) in netScoresDict {
                print("Hole \(holeNumber), Golfer \(golferId): Net Score \(netScore)")
            }
        }
    }
}
