import Foundation

struct BlindDrawBetterBallModel {
    static func initializeBlindDrawBetterBall(roundViewModel: RoundViewModel) {
        guard roundViewModel.isBlindDrawBetterBall else {
            print("Debug: BlindDrawBetterBallModel - Blind Draw Better Ball is not enabled")
            return
        }
        
        print("Debug: BlindDrawBetterBallModel - Initializing Blind Draw Better Ball")
        
        let numberOfHoles = getNumberOfHoles(for: roundViewModel.roundType)
        roundViewModel.blindDrawBetterBallMatchArray = Array(repeating: 0, count: numberOfHoles)
        roundViewModel.blindDrawBetterBallMatchStatus = "All Square"
        
        // Calculate Blind Draw Better Ball stroke holes
        calculateBlindDrawBetterBallStrokeHoles(roundViewModel: roundViewModel)
        
        // Initialize other necessary properties
        roundViewModel.blindDrawBetterBallHoleTallies = [:]
        roundViewModel.blindDrawBetterBallTalliedHoles = []
        roundViewModel.blindDrawBetterBallHoleWinners = [:]
        roundViewModel.blindDrawBetterBallNetScores = [:]
        
        if let (teamA, teamB) = getTeams(roundViewModel: roundViewModel) {
            print("Team A: \(teamA.map { "\($0.firstName) \($0.lastName)" })")
            print("Team B: \(teamB.map { "\($0.firstName) \($0.lastName)" })")
        } else {
            print("Error: Blind Draw Better Ball teams not properly set")
        }
    }
    
    static func getTeams(roundViewModel: RoundViewModel) -> ([Golfer], [Golfer])? {
        guard !roundViewModel.blindDrawBetterBallTeamAssignments.isEmpty else {
            print("Debug: getTeams - blindDrawBetterBallTeamAssignments is empty")
            return nil
        }
        
        var teamA: [Golfer] = []
        var teamB: [Golfer] = []
        
        for golfer in roundViewModel.golfers {
            if let assignment = roundViewModel.blindDrawBetterBallTeamAssignments[golfer.id] {
                switch assignment {
                case "Team A": teamA.append(golfer)
                case "Team B": teamB.append(golfer)
                default: break
                }
            } else {
                print("Debug: getTeams - No assignment found for golfer: \(golfer.firstName) \(golfer.lastName)")
            }
        }
        
        // Ensure at least one player in each team
        guard !teamA.isEmpty && !teamB.isEmpty else { return nil }
        
        return (teamA, teamB)
    }
    
    static func updateBlindDrawBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        let isStrokeHole = roundViewModel.blindDrawBetterBallStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        let blindDrawBetterBallNetScore = isStrokeHole ? scoreInt - 1 : scoreInt
        
        roundViewModel.blindDrawBetterBallNetScores[currentHoleNumber, default: [:]][golferId] = blindDrawBetterBallNetScore
        
