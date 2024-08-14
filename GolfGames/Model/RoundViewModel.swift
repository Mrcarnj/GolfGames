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
    @Published var selectedScorecardType: ScorecardType = .strokePlay
    @Published var matchStatus: [Int: [String: Int]] = [:]
    @Published var matchStatusArray: [Int] = Array(repeating: 0, count: 18)
    @Published var finalMatchStatusArray: [Int]?
    @Published var matchWinningHole: Int?
    @Published var matchPlayGolfers: (Golfer, Golfer)?
    @Published var presses: [(startHole: Int, matchStatusArray: [Int], winner: String?, winningScore: String?, winningHole: Int?)] = []
    @Published var pressStatuses: [String] = []
    @Published var currentPressStartHole: Int?

    func formattedGolferName(for golfer: Golfer) -> String {
        return golfer.formattedName(golfers: self.golfers)
    }
    
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
        print("Golfers for this round: \(self.golfers.map { $0.formattedName(golfers: self.golfers) })")
        
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
                
                print("Golfer: \(golfer.formattedName(golfers: self.golfers)), Playing Handicap: \(golferHandicap), Stroke Holes: \(golferStrokeHoles)")
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
        
        print("Calculated stroke holes for \(golfer.formattedName(golfers: self.golfers)): \(strokeHoles)")
        print("Course Handicap: \(courseHandicap)")
    }
}
    
    func updateStrokePlayNetScores() {
        for (holeNumber, scores) in grossScores {
            for (golferId, grossScore) in scores {
                guard let courseHandicap = courseHandicaps[golferId] else {
                    print("Warning: No course handicap found for golfer \(golferId)")
                    continue
                }
                
                let isStrokeHole = strokeHoles[golferId]?.contains(holeNumber) ?? false
                let netScore: Int
                
                if courseHandicap < 0 {
                    netScore = isStrokeHole ? grossScore + 1 : grossScore
                } else {
                    netScore = isStrokeHole ? grossScore - 1 : grossScore
                }
                
                netStrokePlayScores[holeNumber, default: [:]][golferId] = netScore
                
                print("Hole \(holeNumber) for golfer \(golferId): Gross \(grossScore), Net \(netScore), Stroke Hole: \(isStrokeHole), Course Handicap: \(courseHandicap)")
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
        
        // Recalculate match status for all holes from the changed hole onward
        for currentHole in hole...18 {
            updateMatchStatus(for: currentHole)
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
        guard isMatchPlay, golfers.count >= 2 else { return }
        
        // If matchPlayGolfers is not set, default to the first two golfers
        if matchPlayGolfers == nil {
            matchPlayGolfers = (golfers[0], golfers[1])
        }
        
        // Ensure we're using the correct playing handicaps
        let player1Handicap = courseHandicaps[matchPlayGolfers!.0.id] ?? 0
        let player2Handicap = courseHandicaps[matchPlayGolfers!.1.id] ?? 0
        
        print("Debug: Initializing Match Play")
        print("Debug: \(matchPlayGolfers!.0.fullName) - Playing Handicap: \(player1Handicap)")
        print("Debug: \(matchPlayGolfers!.1.fullName) - Playing Handicap: \(player2Handicap)")
        
        let matchPlayHandicap = abs(player1Handicap - player2Handicap)
        
        print("Debug: Calculated Match Play Handicap: \(matchPlayHandicap)")
        
        matchPlayViewModel = MatchPlayViewModel(
            player1Id: matchPlayGolfers!.0.id,
            player2Id: matchPlayGolfers!.1.id,
            matchPlayHandicap: matchPlayHandicap
        )
        
        // Set up match play stroke holes
        let lowerHandicapPlayer = player1Handicap < player2Handicap ? matchPlayGolfers!.0 : matchPlayGolfers!.1
        let higherHandicapPlayer = player1Handicap < player2Handicap ? matchPlayGolfers!.1 : matchPlayGolfers!.0
        
        matchPlayStrokeHoles[lowerHandicapPlayer.id] = []
        matchPlayStrokeHoles[higherHandicapPlayer.id] = strokeHoles[higherHandicapPlayer.id]?.prefix(matchPlayHandicap).map { $0 } ?? []
        
        print("Debug: Match Play Stroke Holes - \(lowerHandicapPlayer.fullName): \(matchPlayStrokeHoles[lowerHandicapPlayer.id] ?? [])")
        print("Debug: Match Play Stroke Holes - \(higherHandicapPlayer.fullName): \(matchPlayStrokeHoles[higherHandicapPlayer.id] ?? [])")
    }
    
    func updateTallies(for holeNumber: Int) {
        guard let (player1, player2) = matchPlayGolfers,
              let player1Score = matchPlayNetScores[holeNumber]?[player1.id],
              let player2Score = matchPlayNetScores[holeNumber]?[player2.id] else {
            return
        }
        
        if player1Score < player2Score {
            holeTallies[player1.formattedName(golfers: self.golfers), default: 0] += 1
            holeWinners[holeNumber] = player1.formattedName(golfers: self.golfers)
        } else if player2Score < player1Score {
            holeTallies[player2.formattedName(golfers: self.golfers), default: 0] += 1
            holeWinners[holeNumber] = player2.formattedName(golfers: self.golfers)
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
    
    private func formatWinningScore(_ score: String) -> String {
        if score.hasSuffix("&0") {
            let leadNumber = score.split(separator: "&")[0]
            return "\(leadNumber)UP"
        }
        return score
    }

    func updateMatchStatus(for currentHoleNumber: Int) {
        self.currentHole = currentHoleNumber
        guard isMatchPlay, let (player1, player2) = matchPlayGolfers else { return }
        
        // Reset match status array if recalculating from an earlier hole
        if currentHoleNumber == 1 {
            matchStatusArray = Array(repeating: 0, count: 18)
            matchWinner = nil
            winningScore = nil
            matchWinningHole = nil
            finalMatchStatusArray = nil
        }
        
        // Only update if the match hasn't been finalized
        if matchWinner == nil {
            // Update match status for each hole up to the current hole
            for hole in 1...currentHoleNumber {
                if let winner = holeWinners[hole] {
                    if winner == player1.formattedName(golfers: self.golfers) {
                        matchStatusArray[hole - 1] = 1
                    } else if winner == player2.formattedName(golfers: self.golfers) {
                        matchStatusArray[hole - 1] = -1
                    } else {
                        matchStatusArray[hole - 1] = 0
                    }
                }
                
                // Calculate cumulative status
                matchScore = matchStatusArray[0..<hole].reduce(0, +)
                holesPlayed = hole
                
                let remainingHoles = 18 - holesPlayed
                
                // Check for match win conditions
                if abs(matchScore) > remainingHoles {
                    matchWinner = matchScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
                    winningScore = formatWinningScore("\(abs(matchScore))&\(remainingHoles)")
                    matchWinningHole = hole
                    finalMatchStatusArray = matchStatusArray
                    matchPlayStatus = "\(matchWinner!) won \(winningScore!)"
                    break
                } else if holesPlayed == 18 {
                    if matchScore != 0 {
                        matchWinner = matchScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
                        winningScore = "1UP"
                        matchPlayStatus = "\(matchWinner!) won \(winningScore!)"
                    } else {
                        matchWinner = "Tie"
                        winningScore = "All Square"
                        matchPlayStatus = "Match ended \(winningScore!)"
                    }
                    matchWinningHole = 18
                    finalMatchStatusArray = matchStatusArray
                    break
                }
                
                // Update matchPlayStatus string
                if matchScore == 0 {
                    matchPlayStatus = "All Square thru \(holesPlayed)"
                } else {
                    let leadingPlayer = matchScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
                    let absScore = abs(matchScore)
                    
                    if absScore == remainingHoles {
                        matchPlayStatus = "\(leadingPlayer) \(absScore)UP with \(remainingHoles) to play (Dormie)"
                    } else {
                        matchPlayStatus = "\(leadingPlayer) \(absScore)UP thru \(holesPlayed)"
                    }
                }
            }
        }
        
        // Update press statuses
        updateAllPressStatuses(for: currentHoleNumber)
        
        print("Updated match status for hole \(currentHoleNumber): \(matchStatusArray)")
        print("Main match status: \(matchPlayStatus ?? "N/A")")
        for (index, pressStatus) in pressStatuses.enumerated() {
            print("Press \(index + 1) status: \(pressStatus)")
        }
        
        objectWillChange.send()
    }

    func recalculateTallies(upToHole: Int) {
        guard isMatchPlay && golfers.count >= 2 else { return }
        
        holeTallies = [:]
        talliedHoles = []
        matchStatusArray = Array(repeating: 0, count: 18)
        
        for holeNumber in 1...upToHole {
            updateTallies(for: holeNumber)
            updateMatchStatus(for: holeNumber)
        }
    }
    
    private func updateAllPressStatuses(for currentHoleNumber: Int) {
        for (index, press) in presses.enumerated() {
            if currentHoleNumber >= press.startHole {
                updatePressMatchStatus(pressIndex: index, for: currentHoleNumber)
                pressStatuses[index] = calculatePressStatus(pressIndex: index, currentHole: currentHoleNumber)
            }
        }
    }
    
    private func calculatePressStatus(pressIndex: Int, currentHole: Int) -> String {
        guard pressIndex < presses.count, let (player1, player2) = matchPlayGolfers else {
            return "Invalid Press"
        }
        
        let press = presses[pressIndex]
        
        // If this press has already been won, return its final status
        if let winner = press.winner, let winningScore = press.winningScore {
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        }
        
        let pressStartHole = press.startHole
        let relevantHoles = pressStartHole...currentHole
        
        let cumulativePressScore = relevantHoles.reduce(0) { total, hole in
            return total + (press.matchStatusArray[hole - pressStartHole] ?? 0)
        }
        
        let holesPlayed = currentHole - pressStartHole + 1
        let remainingHoles = 18 - currentHole
        
        // Check if this press has already been won
        if let winner = press.winner, let winningScore = press.winningScore {
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        }
        
        // Check for press win conditions
        if abs(cumulativePressScore) > remainingHoles {
            let winner = cumulativePressScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
            let winningScore = formatWinningScore("\(abs(cumulativePressScore))&\(remainingHoles)")
            presses[pressIndex].winner = winner
            presses[pressIndex].winningScore = winningScore
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        } else if currentHole == 18 {
            if cumulativePressScore != 0 {
                let winner = cumulativePressScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
                let winningScore = "\(abs(cumulativePressScore))UP"
                presses[pressIndex].winner = winner
                presses[pressIndex].winningScore = winningScore
                return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
            } else {
                presses[pressIndex].winner = "Tie"
                presses[pressIndex].winningScore = "All Square"
                return "Press \(pressIndex + 1): Tie - All Square"
            }
        }
        
        // Dormie condition
        if abs(cumulativePressScore) == remainingHoles {
            let leadingPlayer = cumulativePressScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
            return "Press \(pressIndex + 1): \(leadingPlayer) \(abs(cumulativePressScore))UP with \(remainingHoles) to play (Dormie)"
        }
        
        // Regular status
        if cumulativePressScore == 0 {
            return "Press \(pressIndex + 1): All Square thru \(holesPlayed)"
        } else {
            let leadingPlayer = cumulativePressScore > 0 ? player1.formattedName(golfers: self.golfers) : player2.formattedName(golfers: self.golfers)
            return "Press \(pressIndex + 1): \(leadingPlayer) \(abs(cumulativePressScore))UP thru \(holesPlayed)"
        }
    }
    
    func updatePressMatchStatus(pressIndex: Int, for currentHoleNumber: Int) {
        guard let (golfer1, golfer2) = matchPlayGolfers else { return }
        
        let press = presses[pressIndex]
        
        // If the press already has a winner, don't update it
        if press.winner != nil {
            return
        }
        
        let pressStartHole = press.startHole
        for hole in pressStartHole...currentHoleNumber {
            if let winner = holeWinners[hole] {
                if winner == golfer1.formattedName(golfers: self.golfers) {
                    presses[pressIndex].matchStatusArray[hole - pressStartHole] = 1
                } else if winner == golfer2.formattedName(golfers: self.golfers) {
                    presses[pressIndex].matchStatusArray[hole - pressStartHole] = -1
                } else {
                    presses[pressIndex].matchStatusArray[hole - pressStartHole] = 0
                }
            }
        }
        
        // Check if the press has been won
        let pressStatus = presses[pressIndex].matchStatusArray.reduce(0, +)
        let remainingHoles = 18 - currentHoleNumber
        if abs(pressStatus) > remainingHoles {
            let winner = pressStatus > 0 ? golfer1.formattedName(golfers: self.golfers) : golfer2.formattedName(golfers: self.golfers)
            let leadAmount = abs(pressStatus)
            presses[pressIndex].winner = winner
            presses[pressIndex].winningScore = formatWinningScore("\(leadAmount)&\(remainingHoles)")
            presses[pressIndex].winningHole = currentHoleNumber
        } else if currentHoleNumber == 18 && pressStatus != 0 {
            // Handle the case where the press is won on the 18th hole
            let winner = pressStatus > 0 ? golfer1.formattedName(golfers: self.golfers) : golfer2.formattedName(golfers: self.golfers)
            presses[pressIndex].winner = winner
            presses[pressIndex].winningScore = "1UP"
            presses[pressIndex].winningHole = 18
        }
    }
    
    func clearRoundData() {
        print("Clearing round data...")
        print("Number of presses before clearing: \(presses.count)")
        print("Number of press statuses before clearing: \(pressStatuses.count)")
        
        // Reset all round-related data
        roundId = nil
        selectedCourse = nil
        selectedTee = nil
        golfers = []
        grossScores = [:]
        netStrokePlayScores = [:]
        matchPlayNetScores = [:]
        strokeHoles = [:]
        matchPlayStrokeHoles = [:]
        holeWinners = [:]
        matchScore = 0
        holesPlayed = 0
        matchWinner = nil
        winningScore = nil
        matchPlayGolfers = nil
        
        presses.removeAll()
        pressStatuses.removeAll()
        currentPressStartHole = nil
        
        print("Number of presses after clearing: \(presses.count)")
        print("Number of press statuses after clearing: \(pressStatuses.count)")
        
        objectWillChange.send()
    }
    
    func setMatchPlayGolfers(golfer1: Golfer, golfer2: Golfer) {
        matchPlayGolfers = (golfer1, golfer2)
        initializeMatchPlay()
    }
    
    func initiatePress(atHole: Int) {
        // Allow new presses if there are existing presses or if the main match hasn't been won yet
        if presses.isEmpty && matchWinner != nil {
            print("Cannot initiate new press: main match has been won and no existing presses")
            return
        }

        print("Initiating press at hole \(atHole)")
        print("Current hole: \(currentHole)")
        print("Number of presses before adding: \(presses.count)")
        
        presses.append((startHole: atHole, matchStatusArray: Array(repeating: 0, count: 18), winner: nil, winningScore: nil, winningHole: nil))
        pressStatuses.append("Press \(presses.count): All Square thru 0")
        currentPressStartHole = atHole
        
        print("Number of presses after adding: \(presses.count)")
        print("Number of press statuses: \(pressStatuses.count)")
        print("Current presses: \(presses)")
        print("Current press statuses: \(pressStatuses)")
        
        objectWillChange.send()
    }
    
    func getLosingPlayer() -> Golfer? {
        guard let (golfer1, golfer2) = matchPlayGolfers else { return nil }
        
        if let lastPress = presses.last {
            // Ensure we're not accessing an index out of bounds
            let relevantIndex = max(0, min(currentHole - lastPress.startHole, lastPress.matchStatusArray.count - 1))
            let pressScore = lastPress.matchStatusArray[relevantIndex]
            if pressScore > 0 {
                return golfer2
            } else if pressScore < 0 {
                return golfer1
            }
        } else {
            // If no presses, check the main match
            if matchScore > 0 {
                return golfer2
            } else if matchScore < 0 {
                return golfer1
            }
        }
        return nil  // Return nil if it's all square
    }
    
    func getCurrentPressStatus() -> (leadingPlayer: Golfer?, trailingPlayer: Golfer?, score: Int)? {
    guard let (golfer1, golfer2) = matchPlayGolfers else { return nil }
    
    if let lastPress = presses.last {
        let pressStartHole = lastPress.startHole
        let lowerBound = max(pressStartHole, 1)
        let upperBound = max(currentHole, lowerBound)
        let relevantHoles = lowerBound...upperBound
        
        print("Press start hole: \(pressStartHole)")
        print("Current hole: \(currentHole)")
        print("Relevant holes: \(relevantHoles)")
        
        let cumulativePressScore = relevantHoles.reduce(0) { total, hole in
            guard hole - pressStartHole < lastPress.matchStatusArray.count else { return total }
            return total + lastPress.matchStatusArray[hole - pressStartHole]
        }
        
        print("Cumulative Press Score: \(cumulativePressScore)")
        
        if cumulativePressScore > 0 {
            return (golfer1, golfer2, cumulativePressScore)
        } else if cumulativePressScore < 0 {
            return (golfer2, golfer1, -cumulativePressScore)
        } else {
            return (nil, nil, 0)  // All square
        }
    } else {
        // If no presses, return main match status
        if matchScore > 0 {
            return (golfer1, golfer2, matchScore)
        } else if matchScore < 0 {
            return (golfer2, golfer1, -matchScore)
        } else {
            return (nil, nil, 0)  // All square
        }
    }
}
    
    func forceUIUpdate() {
        objectWillChange.send()
    }

    func updateFinalMatchStatus() {
        // Update main match status
        updateMatchStatus(for: 18)
        
        // If the main match ended with a "&0" score, update it
        if let score = winningScore, score.hasSuffix("&0") {
            winningScore = formatWinningScore(score)
            matchPlayStatus = "\(matchWinner!) won \(winningScore!)"
        }
        
        // Update and finalize all presses
        for index in presses.indices {
            updatePressMatchStatus(pressIndex: index, for: 18)
            
            let press = presses[index]
            let pressScore = press.matchStatusArray.reduce(0, +)
            
            if pressScore == 0 && press.winner == nil {
                presses[index].winner = "Tie"
                presses[index].winningScore = "All Square"
                pressStatuses[index] = "Press \(index + 1) ended All Square"
            } else if let score = press.winningScore, score.hasSuffix("&0") {
                // Update press status if it ended with a "&0" score
                presses[index].winningScore = formatWinningScore(score)
                pressStatuses[index] = "Press \(index + 1): \(press.winner ?? "Unknown") won \(presses[index].winningScore ?? "Unknown")"
            }
        }
        
        forceUIUpdate()
    }
}