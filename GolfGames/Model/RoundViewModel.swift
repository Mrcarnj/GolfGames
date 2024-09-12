
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
    @Published var roundType: RoundType = .full18
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
    @Published var lastUpdatedHole: Int = 0
    @Published var talliedHoles: Set<Int> = []
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
    @Published var matchPlayHandicaps: [String: Int] = [:]
    @Published var isBetterBall: Bool = false
    @Published var betterBallMatchArray: [Int] = Array(repeating: 0, count: 18)
    @Published var betterBallFinalMatchArray: [Int]?
    @Published var betterBallMatchStatus: String?
    @Published var betterBallTeamAssignments: [String: String] = [:]
    @Published var betterBallNetScores: [Int: [String: Int]] = [:]
    @Published var betterBallHoleWinners: [Int: String] = [:]
    @Published var betterBallHoleTallies: [String: Int] = [:]
    @Published var betterBallMatchScore: Int = 0
    @Published var betterBallMatchWinner: String?
    @Published var betterBallWinningScore: String?
    @Published var betterBallMatchWinningHole: Int?
    @Published var betterBallHandicaps: [String: Int] = [:]
    @Published var betterBallFinalStatistics: [String: Int] = [:]
    @Published var betterBallStrokeHoles: [String: [Int]] = [:]
    @Published var betterBallTalliedHoles: Set<Int> = []
    @Published var betterBallPresses: [(startHole: Int, matchStatusArray: [Int], winner: String?, winningScore: String?, winningHole: Int?)] = []
    @Published var betterBallPressStatuses: [String] = []
    @Published var betterBallCurrentPressStartHole: Int?
    @Published var isNinePoint: Bool = false
    @Published var ninePointScores: [Int: [String: Int]] = [:]
    @Published var ninePointTotalScores: [String: Int] = [:]
    @Published var ninePointStrokeHoles: [String: [Int]] = [:]
    @Published var isStablefordGross: Bool = false
    @Published var stablefordGrossScores: [Int: [String: Int]] = [:]
    @Published var stablefordGrossQuotas: [String: Int] = [:]
    @Published var stablefordGrossTotalScores: [String: Int] = [:]
    @Published var birdieCount: [String: Int] = [:]
    @Published var eagleOrBetterCount: [String: Int] = [:]
    @Published var parCount: [String: Int] = [:]
    @Published var bogeyCount: [String: Int] = [:]
    @Published var doubleBogeyPlusCount: [String: Int] = [:]

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
        
        self.golfers = [Golfer(id: user.id, firstName: user.firstName, lastName: user.lastName, handicap: user.handicap ?? 0.0)] + additionalGolfers
        print("Golfers for this round: \(self.golfers.map { $0.formattedName(golfers: self.golfers) })")
        
        let roundGolfers = self.golfers.map { golfer in
            Round.Golfer(id: golfer.id, firstName: golfer.firstName, lastName: golfer.lastName, handicap: golfer.handicap)
        }
        
        let round = Round(
            courseId: courseId,
            courseName: course.name,
            teeName: tee.tee_name,
            golfers: roundGolfers,
            date: Date(),
            roundType: self.roundType
        )
        
        if isMatchPlay && golfers.count >= 2 {
            MatchPlayModel.initializeMatchPlay(roundViewModel: self)
        }

        if isBetterBall && golfers.count >= 2 {
        BetterBallModel.initializeBetterBall(roundViewModel: self)
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
        
        // Initialize currentHoleIndex based on roundType
        self.currentHole = (self.roundType == .back9) ? 10 : 1
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
    
    func printDebugInfo() {
        print("RoundViewModel Debug Info:")
        print("Number of golfers: \(golfers.count)")
        print("Golfers: \(golfers.map { "\($0.firstName) \($0.lastName)" })")
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

 ////////////////// STROKES //////////////////

    func getHoleHandicap(for hole: Int, teeId: String) -> Int {
        return StrokesModel.getHoleHandicap(roundViewModel: self, for: hole, teeId: teeId)
    }

func calculateStrokePlayStrokeHoles(holes: [Hole]) {
        StrokesModel.calculateStrokePlayStrokeHoles(roundViewModel: self, holes: holes)
    }

 ////////////////// SCORING //////////////////

    func updateStrokePlayNetScores() {
        ScoringModel.updateStrokePlayNetScores(roundViewModel: self)
    }
    
    func resetScoresForCurrentHole() {
        ScoringModel.resetScoresForCurrentHole(roundViewModel: self)
    }
    
    func nextHole() {
        ScoringModel.nextHole(roundViewModel: self)
    }
    
    func previousHole() {
        ScoringModel.previousHole(roundViewModel: self)
    }
    
    func saveScores() {
        ScoringModel.saveScores(roundViewModel: self)
    }
    
    func getMissingScores(for golferId: String) -> [Int] {
        return ScoringModel.getMissingScores(roundViewModel: self, for: golferId)
    }
    
    func allScoresEntered(for holeNumber: Int? = nil) -> Bool {
        return ScoringModel.allScoresEntered(roundViewModel: self, for: holeNumber)
    }
    
    func updateScore(for hole: Int, golferId: String, score: Int) {
        ScoringModel.updateScore(roundViewModel: self, for: hole, golferId: golferId, score: score)
        
        let lastHole = (roundType == .front9) ? 9 : 18
        if hole == lastHole {
            updateFinalMatchStatus()
        }
    }
    
////////////////// MATCH PLAY //////////////////


    func initializeMatchPlay() {
        MatchPlayModel.initializeMatchPlay(roundViewModel: self)
    }
    
    func updateTallies(for holeNumber: Int) {
        MatchPlayModel.updateTallies(roundViewModel: self, for: holeNumber)
    }
    
    func resetTallyForHole(_ holeNumber: Int) {
        MatchPlayModel.resetTallyForHole(roundViewModel: self, holeNumber: holeNumber)
    }
    
    func formatWinningScore(_ score: String) -> String {
        MatchPlayModel.formatWinningScore(score)
    }

    func updateMatchStatus(for currentHoleNumber: Int) {
        MatchPlayModel.updateMatchStatus(roundViewModel: self, for: currentHoleNumber)
    }
    
    func setMatchPlayGolfers(golfer1: Golfer, golfer2: Golfer) {
        MatchPlayModel.setMatchPlayGolfers(roundViewModel: self, golfer1: golfer1, golfer2: golfer2)
    }

    func updateFinalMatchStatus() {
        MatchPlayModel.updateFinalMatchStatus(roundViewModel: self)
    }
    
////////////////// PRESSES //////////////////


    func updateAllPressStatuses(for currentHoleNumber: Int) {
        MatchPlayPressModel.updateAllPressStatuses(roundViewModel: self, for: currentHoleNumber)
    }
    
    func calculatePressStatus(pressIndex: Int, currentHole: Int) -> String {
        MatchPlayPressModel.calculatePressStatus(roundViewModel: self, pressIndex: pressIndex, currentHole: currentHole)
    }
    
    func updatePressMatchStatus(pressIndex: Int, for currentHoleNumber: Int) {
        MatchPlayPressModel.updatePressMatchStatus(roundViewModel: self, pressIndex: pressIndex, for: currentHoleNumber)
    }
    
    func initiatePress(atHole: Int) {
        MatchPlayPressModel.initiatePress(roundViewModel: self, atHole: atHole)
    }
    
    func getLosingPlayer() -> Golfer? {
        MatchPlayPressModel.getLosingPlayer(roundViewModel: self)
    }
    
    func getCurrentPressStatus() -> (leadingPlayer: Golfer?, trailingPlayer: Golfer?, score: Int)? {
        MatchPlayPressModel.getCurrentPressStatus(roundViewModel: self)
}
////////////////// BETTER BALL //////////////////
    func setBetterBallTeams(_ assignments: [String: String]) {
    self.betterBallTeamAssignments = assignments
    isBetterBall = true
    isMatchPlay = false
    print("Debug: RoundViewModel setBetterBallTeams() - Assignments: \(assignments)")
    print("Debug: RoundViewModel setBetterBallTeams() - Course Handicaps: \(courseHandicaps)")
    
    // Don't initialize here, we'll do it after course handicaps are set
    objectWillChange.send()
}

func initializeBetterBallAfterHandicapsSet() {
    guard isBetterBall, !courseHandicaps.isEmpty else { return }
    
    print("Debug: RoundViewModel initializeBetterBallAfterHandicapsSet() - Initializing Better Ball")
    BetterBallModel.initializeBetterBall(roundViewModel: self)
}
    
    func updateBetterBallScore(for golferId: String, currentHoleNumber: Int, score: Int) {
        BetterBallModel.updateBetterBallScore(roundViewModel: self, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: score)
    }
    
    func updateBetterBallTallies(for holeNumber: Int) {
        BetterBallModel.updateBetterBallTallies(roundViewModel: self, for: holeNumber)
    }
    
    func resetBetterBallScore(for golferId: String, currentHoleNumber: Int) {
        BetterBallModel.resetBetterBallScore(roundViewModel: self, golferId: golferId, currentHoleNumber: currentHoleNumber)
    }
    
    func updateBetterBallMatchStatus(for currentHoleNumber: Int) {
        BetterBallModel.updateBetterBallMatchStatus(roundViewModel: self, for: currentHoleNumber)
    }
    
    func recalculateBetterBallTallies(upToHole: Int) {
        BetterBallModel.recalculateBetterBallTallies(roundViewModel: self, upToHole: upToHole)
    }
    
    func updateFinalBetterBallMatchStatus() {
        BetterBallModel.updateFinalBetterBallMatchStatus(roundViewModel: self)
    }

////////////////// BETTER BALL PRESSES //////////////////

func updateAllBetterBallPressStatuses(for currentHoleNumber: Int) {
    BetterBallPressModel.updateAllBetterBallPressStatuses(roundViewModel: self, for: currentHoleNumber)
}

func calculateBetterBallPressStatus(pressIndex: Int, currentHole: Int) -> String {
    BetterBallPressModel.calculateBetterBallPressStatus(roundViewModel: self, pressIndex: pressIndex, currentHole: currentHole)
}

func updateBetterBallPressMatchStatus(pressIndex: Int, for currentHoleNumber: Int) {
    BetterBallPressModel.updateBetterBallPressMatchStatus(roundViewModel: self, pressIndex: pressIndex, for: currentHoleNumber)
}

func initiateBetterBallPress(atHole: Int) {
    BetterBallPressModel.initiateBetterBallPress(roundViewModel: self, atHole: atHole)
}

func getLosingBetterBallTeam() -> String? {
    BetterBallPressModel.getLosingTeam(roundViewModel: self)
}

func getCurrentBetterBallPressStatus() -> (leadingTeam: String?, trailingTeam: String?, score: Int)? {
    BetterBallPressModel.getCurrentBetterBallPressStatus(roundViewModel: self)
}

////////////////// 9 POINT  //////////////////
func initializeNinePoint() {
    NinePointModel.initializeNinePoint(roundViewModel: self)
}

func updateNinePointScore(for holeNumber: Int) {
    NinePointModel.updateNinePointScore(roundViewModel: self, holeNumber: holeNumber)
}

func resetNinePointScore(for holeNumber: Int) {
    NinePointModel.resetNinePointScore(roundViewModel: self, holeNumber: holeNumber)
}

    //////////////////STABLEFORD - GROSS  //////////////////
    func initializeStablefordGross(quotas: [String: Int]) {
        StablefordGrossModel.initializeStablefordGross(roundViewModel: self, quotas: quotas)
    }

    func updateStablefordGrossScore(for holeNumber: Int) {
        StablefordGrossModel.updateStablefordGrossScore(roundViewModel: self, holeNumber: holeNumber)
    }

    func recalculateStablefordGrossScores(upToHole: Int) {
        StablefordGrossModel.recalculateStablefordGrossScores(roundViewModel: self, upToHole: upToHole)
    }

    func resetStablefordGrossScore(for holeNumber: Int) {
        StablefordGrossModel.resetStablefordGrossScore(roundViewModel: self, holeNumber: holeNumber)
    }

    func displayStablefordGrossFinalResults() -> String {
        return StablefordGrossModel.displayFinalResults(roundViewModel: self)
    }

////////////////// CLEAR ROUND DATA //////////////////

func clearRoundData() {
    print("Clearing round data...")
    
    // Reset basic round information
    roundId = nil
    selectedCourse = nil
    selectedTee = nil
    selectedLocation = nil
    golfers = []
    currentHole = 1
    roundType = .full18
    selectedScorecardType = .strokePlay
    
    // Clear scores and pars
    grossScores = [:]
    netStrokePlayScores = [:]
    pars = [:]
    courseHandicaps = [:]
    strokeHoles = [:]

    // Clear stats
    eagleOrBetterCount = [:]
    birdieCount = [:]
    parCount = [:]
    bogeyCount = [:]
    doubleBogeyPlusCount = [:]
    
    // Clear Match Play data
    isMatchPlay = false
    matchPlayStatus = nil
    matchPlayStrokeHoles = [:]
    matchPlayHandicap = 0
    matchPlayNetScores = [:]
    previousHoleWinner = nil
    holeWinners = [:]
    holeTallies = [:]
    matchScore = 0
    holesPlayed = 0
    lastUpdatedHole = 0
    talliedHoles = []
    matchWinner = nil
    winningScore = nil
    matchStatus = [:]
    matchStatusArray = Array(repeating: 0, count: 18)
    finalMatchStatusArray = nil
    matchWinningHole = nil
    matchPlayGolfers = nil
    matchPlayHandicaps = [:]
    
    // Clear Match Play Presses
    presses = []
    pressStatuses = []
    currentPressStartHole = nil
    
    // Clear Better Ball data
    isBetterBall = false
    betterBallMatchArray = Array(repeating: 0, count: 18)
    betterBallFinalMatchArray = nil
    betterBallMatchStatus = nil
    betterBallTeamAssignments = [:]
    betterBallNetScores = [:]
    betterBallHoleWinners = [:]
    betterBallHoleTallies = [:]
    betterBallMatchScore = 0
    betterBallMatchWinner = nil
    betterBallWinningScore = nil
    betterBallMatchWinningHole = nil
    betterBallHandicaps = [:]
    betterBallFinalStatistics = [:]
    betterBallStrokeHoles = [:]
    betterBallTalliedHoles = []
    
    // Clear Better Ball Presses
    betterBallPresses = []
    betterBallPressStatuses = []
    betterBallCurrentPressStartHole = nil
    
    // Clear Nine Point data
    isNinePoint = false
    ninePointScores = [:]
    ninePointTotalScores = [:]
    ninePointStrokeHoles = [:]
    
    print("Round data cleared successfully.")
    objectWillChange.send()
}

    func forceUIUpdate() {
        objectWillChange.send()
    }

    func getStartingHoleNumber() -> Int {
    switch roundType {
    case .full18, .front9:
        return 1
    case .back9:
        return 10
    }
}

    func updateStats(for golferId: String, score: Int, par: Int) {
    let scoreDiff = score - par
    print("Debug: Updating stats for golfer \(golferId) - Score: \(score), Par: \(par), Diff: \(scoreDiff)")
    switch scoreDiff {
    case ...(-2):
        eagleOrBetterCount[golferId, default: 0] += 1
        print("Debug: Eagle or better recorded")
    case -1:
        birdieCount[golferId, default: 0] += 1
        print("Debug: Birdie recorded")
    case 0:
        parCount[golferId, default: 0] += 1
        print("Debug: Par recorded")
    case 1:
        bogeyCount[golferId, default: 0] += 1
        print("Debug: Bogey recorded")
    case 2...:
        doubleBogeyPlusCount[golferId, default: 0] += 1
        print("Debug: Double bogey or worse recorded")
    default:
        print("Debug: Invalid score difference")
    }
}
}

extension RoundViewModel {
    var betterBallPressesUpdateTrigger: Int {
        betterBallPresses.reduce(0) { $0 + $1.matchStatusArray.reduce(0, +) }
    }
}
