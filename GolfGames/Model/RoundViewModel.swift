//
//  RoundView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class RoundViewModel: ObservableObject {
    @Published var selectedTee: Tee?
    @Published var selectedCourse: Course?
    @Published var selectedLocation: String?

    func beginRound(for user: User, completion: @escaping (String?, String?, String?) -> Void) {
        guard let course = selectedCourse,
              let tee = selectedTee,
              let courseId = course.id,
              let teeId = tee.id else {
            print("Missing required data to begin round")
            completion(nil, nil, nil)
            return
        }

        let golfer = Round.Golfer(id: user.id, name: user.fullname, handicap: user.handicap ?? 0.0)

        let round = Round(
            courseId: courseId,
            courseName: course.name,
            teeName: tee.tee_name,
            golfers: [golfer],
            date: Date()
        )

        do {
            let db = Firestore.firestore()
            let roundsRef = db.collection("users").document(user.id).collection("rounds")
            let roundRef = try roundsRef.addDocument(from: round)

            roundRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    print("Round saved with ID: \(document.documentID)")
                    completion(document.documentID, courseId, teeId)
                } else {
                    print("Error saving round: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil, nil, nil)
                }
            }
        } catch {
            print("Error saving round: \(error.localizedDescription)")
            completion(nil, nil, nil)
        }
    }
}
