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
    @Published var grossScores: [Int: [String: Int]] = [:] // Nested dictionary to hold gross scores keyed by hole number and golfer ID
    @Published var netScores: [Int: [String: Int]] = [:] // Nested dictionary to hold net scores keyed by hole number and golfer ID
    @Published var pars: [Int: Int] = [:] // Dictionary to hold pars keyed by hole number
    @Published var playingHandicaps: [String: Int] = [:] // Dictionary to hold playing handicaps keyed by golfer ID
    @Published var strokeHoles: [String: [Int]] = [:] // Dictionary to hold stroke holes keyed by golfer ID
    @Published var roundId: String?
    @Published var recentRounds: [Round] = []
    @Published var golfers: [Golfer] = []
    @Published var currentHole: Int = 1 // Track the current hole
    @Published var courseHandicaps: [String: Int] = [:] // Dictionary to hold course handicaps keyed by golfer ID
    @Published var holes: [String: [Hole]] = [:]

    func beginRound(for user: User, additionalGolfers: [Golfer], completion: @escaping (String?, String?, String?) -> Void) {
        print("Beginning round...")
        guard let course = selectedCourse,
              let tee = selectedTee,
              let courseId = course.id else {
            print("Missing required data to begin round. Course: \(selectedCourse?.name ?? "nil"), Tee: \(selectedTee?.tee_name ?? "nil")")
            completion(nil, nil, nil)
            return
        }

        print("Course and tee selected: \(course.name), \(tee.tee_name)")

        self.golfers = [Golfer(id: user.id, fullName: user.fullname, handicap: user.handicap ?? 0.0)] + additionalGolfers
        print("Golfers for this round: \(self.golfers.map { $0.fullName })")

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
                    completion(document.documentID, courseId, tee.id)
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
            self.pars = pars
            completion(pars)

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

    func calculateStrokeHoles(holes: [Hole]) {
        for golfer in golfers {
            guard let courseHandicap = courseHandicaps[golfer.id] else {
                print("Warning: No course handicap found for golfer \(golfer.fullName)")
                continue
            }
            
            let strokeHoles = HandicapCalculator.determineStrokeHoles(courseHandicap: courseHandicap, holes: holes)
            self.strokeHoles[golfer.id] = strokeHoles
            
            print("Calculated stroke holes for \(golfer.fullName): \(strokeHoles)")
            print("Course Handicap: \(courseHandicap)")
        }
    }

    func updateNetScores() {
        for (holeNumber, scores) in grossScores {
            for (golferId, grossScore) in scores {
                let isStrokeHole = strokeHoles[golferId]?.contains(holeNumber) ?? false
                let netScore = isStrokeHole ? grossScore - 1 : grossScore
                netScores[holeNumber, default: [:]][golferId] = netScore
                
                print("Hole \(holeNumber) for golfer \(golferId): Gross \(grossScore), Net \(netScore), Stroke Hole: \(isStrokeHole)")
            }
        }
    }
    
    func printDebugInfo() {
            print("RoundViewModel Debug Info:")
            print("Number of golfers: \(golfers.count)")
            print("Golfers: \(golfers)")
            print("Scores: \(grossScores)")
            print("Stroke Holes: \(strokeHoles)")
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
                print("Fetched recent rounds: \(self.recentRounds)")
            }
    }

    func resetScoresForCurrentHole() {
        for golfer in golfers {
            let par = pars[currentHole] ?? 0
            if let index = grossScores[currentHole]?.firstIndex(where: { $0.key == golfer.id }) {
                grossScores[currentHole]?[golfer.id] = par
            } else {
                grossScores[currentHole, default: [:]][golfer.id] = par
            }
        }
    }

    func nextHole() {
        saveScores()
        if currentHole < 18 {
            currentHole += 1
            resetScoresForCurrentHole()
        }
    }

    func previousHole() {
        saveScores()
        if currentHole > 1 {
            currentHole -= 1
            resetScoresForCurrentHole()
        }
    }

    func saveScores() {
        guard let roundId = roundId else { return }

        let db = Firestore.firestore()
        let grossScoresData = grossScores.mapValues { $0.mapValues { $0 } }
        let netScoresData = netScores.mapValues { $0.mapValues { $0 } }

        db.collection("users").document("user_id").collection("rounds").document(roundId).setData(["gross_scores": grossScoresData, "net_scores": netScoresData], merge: true) { error in
            if let error = error {
                print("Error saving scores: \(error.localizedDescription)")
            } else {
                print("Scores saved successfully: \(self.grossScores)")
            }
        }
    }

    func getMissingScores(for golferId: String) -> [Int] {
        return (1...18).filter { holeNumber in
            grossScores[holeNumber]?[golferId] == nil
        }
    }

    func allScoresEntered() -> Bool {
        for golfer in golfers {
            if !getMissingScores(for: golfer.id).isEmpty {
                return false
            }
        }
        return true
    }
}
