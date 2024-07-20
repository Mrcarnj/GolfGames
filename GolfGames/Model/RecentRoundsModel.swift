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
        let db = Firestore.firestore()
        let roundsRef = db.collection("users").document(user.id).collection("rounds")
        
        roundsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching rounds: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No rounds found")
                return
            }
            
            var roundResults: [RoundResult] = []
            
            let group = DispatchGroup()
            
            for document in documents {
                group.enter()
                let roundId = document.documentID
                let resultsRef = roundsRef.document(roundId).collection("results").document("round_results")
                
                resultsRef.getDocument { resultSnapshot, error in
                    defer { group.leave() }
                    if let error = error {
                        print("Error fetching round result: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = resultSnapshot?.data() else {
//                        print("No result data found for round ID: \(roundId)")
                        return
                    }
                    
                    if let course = data["course"] as? String,
                       let date = (data["date"] as? Timestamp)?.dateValue(),
                       let totalScore = data["total_score"] as? Int,
                       let tees = data["tees"] as? String,
                       let courseRating = data["course_rating"] as? Float,
                       let slopeRating = data["slope_rating"] as? Float {
                        
                        let roundResult = RoundResult(id: roundId, course: course, date: date, totalScore: totalScore, tees: tees, courseRating: courseRating, slopeRating: slopeRating)
                        roundResults.append(roundResult)
                        
                        print("Found round result for round ID: \(roundId)")
                        print("Course: \(course), Date: \(date), Total Score: \(totalScore), Tees: \(tees), Course Rating: \(courseRating), Slope Rating: \(slopeRating)")
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.recentRounds = roundResults.sorted(by: { $0.date > $1.date })
            }
        }
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
}
