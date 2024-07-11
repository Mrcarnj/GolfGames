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
    @Published var scores: [Int: Int] = [:]  // Dictionary to hold scores keyed by hole number
    @Published var pars: [Int: Int] = [:]  // Dictionary to hold pars keyed by hole number
    @Published var playingHandicap: Int = 0
    @Published var strokeHoles: [Int] = []
    @Published var roundId: String?
    @Published var netScores: [Int: Int] = [:] // Dictionary to hold net scores keyed by hole number
    @Published var recentRounds: [Round] = []

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
                    self.roundId = document.documentID // Set roundId here
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

    func fetchPars(for courseId: String, teeId: String, user: User, completion: @escaping ([Int: Int]) -> Void) {
        let db = Firestore.firestore()
        let holesRef = db.collection("courses").document(courseId).collection("Tees").document(teeId).collection("Holes")

        print("Fetching pars for course: \(courseId), tee: \(teeId)")

        holesRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching hole data: \(error.localizedDescription)")
                completion([:])
                return
            }

            guard let documents = snapshot?.documents else {
                print("No hole documents found")
                completion([:])
                return
            }

            var pars = [Int: Int]()
            var holeHandicaps = [Int: Int]()
            for document in documents {
                if let holeNumber = document.data()["hole_number"] as? Int,
                   let par = document.data()["par"] as? Int,
                   let handicap = document.data()["handicap"] as? Int {
                    pars[holeNumber] = par
                    holeHandicaps[holeNumber] = handicap
                }
            }
            print("Fetched pars: \(pars)")
            completion(pars)

            // Calculate playing handicap and stroke holes
            if let slopeRating = self.selectedTee?.slope_rating,
               let courseRating = self.selectedTee?.course_rating,
               let coursePar = self.selectedTee?.course_par {
                self.playingHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: user.handicap ?? 0.0,
                    slopeRating: slopeRating,
                    courseRating: courseRating,
                    par: coursePar
                )
                let strokeHoles = holeHandicaps.sorted { $0.value < $1.value }.prefix(self.playingHandicap).map { $0.key }
                self.strokeHoles = strokeHoles
                print("Playing Handicap: \(self.playingHandicap), Stroke Holes: \(self.strokeHoles)")
                
                // Debug print statements
                for holeNumber in self.strokeHoles {
                    if let handicap = holeHandicaps[holeNumber] {
                        print("Hole \(holeNumber) with handicap \(handicap) gets a stroke")
                    }
                }
            }
        }
    }

    func updateNetScores() {
        netScores = scores.mapValues { score in
            let holeNumber = scores.first(where: { $0.value == score })?.key ?? 0
            return strokeHoles.contains(holeNumber) ? score - 1 : score
        }
        // Update the netScores dictionary correctly based on stroke holes
        for (holeNumber, score) in scores {
            netScores[holeNumber] = strokeHoles.contains(holeNumber) ? score - 1 : score
        }
    }
    
    func fetchRecentRounds(for user: User) {
            let db = Firestore.firestore()
            db.collection("users").document(user.id).collection("rounds")
                .order(by: "date", descending: true)
                .limit(to: 10)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching recent rounds: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        print("No recent rounds found")
                        return
                    }
                    self.recentRounds = documents.compactMap { try? $0.data(as: Round.self) }
                }
        }
}
