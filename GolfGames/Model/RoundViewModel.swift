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
    @Published var scores: [Int: [String: Int]] = [:]  // Nested dictionary to hold scores keyed by hole number and golfer ID
    @Published var pars: [Int: Int] = [:]  // Dictionary to hold pars keyed by hole number
    @Published var playingHandicaps: [String: Int] = [:]  // Dictionary to hold playing handicaps keyed by golfer ID
    @Published var strokeHoles: [String: [Int]] = [:]  // Dictionary to hold stroke holes keyed by golfer ID
    @Published var roundId: String?
    @Published var netScores: [Int: [String: Int]] = [:] // Nested dictionary to hold net scores keyed by hole number and golfer ID
    @Published var recentRounds: [Round] = []
    @Published var golfers: [Golfer] = []

    func beginRound(for user: User, additionalGolfers: [Golfer], completion: @escaping (String?, String?, String?) -> Void) {
        guard let course = selectedCourse,
              let tee = selectedTee,
              let courseId = course.id,
              let teeId = tee.id else {
            print("Missing required data to begin round")
            completion(nil, nil, nil)
            return
        }

        self.golfers = [Golfer(id: user.id, fullName: user.fullname, handicap: user.handicap ?? 0.0)] + additionalGolfers

        let roundGolfers = self.golfers.map { golfer in
            Round.Golfer(id: golfer.id, fullName: golfer.fullName, handicap: golfer.handicap)
        }

        let round = Round(
            courseId: courseId,
            courseName: course.name,
            teeName: tee.tee_name,
            golfers: roundGolfers,
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

            // Calculate playing handicaps and stroke holes for all golfers
            for golfer in self.golfers {
                let golferHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: golfer.handicap,
                    slopeRating: self.selectedTee?.slope_rating ?? 113,
                    courseRating: self.selectedTee?.course_rating ?? 72.0,
                    par: self.selectedTee?.course_par ?? 72
                )
                self.playingHandicaps[golfer.id] = golferHandicap

                let golferStrokeHoles = holeHandicaps.sorted { $0.value < $1.value }.prefix(golferHandicap).map { $0.key }
                self.strokeHoles[golfer.id] = golferStrokeHoles

                print("Golfer: \(golfer.fullName), Playing Handicap: \(golferHandicap), Stroke Holes: \(golferStrokeHoles)")
            }
        }
    }

    func updateNetScores() {
        var netScoreDict = [Int: [String: Int]]()

        for (holeNumber, scoresDict) in scores {
            for (golferId, score) in scoresDict {
                netScoreDict[holeNumber, default: [:]][golferId] = (strokeHoles[golferId]?.contains(holeNumber) ?? false) ? score - 1 : score
            }
        }

        self.netScores = netScoreDict
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
