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
    @Published var netStrokePlayScores: [Int: [String: Int]] = [:] // Nested dictionary to hold net scores keyed by hole number and golfer ID
    @Published var pars: [Int: Int] = [:] // Dictionary to hold pars keyed by hole number
    @Published var playingHandicaps: [String: Int] = [:] // Dictionary to hold playing handicaps keyed by golfer ID
    @Published var strokeHoles: [String: [Int]] = [:] // Dictionary to hold stroke holes keyed by golfer ID
    @Published var roundId: String?
    @Published var recentRounds: [Round] = []
    @Published var golfers: [Golfer] = []
    @Published var currentHole: Int = 1 // Track the current hole
    @Published var courseHandicaps: [String: Int] = [:] // Dictionary to hold course handicaps keyed by golfer ID
    @Published var holes: [String: [Hole]] = [:] // Dictionary with teeId as key and array of Holes as value
    @Published var matchPlayViewModel: MatchPlayViewModel?
    @Published var matchPlayStatus: String?
    @Published var isMatchPlay: Bool = false // Track whether it's a match play game
    @Published var matchPlayStrokeHoles: [String: [Int]] = [:]
    @Published var matchPlayHandicap: Int = 0
    @Published var matchPlayNetScores: [Int: [String: Int]] = [:]

    func beginRound(for user: User, additionalGolfers: [Golfer], isMatchPlay: Bool, completion: @escaping (String?, Error?, [String: Any]?) -> Void) {
        self.isMatchPlay = isMatchPlay
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

        if isMatchPlay && golfers.count >= 2 {
            initializeMatchPlayGame()
        }

        do {
            let db = Firestore.firestore()
            let roundsRef = db.collection("users").document(user.id).collection("rounds")
            let roundRef = try roundsRef.addDocument(from: round)

            roundRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    print("Round saved with ID: \(document.documentID)")
                    self.roundId = document.documentID // Set roundId here
                    let additionalInfo: [String: Any] = ["courseId": courseId, "teeId": tee.id]
                    completion(document.documentID, nil, additionalInfo)
                } else {
                    print("Error saving round: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil, error, nil)
                }
            }
        } catch {
            print("Error saving round: \(error.localizedDescription)")
            completion(nil, error, nil)
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

    func calculateStrokePlayStrokeHoles(holes: [Hole]) {
        for golfer in golfers {
            guard let courseHandicap = courseHandicaps[golfer.id] else {
                print("Warning: No course handicap found for golfer \(golfer.fullName)")
                continue
            }
            
            let strokeHoles = HandicapCalculator.determineStrokePlayStrokeHoles(courseHandicap: courseHandicap, holes: holes)
            self.strokeHoles[golfer.id] = strokeHoles
            
            print("Calculated stroke holes for \(golfer.fullName): \(strokeHoles)")
            print("Course Handicap: \(courseHandicap)")
        }
    }

    func updateStrokePlayNetScores() {
        for (holeNumber, scores) in grossScores {
            for (golferId, grossScore) in scores {
                let isStrokeHole = strokeHoles[golferId]?.contains(holeNumber) ?? false
                let netScore = isStrokeHole ? grossScore - 1 : grossScore
                netStrokePlayScores[holeNumber, default: [:]][golferId] = netScore
                
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
        let netScoresData = netStrokePlayScores.mapValues { $0.mapValues { $0 } }

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
    
    func updateScore(for hole: Int, golferId: String, score: Int) {
        grossScores[hole, default: [:]][golferId] = score
        updateStrokePlayNetScores()
        
        if let matchPlayVM = matchPlayViewModel, golfers.count >= 2 {
            let player1 = golfers[0]
            let player2 = golfers[1]
            let player1Score = grossScores[hole]?[player1.id] ?? 0
            let player2Score = grossScores[hole]?[player2.id] ?? 0
            
            let player1HoleHandicap = getHoleHandicap(for: hole, teeId: player1.tee?.id ?? "")
            let player2HoleHandicap = getHoleHandicap(for: hole, teeId: player2.tee?.id ?? "")
            
            matchPlayVM.updateScore(
                for: hole,
                player1Score: player1Score,
                player2Score: player2Score,
                player1HoleHandicap: player1HoleHandicap,
                player2HoleHandicap: player2HoleHandicap
            )
        }
    }

    func getHoleHandicap(for hole: Int, teeId: String) -> Int {
        if let holes = self.holes[teeId],
           let holeData = holes.first(where: { $0.holeNumber == hole }) {
            return holeData.handicap
        }
        return 0  // Default value if hole data is not found
    }

    func isMatchPlayStrokeHole(for golferId: String, teeId: String, holeNumber: Int) -> Bool {
        guard let holesForTee = holes[teeId],
              let hole = holesForTee.first(where: { $0.holeNumber == holeNumber }),
              let matchPlayVM = matchPlayViewModel else { return false }
        return matchPlayVM.isStrokeHole(for: golferId, holeHandicap: hole.handicap)
    }

    func getMatchPlayStatus() -> String? {
        return matchPlayViewModel?.matchStatus
    }

    func isMatchPlayComplete() -> Bool {
        return matchPlayViewModel?.isMatchComplete() ?? false
    }

    func getMatchPlayFinalScore() -> String? {
        return matchPlayViewModel?.getFinalScore()
    }

    public func calculateMatchPlayHandicap() -> Int {
        guard golfers.count == 2 else {
            print("Debug: Not enough golfers for match play")
            return 0
        }
        
        let golfer1 = golfers[0]
        let golfer2 = golfers[1]
        
        print("Debug: Golfer 1 - \(golfer1.fullName), Handicap: \(golfer1.handicap), Playing Handicap: \(golfer1.playingHandicap ?? 0)")
        print("Debug: Golfer 2 - \(golfer2.fullName), Handicap: \(golfer2.handicap), Playing Handicap: \(golfer2.playingHandicap ?? 0)")
        
        let handicap1 = golfer1.playingHandicap ?? Int(golfer1.handicap)
        let handicap2 = golfer2.playingHandicap ?? Int(golfer2.handicap)
        
        let matchPlayHandicap = abs(handicap1 - handicap2)
        
        print("Debug: Calculated Match Play Handicap: \(matchPlayHandicap)")
        
        return matchPlayHandicap
    }
    
    private func initializeMatchPlayGame() {
        guard golfers.count >= 2 else { return }
        
        let player1 = golfers[0]
        let player2 = golfers[1]
        let matchPlayHandicap = calculateMatchPlayHandicap()
        
        matchPlayViewModel = MatchPlayViewModel(
            player1Id: player1.id,
            player2Id: player2.id,
            matchPlayHandicap: matchPlayHandicap
        )
    }
    
    func updateMatchPlayStatus(for holeNumber: Int) {
        guard isMatchPlay, let matchPlayVM = matchPlayViewModel, golfers.count >= 2 else { return }
        
        let player1Score = grossScores[holeNumber]?[golfers[0].id] ?? 0
        let player2Score = grossScores[holeNumber]?[golfers[1].id] ?? 0
        
        let player1HoleHandicap = getHoleHandicap(for: holeNumber, teeId: golfers[0].tee?.id ?? "")
        let player2HoleHandicap = getHoleHandicap(for: holeNumber, teeId: golfers[1].tee?.id ?? "")
        
        matchPlayVM.updateScore(
            for: holeNumber,
            player1Score: player1Score,
            player2Score: player2Score,
            player1HoleHandicap: player1HoleHandicap,
            player2HoleHandicap: player2HoleHandicap
        )
        matchPlayVM.updateMatchStatus(for: holeNumber)
    }
}