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
    @State private var currentHoleNumber: Int = 1
    @State private var hole: Hole?
    @State private var scores: [Int: String] = [:]

    var roundId: String
    var selectedCourseId: String
    var selectedTeeId: String
    let totalHoles = 18

    var body: some View {
        VStack {
            if let hole = hole {
                HoleView(
                    hole: hole,
                    score: scores[currentHoleNumber] ?? "",
                    onScoreChange: { newScore in
                        scores[currentHoleNumber] = newScore
                    },
                    onNextHole: {
                        currentHoleNumber += 1
                        fetchHoleData()
                    },
                    onPreviousHole: {
                        currentHoleNumber -= 1
                        fetchHoleData()
                    },
                    currentHoleNumber: currentHoleNumber,
                    totalHoles: totalHoles
                )
            } else {
                Text("Loading hole data...")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchHoleData()
        }
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
}

struct RoundView_Previews: PreviewProvider {
    static var previews: some View {
        RoundView(roundId: "mockRoundId", selectedCourseId: "courseId", selectedTeeId: "teeId")
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
