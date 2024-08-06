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
    @Published var courseHandicaps: [String: Int] = [:] // Dictionary to hold playing handicaps keyed by golfer ID
    @Published var strokeHoles: [String: [Int]] = [:] // Dictionary to hold stroke holes keyed by golfer ID
    @Published var roundId: String?
    @Published var recentRounds: [Round] = []
    @Published var golfers: [Golfer] = []
    @Published var currentHole: Int = 1 // Track the current hole
    @Published var holes: [String: [Hole]] = [:] // Dictionary with teeId as key and array of Holes as value
    @Published var matchPlayViewModel: MatchPlayViewModel?
    @Published var matchPlayStatus: String?
    @Published var isMatchPlay: Bool = false // Track whether it's a match play game
    @Published var matchPlayStrokeHoles: [String: [Int]] = [:]
    @Published var matchPlayHandicap: Int = 0
    @Published var matchPlayNetScores: [Int: [String: Int]] = [:]
    @Published var previousHoleWinner: String?
    @Published var holeWinners: [Int: String] = [:]
    @Published var holeTallies: [String: Int] = [:]
    @Published var matchScore: Int = 0
    @Published var holesPlayed: Int = 0
    private var lastUpdatedHole: Int = 0
    private var talliedHoles: Set<Int> = []
    @Published var matchWinner: String?
    @Published var winningScore: String?
    
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
            initializeMatchPlay()
            initializeMatchPlayStatus() // Call this here
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
        
        holeWinners = [:]
        holeTallies = [:]
        talliedHoles = []
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
                self.courseHandicaps[golfer.id] = golferHandicap
                
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
    
    func allScoresEntered(for holeNumber: Int? = nil) -> Bool {
        if let hole = holeNumber {
            // Check for a specific hole
            return golfers.allSatisfy { golfer in
                grossScores[hole]?[golfer.id] != nil
            }
        } else {
            // Check all holes
            return (1...18).allSatisfy { hole in
                golfers.allSatisfy { golfer in
                    grossScores[hole]?[golfer.id] != nil
                }
            }
        }
    }
    
    func updateScore(for hole: Int, golferId: String, score: Int) {
        grossScores[hole, default: [:]][golferId] = score
        updateStrokePlayNetScores()
        
        if isMatchPlay && allScoresEntered(for: hole) {
            updateMatchPlayStatus(for: hole)
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
    
    func initializeMatchPlay() {
        guard isMatchPlay && golfers.count == 2 else { return }
        
        let player1 = golfers[0]
        let player2 = golfers[1]
        
        // Ensure we're using the correct playing handicaps
        let player1Handicap = courseHandicaps[player1.id] ?? 0
        let player2Handicap = courseHandicaps[player2.id] ?? 0
        
        print("Debug: Initializing Match Play")
        print("Debug: \(player1.fullName) - Playing Handicap: \(player1Handicap)")
        print("Debug: \(player2.fullName) - Playing Handicap: \(player2Handicap)")
        
        let matchPlayHandicap = abs(player1Handicap - player2Handicap)
        
        print("Debug: Calculated Match Play Handicap: \(matchPlayHandicap)")
        
        matchPlayViewModel = MatchPlayViewModel(
            player1Id: player1.id,
            player2Id: player2.id,
            matchPlayHandicap: matchPlayHandicap
        )
        
        // Set up match play stroke holes
        let lowerHandicapPlayer = player1Handicap < player2Handicap ? player1 : player2
        let higherHandicapPlayer = player1Handicap < player2Handicap ? player2 : player1
        
        matchPlayStrokeHoles[lowerHandicapPlayer.id] = []
        matchPlayStrokeHoles[higherHandicapPlayer.id] = strokeHoles[higherHandicapPlayer.id]?.prefix(matchPlayHandicap).map { $0 } ?? []
        
        print("Debug: Match Play Stroke Holes - \(lowerHandicapPlayer.fullName): \(matchPlayStrokeHoles[lowerHandicapPlayer.id] ?? [])")
        print("Debug: Match Play Stroke Holes - \(higherHandicapPlayer.fullName): \(matchPlayStrokeHoles[higherHandicapPlayer.id] ?? [])")
    }
    
    func updateMatchPlayStatus(for currentHoleNumber: Int) {
        guard isMatchPlay,
                matchPlayViewModel != nil,
                golfers.count >= 2,
                currentHoleNumber > 0,
              currentHoleNumber > lastUpdatedHole,
              allScoresEntered(for: currentHoleNumber) else {
            print("Debug: Guard condition failed in updateMatchPlayStatus")
            print("isMatchPlay: \(isMatchPlay)")
            print("matchPlayViewModel: \(matchPlayViewModel != nil)")
            print("golfers count: \(golfers.count)")
            print("currentHoleNumber: \(currentHoleNumber)")
            print("lastUpdatedHole: \(lastUpdatedHole)")
            print("allScoresEntered: \(allScoresEntered(for: currentHoleNumber))")
            return
        }
        
        let player1 = golfers[0]
        let player2 = golfers[1]
        let player1GrossScore = grossScores[currentHoleNumber]?[player1.id] ?? 0
        let player2GrossScore = grossScores[currentHoleNumber]?[player2.id] ?? 0
        let player1NetScore = matchPlayNetScores[currentHoleNumber]?[player1.id] ?? player1GrossScore
        let player2NetScore = matchPlayNetScores[currentHoleNumber]?[player2.id] ?? player2GrossScore
        
        let player1HoleHandicap = getHoleHandicap(for: currentHoleNumber, teeId: player1.tee?.id ?? "")
        let player2HoleHandicap = getHoleHandicap(for: currentHoleNumber, teeId: player2.tee?.id ?? "")
        
        matchPlayViewModel?.updateScore(
            for: currentHoleNumber,
            player1Score: player1NetScore,
            player2Score: player2NetScore,
            player1HoleHandicap: player1HoleHandicap,
            player2HoleHandicap: player2HoleHandicap
        )
        
        let matchStatus = matchPlayViewModel?.calculateMatchStatus() ?? "Unknown"
        
        print("Debug: Match Play Status Update")
        print("Previous Hole \(currentHoleNumber):")
        print("  \(player1.fullName): Gross \(player1GrossScore), Net \(player1NetScore)")
        print("  \(player2.fullName): Gross \(player2GrossScore), Net \(player2NetScore)")
        print("Match Status: \(matchStatus)")
        print("Current Hole: \(currentHoleNumber + 1)")
        print("-----------------------------")
        
        lastUpdatedHole = currentHoleNumber
        
        if player1NetScore < player2NetScore {
            holeWinners[currentHoleNumber] = player1.fullName
        } else if player2NetScore < player1NetScore {
            holeWinners[currentHoleNumber] = player2.fullName
        } else {
            holeWinners[currentHoleNumber] = "Halved"
        }
    }
    
    func initializeMatchPlayStatus() {
        guard isMatchPlay, let matchPlayVM = matchPlayViewModel, golfers.count >= 2 else { return }
        
        let player1 = golfers[0]
        let player2 = golfers[1]
        
        print("Debug: Match Play Status Update")
        print("Match Play Status Initialized")
        print("  \(player1.fullName): No Score Entered Yet")
        print("  \(player2.fullName): No Score Entered Yet")
        print("Match Status: All Square")
        print("Current Hole: 1")
        print("-----------------------------")
    }
    
    func updateTallies(for holeNumber: Int) {
        guard let player1Score = matchPlayNetScores[holeNumber]?[golfers[0].id],
              let player2Score = matchPlayNetScores[holeNumber]?[golfers[1].id] else {
            return
        }
        
        if player1Score < player2Score {
            holeTallies[golfers[0].fullName, default: 0] += 1
            holeWinners[holeNumber] = golfers[0].fullName
        } else if player2Score < player1Score {
            holeTallies[golfers[1].fullName, default: 0] += 1
            holeWinners[holeNumber] = golfers[1].fullName
        } else {
            holeTallies["Halved", default: 0] += 1
            holeWinners[holeNumber] = "Halved"
        }
        
        talliedHoles.insert(holeNumber)
    }
    
    func resetTallyForHole(_ holeNumber: Int) {
        guard talliedHoles.contains(holeNumber), let winner = holeWinners[holeNumber] else { return }
        
        if winner == "Halved" {
            holeTallies["Halved", default: 0] -= 1
        } else {
            holeTallies[winner, default: 0] -= 1
        }
        talliedHoles.remove(holeNumber)
    }
    
    func updateMatchStatus() {
        guard isMatchPlay && golfers.count >= 2 else { return }
        
        // If a winner has already been determined, don't update anything
        if matchWinner != nil {
            return
        }
        
        let player1 = golfers[0]
        let player2 = golfers[1]
        
        let player1Wins = holeTallies[player1.fullName, default: 0]
        let player2Wins = holeTallies[player2.fullName, default: 0]
        let halvedHoles = holeTallies["Halved", default: 0]
        
        matchScore = player1Wins - player2Wins
        holesPlayed = min(player1Wins + player2Wins + halvedHoles, 18)
        
        let remainingHoles = 18 - holesPlayed
        
        if abs(matchScore) > remainingHoles {
            matchWinner = matchScore > 0 ? player1.fullName : player2.fullName
            winningScore = "\(abs(matchScore))&\(remainingHoles)"
        } else if holesPlayed == 18 {
            if matchScore > 0 {
                matchWinner = player1.fullName
                winningScore = "\(matchScore)UP"
            } else if matchScore < 0 {
                matchWinner = player2.fullName
                winningScore = "\(abs(matchScore))UP"
            } else {
                matchWinner = "Tie"
                winningScore = "All Square"
            }
        }
    }
    
    func recalculateTallies(upToHole: Int) {
        guard isMatchPlay && golfers.count >= 2 else { return }
        
        holeTallies = [:]
        talliedHoles = []
        
        for holeNumber in 1...upToHole {
            updateTallies(for: holeNumber)
        }
        
        updateMatchStatus()
    }
}
