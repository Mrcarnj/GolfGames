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
                            onScoreChange: { newScore, golferId in
                                roundViewModel.scores[currentHoleNumber, default: [:]][golferId] = Int(newScore)
                            },
                            onNextHole: {
                                if roundViewModel.scores[currentHoleNumber] == nil {
                                    missingHole = currentHoleNumber
                                    showAlert = true
                                } else if currentHoleNumber < totalHoles {
                                    currentHoleNumber += 1
                                    fetchHoleData()
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
                        message: Text("You haven't entered a score for hole \(missingHole!)."),
                        primaryButton: .default(Text("Enter Score"), action: {
                            // Close the alert and stay on the current hole
                            showAlert = false
                        }),
                        secondaryButton: .destructive(Text("Continue"), action: {
                            // Continue to the next hole
                            currentHoleNumber += 1
                            fetchHoleData()
                        })
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

    func firstMissingScoreExists() -> Bool {
        for hole in 1...totalHoles {
            if roundViewModel.scores[hole] == nil {
                return true
            }
        }
        return false
    }

    private func nextHole() {
        if roundViewModel.scores[currentHoleNumber] == nil {
            missingHole = currentHoleNumber
            showAlert = true
        } else if currentHoleNumber < totalHoles {
            currentHoleNumber += 1
            fetchHoleData()
        }
    }

    private func previousHole() {
        if currentHoleNumber > 1 {
            currentHoleNumber -= 1
            fetchHoleData()
        }
    }
}
