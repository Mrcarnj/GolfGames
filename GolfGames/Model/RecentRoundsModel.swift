//
//  RecentRoundsModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation
import FirebaseFirestore

class RecentRoundsModel: ObservableObject {
    @Published var recentRounds: [RoundResult] = []
    
    func fetchRecentRounds(for user: User) {
        print("DEBUG: Fetching recent rounds for user ID: \(user.id)")
        let db = Firestore.firestore()
        let roundsRef = db.collection("users").document(user.id).collection("rounds")
        
        roundsRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching rounds: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot, !snapshot.isEmpty {
                print("DEBUG: Found \(snapshot.documents.count) rounds")
                self?.processRoundsSnapshot(snapshot)
            } else {
                print("DEBUG: No rounds found for user ID: \(user.id)")
                // Rounds collection doesn't exist, try to find the user by email
                self?.findUserByEmailAndFetchRounds(email: user.email)
            }
        }
    }

    private func processRoundsSnapshot(_ snapshot: QuerySnapshot) {
        var roundResults: [RoundResult] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            if let course = data["courseName"] as? String,
               let date = (data["date"] as? Timestamp)?.dateValue(),
               let tees = data["tees"] as? String,
               let courseRating = data["courseRating"] as? Float,
               let slopeRating = data["slopeRating"] as? Float,
               let golfers = data["golfers"] as? [[String: Any]] {
                
                // Assuming the first golfer in the array is the main player
                if let firstGolfer = golfers.first,
                   let totalScore = firstGolfer["grossTotal"] as? Int {
                    
                    let scoreDifferential = self.calculateScoreDifferential(totalScore: totalScore, courseRating: courseRating, slopeRating: slopeRating)
                    
                    let roundResult = RoundResult(
                        id: document.documentID,
                        course: course,
                        date: date,
                        totalScore: totalScore,
                        tees: tees,
                        courseRating: courseRating,
                        slopeRating: slopeRating,
                        scoreDifferential: scoreDifferential
                    )
                    roundResults.append(roundResult)
                    
                    print("DEBUG: Processed round: \(course) on \(date)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.recentRounds = roundResults.sorted(by: { $0.date > $1.date })
            print("DEBUG: Updated recentRounds with \(self.recentRounds.count) rounds")
        }
    }

    private func findUserByEmailAndFetchRounds(email: String) {
        print("DEBUG: Attempting to find user by email: \(email)")
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] (snapshot, error) in
            if let document = snapshot?.documents.first {
                let userId = document.documentID
                print("DEBUG: Found user with ID: \(userId)")
                
                // Now fetch rounds using this userId
                db.collection("users").document(userId).collection("rounds").getDocuments { [weak self] (roundsSnapshot, roundsError) in
                    if let roundsSnapshot = roundsSnapshot {
                        print("DEBUG: Found \(roundsSnapshot.documents.count) rounds for user")
                        self?.processRoundsSnapshot(roundsSnapshot)
                    } else if let error = roundsError {
                        print("DEBUG: Error fetching rounds: \(error.localizedDescription)")
                    }
                }
            } else {
                print("DEBUG: No user found with email: \(email)")
            }
        }
    }

    private func calculateScoreDifferential(totalScore: Int, courseRating: Float, slopeRating: Float) -> Float {
        let differential = (113 / slopeRating) * (Float(totalScore) - courseRating)
        return (differential * 10).rounded() / 10
    }
}

struct RoundResult: Identifiable {
    var id: String
    var course: String
    var date: Date
    var totalScore: Int
    var tees: String
    var courseRating: Float
    var slopeRating: Float
    var scoreDifferential: Float
}