        // Update tallies
        updateBlindDrawBetterBallTallies(roundViewModel: roundViewModel, for: currentHoleNumber)
    }
    
    static func updateBlindDrawBetterBallTallies(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        guard let (teamA, teamB) = getTeams(roundViewModel: roundViewModel) else {
            return
        }
        
        let teamAScores = calculateTeamScore(roundViewModel: roundViewModel, team: teamA, for: currentHoleNumber)
        let teamBScores = calculateTeamScore(roundViewModel: roundViewModel, team: teamB, for: currentHoleNumber)
        updateTally(roundViewModel: roundViewModel, teamAScores: teamAScores, teamBScores: teamBScores, currentHoleNumber: currentHoleNumber)
        
        roundViewModel.blindDrawBetterBallTalliedHoles.insert(currentHoleNumber)
    }
    
    private static func updateTally(roundViewModel: RoundViewModel, teamAScores: [Int], teamBScores: [Int], currentHoleNumber: Int) {
        let comparison = compareTeamScores(teamAScores: teamAScores, teamBScores: teamBScores, scoresToUse: roundViewModel.blindDrawScoresToUse)
        
        if comparison < 0 {
            roundViewModel.blindDrawBetterBallHoleTallies["Team A", default: 0] += 1
            roundViewModel.blindDrawBetterBallHoleWinners[currentHoleNumber] = "Team A"
        } else if comparison > 0 {
            roundViewModel.blindDrawBetterBallHoleTallies["Team B", default: 0] += 1
            roundViewModel.blindDrawBetterBallHoleWinners[currentHoleNumber] = "Team B"
        } else {
            roundViewModel.blindDrawBetterBallHoleTallies["Halved", default: 0] += 1
            roundViewModel.blindDrawBetterBallHoleWinners[currentHoleNumber] = "Halved"
        }
        
        print("Team A scores: \(teamAScores) || Team B scores: \(teamBScores)")
    }
    
    static func resetBlindDrawBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int) {
        roundViewModel.blindDrawBetterBallNetScores[currentHoleNumber, default: [:]][golferId] = nil
        roundViewModel.blindDrawBetterBallHoleWinners[currentHoleNumber] = nil
        resetBlindDrawBetterBallTallyForHole(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
    }
    
    static func updateBlindDrawBetterBallMatchStatus(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        roundViewModel.currentHole = currentHoleNumber
        guard roundViewModel.isBlindDrawBetterBall else { return }
        
        let startingHole = getStartingHole(for: roundViewModel.roundType)
        let lastHole = getLastHole(for: roundViewModel.roundType)
        let totalHoles = getNumberOfHoles(for: roundViewModel.roundType)
        
        // Reset match status arrays if recalculating from the first hole
        if currentHoleNumber == startingHole {
            roundViewModel.blindDrawBetterBallMatchArray = Array(repeating: 0, count: totalHoles)
            roundViewModel.blindDrawBetterBallMatchWinner = nil
            roundViewModel.blindDrawBetterBallWinningScore = nil
            roundViewModel.blindDrawBetterBallMatchWinningHole = nil
        }

        let lastHoleToUpdate = min(currentHoleNumber, lastHole)
        
        // Update match status for each hole up to the last hole to update
        for hole in startingHole...lastHoleToUpdate {
            updateMatchArrays(roundViewModel: roundViewModel, hole: hole, startingHole: startingHole)
        }
        
        // Calculate and update match status
        updateMatchStatus(roundViewModel: roundViewModel, currentHoleNumber: currentHoleNumber, startingHole: startingHole, lastHole: lastHole, totalHoles: totalHoles)
        
        // Update press statuses
//        BlindDrawBetterBallPressModel.updateAllBlindDrawBetterBallPressStatuses(roundViewModel: roundViewModel, for: currentHoleNumber)
        
        print("Debug: Blin Draw Better Ball Model updateBlindDrawBetterBallMatchStatus() - Updated match status for hole \(currentHoleNumber)")
        print("Blind Draw Better Ball Match Status: \(roundViewModel.blindDrawBetterBallMatchStatus ?? "N/A")")
        
        roundViewModel.objectWillChange.send()
    }
    
    private static func updateMatchArrays(roundViewModel: RoundViewModel, hole: Int, startingHole: Int) {
        let index = hole - startingHole
        if let winner = roundViewModel.blindDrawBetterBallHoleWinners[hole] {
            roundViewModel.blindDrawBetterBallMatchArray[index] = winner == "Team A" ? 1 : (winner == "Team B" ? -1 : 0)
        }
    }
    
    private static func updateMatchStatus(roundViewModel: RoundViewModel, currentHoleNumber: Int, startingHole: Int, lastHole: Int, totalHoles: Int) {
        let matchArray = roundViewModel.blindDrawBetterBallMatchArray
        let matchScore = matchArray[0..<(currentHoleNumber - startingHole + 1)].reduce(0, +)
        let holesPlayed = currentHoleNumber - startingHole + 1
        let remainingHoles = totalHoles - holesPlayed
        
        // Check for match win conditions
        if abs(matchScore) > remainingHoles {
            setMatchResult(roundViewModel: roundViewModel, winner: matchScore > 0 ? "Team A" : "Team B", score: "\(abs(matchScore))&\(remainingHoles)", winningHole: currentHoleNumber)
        } else if currentHoleNumber == lastHole {
            if matchScore != 0 {
                setMatchResult(roundViewModel: roundViewModel, winner: matchScore > 0 ? "Team A" : "Team B", score: "1UP", winningHole: lastHole)
            } else {
                setMatchResult(roundViewModel: roundViewModel, winner: "Tie", score: "All Square", winningHole: lastHole)
            }
        } else {
            updateOngoingMatchStatus(roundViewModel: roundViewModel, matchScore: matchScore, holesPlayed: holesPlayed, remainingHoles: remainingHoles)
        }
    }
    
    private static func setMatchResult(roundViewModel: RoundViewModel, winner: String, score: String, winningHole: Int) {
        roundViewModel.blindDrawBetterBallMatchWinner = winner
        roundViewModel.blindDrawBetterBallWinningScore = formatBlindDrawBetterBallWinningScore(score)
        roundViewModel.blindDrawBetterBallMatchWinningHole = winningHole
        roundViewModel.blindDrawBetterBallMatchStatus = "\(winner) won \(roundViewModel.blindDrawBetterBallWinningScore!)"
    }
    
    private static func updateOngoingMatchStatus(roundViewModel: RoundViewModel, matchScore: Int, holesPlayed: Int, remainingHoles: Int) {
        let status: String
        if matchScore == 0 {
            status = "All Square thru \(holesPlayed)"
        } else {
            let leadingTeam = matchScore > 0 ? "Team A" : "Team B"
            let absScore = abs(matchScore)
            if absScore == remainingHoles {
                status = "\(leadingTeam) \(absScore)UP with \(remainingHoles) to play (Dormie)"
            } else {
                status = "\(leadingTeam) \(absScore)UP thru \(holesPlayed)"
            }
        }
        
        roundViewModel.blindDrawBetterBallMatchStatus = status
    }
    
    static func recalculateBlindDrawBetterBallTallies(roundViewModel: RoundViewModel, upToHole: Int) {
        guard roundViewModel.isBlindDrawBetterBall, getTeams(roundViewModel: roundViewModel) != nil else {
            print("Error: Blind Draw Better Ball not active or teams not set")
            return
        }
        
        roundViewModel.blindDrawBetterBallHoleTallies = [:]
        roundViewModel.blindDrawBetterBallTalliedHoles = []
        let totalHoles = getNumberOfHoles(for: roundViewModel.roundType)
        roundViewModel.blindDrawBetterBallMatchArray = Array(repeating: 0, count: totalHoles)
        
        for holeNumber in getStartingHole(for: roundViewModel.roundType)...upToHole {
            updateBlindDrawBetterBallTallies(roundViewModel: roundViewModel, for: holeNumber)
            updateBlindDrawBetterBallMatchStatus(roundViewModel: roundViewModel, for: upToHole)
        }
        
        print("Debug: BlindDrawBetterBallModel recalculateBlindDrawBetterBallTallies() - Recalculated tallies up to hole \(upToHole)")
        print("Blind Draw Better Ball Match Array: \(roundViewModel.blindDrawBetterBallMatchArray)")
        print("Blind Draw Better Ball Match Status: \(roundViewModel.blindDrawBetterBallMatchStatus ?? "N/A")")
    }
    
    static func updateFinalBlindDrawBetterBallMatchStatus(roundViewModel: RoundViewModel) {
        print("Debug: BlindDrawBetterBallModel updateFinalBlindDrawBetterBallMatchStatus()")
        let lastHole = getLastHole(for: roundViewModel.roundType)
        updateBlindDrawBetterBallMatchStatus(roundViewModel: roundViewModel, for: lastHole)
        
        updateFinalMatchStatus(roundViewModel: roundViewModel)
        
        // Calculate final team scores
        calculateFinalScores(roundViewModel: roundViewModel)
        
        roundViewModel.forceUIUpdate()
    }
    
    private static func updateFinalMatchStatus(roundViewModel: RoundViewModel) {
        let score = roundViewModel.blindDrawBetterBallWinningScore
        let winner = roundViewModel.blindDrawBetterBallMatchWinner
        
        if let score = score, score.hasSuffix("&0") {
            let updatedScore = formatBlindDrawBetterBallWinningScore(score)
            roundViewModel.blindDrawBetterBallWinningScore = updatedScore
            roundViewModel.blindDrawBetterBallMatchStatus = "\(winner!) won \(updatedScore)"
        }
    }
    
    private static func calculateFinalScores(roundViewModel: RoundViewModel) {
        let teamAScore = roundViewModel.blindDrawBetterBallMatchArray.filter { $0 > 0 }.count
        let teamBScore = roundViewModel.blindDrawBetterBallMatchArray.filter { $0 < 0 }.count
        let halvedHoles = roundViewModel.blindDrawBetterBallMatchArray.filter { $0 == 0 }.count
        
        let finalStats = [
            "Team A Wins": teamAScore,
            "Team B Wins": teamBScore,
            "Halved Holes": halvedHoles
        ]
        
        roundViewModel.blindDrawBetterBallFinalStatistics = finalStats
        
        print("Debug: Final Blind Draw Better Ball Scores - Team A: \(teamAScore), Team B: \(teamBScore), Halved: \(halvedHoles)")
        print("Debug: Final Blind Draw Better Ball Match Status - \(roundViewModel.blindDrawBetterBallMatchStatus ?? "Unknown")")
        print("Debug: Final Blind Draw Better Ball Statistics - \(roundViewModel.blindDrawBetterBallFinalStatistics)")
    }
    
    static func formatBlindDrawBetterBallWinningScore(_ score: String) -> String {
        if score.hasSuffix("&0") {
            let leadNumber = score.split(separator: "&")[0]
            return "\(leadNumber)UP"
        }
        return score
    }
    
    static func resetBlindDrawBetterBallTallyForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        let index = holeNumber - getStartingHole(for: roundViewModel.roundType)
        roundViewModel.blindDrawBetterBallMatchArray[index] = 0
        roundViewModel.blindDrawBetterBallHoleWinners[holeNumber] = nil
    }
    
    static func calculateBlindDrawBetterBallStrokeHoles(roundViewModel: RoundViewModel) {
        guard let (teamA, teamB) = getTeams(roundViewModel: roundViewModel) else {
            print("Error: Blind Draw Better Ball teams not set")
            return
        }
        
        let allPlayers = teamA + teamB
        let lowestHandicapPlayer = allPlayers.min { roundViewModel.courseHandicaps[$0.id] ?? 0 < roundViewModel.courseHandicaps[$1.id] ?? 0 }
        let lowestHandicap = roundViewModel.courseHandicaps[lowestHandicapPlayer?.id ?? ""] ?? 0
        
        for player in allPlayers {
            let playerHandicap = roundViewModel.courseHandicaps[player.id] ?? 0
            let blindDrawBetterBallHandicap = max(0, playerHandicap - lowestHandicap)
            
            if let playerStrokeHoles = roundViewModel.strokeHoles[player.id] {
                roundViewModel.blindDrawBetterBallStrokeHoles[player.id] = Array(playerStrokeHoles.prefix(blindDrawBetterBallHandicap))
            }
            
            print("Debug: Blind Draw Better Ball Stroke Holes for \(player.firstName) \(player.lastName): \(roundViewModel.blindDrawBetterBallStrokeHoles[player.id] ?? [])")
        }
    }
    
    private static func calculateTeamScore(roundViewModel: RoundViewModel, team: [Golfer], for holeNumber: Int) -> [Int] {
        let scores = team.compactMap { roundViewModel.blindDrawBetterBallNetScores[holeNumber]?[$0.id] }
        return scores.sorted()  // Return sorted scores (lowest to highest)
    }

    private static func compareTeamScores(teamAScores: [Int], teamBScores: [Int], scoresToUse: Int) -> Int {
        let sortedA = teamAScores.sorted()
        let sortedB = teamBScores.sorted()
    
        for i in 0..<min(scoresToUse, min(sortedA.count, sortedB.count)) {
            if sortedA[i] < sortedB[i] {
                return -1  // Team A wins
            } else if sortedB[i] < sortedA[i] {
                return 1   // Team B wins
            }
        }
    
        // If we've reached this point and scoresToUse > 1, it means the first scores were tied
        // and we need to check the next score (if available) as a tiebreaker
        if scoresToUse > 1 && sortedA.count > 1 && sortedB.count > 1 {
            if sortedA[1] < sortedB[1] {
                return -1  // Team A wins the tiebreaker
            } else if sortedB[1] < sortedA[1] {
                return 1   // Team B wins the tiebreaker
            }
        }
    
        return 0  // Tie (either because scoresToUse is 1 or because even the tiebreaker was tied)
    }

    static func getLastHole(for roundType: RoundType) -> Int {
        switch roundType {
        case .full18, .back9:
            return 18
        case .front9:
            return 9
        }
    }

    static func getNumberOfHoles(for roundType: RoundType) -> Int {
        switch roundType {
        case .full18:
            return 18
        case .front9, .back9:
            return 9
        }
    }

    static func getStartingHole(for roundType: RoundType) -> Int {
        switch roundType {
        case .full18, .front9:
            return 1
        case .back9:
            return 10
        }
    }
}
