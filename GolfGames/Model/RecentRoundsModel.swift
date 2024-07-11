//
//  RecentRoundsModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RoundResult: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var course: String
    var date: String
    var total_score: Int
    var tees: String
    
    var uniqueID: String {
        return "\(date)-\(course)-\(total_score)-\(tees)"
    }
}

class RecentRoundsModel: ObservableObject {
    @Published var recentRounds: [RoundResult] = []

    func fetchRecentRounds(for user: User) {
            let db = Firestore.firestore()
            db.collection("users").document(user.id).collection("rounds")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching rounds: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        print("No rounds found")
                        return
                    }

                    var roundResults: [RoundResult] = []
                    let dispatchGroup = DispatchGroup()

                    for document in documents {
                        dispatchGroup.enter()
                        let roundId = document.documentID
                        db.collection("users").document(user.id).collection("rounds").document(roundId).collection("results").document("round_results")
                            .getDocument { snapshot, error in
                                if let error = error {
                                    print("Error fetching round result for round ID \(roundId): \(error.localizedDescription)")
                                } else if let snapshot = snapshot, snapshot.exists, let roundResult = try? snapshot.data(as: RoundResult.self) {
                                    print("Found round result for round ID: \(roundId)")
                                    print("Course: \(roundResult.course), Date: \(roundResult.date), Total Score: \(roundResult.total_score), Tees: \(roundResult.tees)")
                                    roundResults.append(roundResult)
                                }
                                dispatchGroup.leave()
                            }
                    }

                    dispatchGroup.notify(queue: .main) {
                        let uniqueRoundResults = Array(Set(roundResults))
                        let sortedRoundResults = uniqueRoundResults.sorted(by: { $0.date > $1.date })
                        self.recentRounds = Array(sortedRoundResults.prefix(10))
                        print("Final Recent Rounds: \(self.recentRounds.map { "\($0.course) \($0.date) \($0.total_score) \($0.tees)" })")
                    }
                }
        }
    }
