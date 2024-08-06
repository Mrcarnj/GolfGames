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
                let data = document.data()
                
                // Check if roundResultID exists in the document
                guard let roundResultID = data["roundResultID"] as? String else {
                   // print("No roundResultID found for document: \(document.documentID)")
                    group.leave()
                    continue
                }
                
                // Use the data directly from the round document
                if let course = data["courseName"] as? String,
                   let date = (data["date"] as? Timestamp)?.dateValue(),
                   let tees = data["tees"] as? String,
                   let courseRating = data["courseRating"] as? Float,
                   let slopeRating = data["slopeRating"] as? Float,
                   let golfers = data["golfers"] as? [[String: Any]] {
                    
                    // Assuming the first golfer in the array is the main player
                    if let firstGolfer = golfers.first,
                       let totalScore = firstGolfer["grossTotal"] as? Int {
                        
                        let roundResult = RoundResult(
                            id: document.documentID,
                            course: course,
                            date: date,
                            totalScore: totalScore,
                            tees: tees,
                            courseRating: courseRating,
                            slopeRating: slopeRating
                        )
                        roundResults.append(roundResult)
                        
                        print("Found round result for round ID: \(document.documentID)")
                        print("Course: \(course), Date: \(date), Total Score: \(totalScore), Tees: \(tees), Course Rating: \(courseRating), Slope Rating: \(slopeRating)")
                    }
                }
                
                group.leave()
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
