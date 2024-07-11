//
//  RecentRoundsModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RoundResult: Identifiable, Hashable {
    var id: String
    var uniqueID: String { id }
    var date: Date
    var course: String
    var courseRating: Double
    var slopeRating: Double
    var total_score: Int
    var tees: String
}


class RecentRoundsModel: ObservableObject {
    @Published var recentRounds: [RoundResult] = []

    func fetchRecentRounds(for user: User) {
            let db = Firestore.firestore()
            db.collection("users").document(user.id).collection("rounds").getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching recent rounds: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                var roundResults: [RoundResult] = []

                let dispatchGroup = DispatchGroup()

                for document in documents {
                    dispatchGroup.enter()
                    let roundRef = document.reference
                    roundRef.collection("results").getDocuments { roundResultsSnapshot, error in
                        if let error = error {
                            print("Error fetching results for round \(document.documentID): \(error.localizedDescription)")
                            dispatchGroup.leave()
                            return
                        }

                        guard let roundResultsDocs = roundResultsSnapshot?.documents else {
                            print("No results found for round \(document.documentID)")
                            dispatchGroup.leave()
                            return
                        }

                        for roundResultDoc in roundResultsDocs {
                            if let roundResultData = roundResultDoc.data() as? [String: Any],
                               let course = roundResultData["course"] as? String,
                               let timestamp = roundResultData["date"] as? Timestamp,
                               let total_score = roundResultData["total_score"] as? Int,
                               let tees = roundResultData["tees"] as? String,
                               let courseRating = roundResultData["course_rating"] as? Double,
                               let slopeRating = roundResultData["slope_rating"] as? Double {
                                let date = timestamp.dateValue()
                                let roundResult = RoundResult(id: roundResultDoc.documentID, date: date, course: course, courseRating: courseRating, slopeRating: slopeRating, total_score: total_score, tees: tees)
                                roundResults.append(roundResult)
                                print("Found round result for round ID: \(document.documentID)")
                                print("Course: \(course), Date: \(date), Total Score: \(total_score), Tees: \(tees), Course Rating: \(courseRating), Slope Rating: \(slopeRating)")
                            }
                        }

                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    self.recentRounds = roundResults.sorted(by: { $0.date > $1.date })
                    print("Final Recent Rounds: \(self.recentRounds.map { "\($0.course) \($0.date) \($0.total_score) \($0.tees)" })")
                }
            }
        }
    }
