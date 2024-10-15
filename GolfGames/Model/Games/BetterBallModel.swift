import Foundation

struct BetterBallModel {
    static func initializeBetterBall(roundViewModel: RoundViewModel) {
        guard roundViewModel.isBetterBall else {
            print("Debug: BetterBallModel - Better Ball is not enabled")
            return
        }
        
        print("Debug: BetterBallModel - Initializing Better Ball")
        
        let numberOfHoles = getNumberOfHoles(for: roundViewModel.roundType)
        roundViewModel.betterBallMatchArray = Array(repeating: 0, count: numberOfHoles)
        roundViewModel.betterBallMatchArrayCD = Array(repeating: 0, count: numberOfHoles)
        roundViewModel.betterBallMatchStatus = "All Square"
        roundViewModel.betterBallMatchStatusCD = "All Square"
        
        // Calculate Better Ball stroke holes
        calculateBetterBallStrokeHoles(roundViewModel: roundViewModel)
        
        // Initialize other necessary properties
        roundViewModel.betterBallHoleTallies = [:]
        roundViewModel.betterBallTalliedHoles = []
        roundViewModel.betterBallHoleWinners = [:]
        roundViewModel.betterBallHoleWinnersCD = [:]
        roundViewModel.betterBallNetScores = [:]
        
        if let (teamA, teamB, teamC, teamD) = getTeams(roundViewModel: roundViewModel) {
            print("Team A: \(teamA.map { "\($0.firstName) \($0.lastName)" })")
            print("Team B: \(teamB.map { "\($0.firstName) \($0.lastName)" })")
            if !teamC.isEmpty && !teamD.isEmpty {
                print("Team C: \(teamC.map { "\($0.firstName) \($0.lastName)" })")
                print("Team D: \(teamD.map { "\($0.firstName) \($0.lastName)" })")
            }
        } else {
            print("Error: Better Ball teams not properly set")
        }
    }
    
    static func getTeams(roundViewModel: RoundViewModel) -> ([Golfer], [Golfer], [Golfer], [Golfer])? {
        guard !roundViewModel.betterBallTeamAssignments.isEmpty else {
            print("Debug: getTeams - betterBallTeamAssignments is empty")
            return nil
        }
        
        var teamA: [Golfer] = []
        var teamB: [Golfer] = []
        var teamC: [Golfer] = []
        var teamD: [Golfer] = []
        
        for golfer in roundViewModel.golfers {
            if let assignment = roundViewModel.betterBallTeamAssignments[golfer.id] {
                switch assignment {
                case "Team A": teamA.append(golfer)
                case "Team B": teamB.append(golfer)
                case "Team C": teamC.append(golfer)
                case "Team D": teamD.append(golfer)
                default: break
                }
            } else {
                print("Debug: getTeams - No assignment found for golfer: \(golfer.firstName) \(golfer.lastName)")
            }
        }
        
        // Ensure at least one player in each team for A vs B
        guard !teamA.isEmpty && !teamB.isEmpty else { return nil }
        
        // For C vs D, both teams must have players or both must be empty
        if (teamC.isEmpty && !teamD.isEmpty) || (!teamC.isEmpty && teamD.isEmpty) {
            return nil
        }
        
        return (teamA, teamB, teamC, teamD)
    }
    
    static func updateBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        let isStrokeHole = roundViewModel.betterBallStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        let betterBallNetScore = isStrokeHole ? scoreInt - 1 : scoreInt
        
        roundViewModel.betterBallNetScores[currentHoleNumber, default: [:]][golferId] = betterBallNetScore
        
        // Update tallies for both matches
        updateBetterBallTallies(roundViewModel: roundViewModel, for: currentHoleNumber)
    }
    
    static func updateBetterBallTallies(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        guard let (teamA, teamB, teamC, teamD) = getTeams(roundViewModel: roundViewModel) else {
            return
        }
        
        // Update for A vs B
        if let teamAScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamA, for: currentHoleNumber),
           let teamBScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamB, for: currentHoleNumber) {
            updateTally(roundViewModel: roundViewModel, teamAScore: teamAScore, teamBScore: teamBScore, currentHoleNumber: currentHoleNumber, isCD: false)
        }
        
        // Update for C vs D if teams exist
        if !teamC.isEmpty && !teamD.isEmpty,
           let teamCScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamC, for: currentHoleNumber),
           let teamDScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamD, for: currentHoleNumber) {
            updateTally(roundViewModel: roundViewModel, teamAScore: teamCScore, teamBScore: teamDScore, currentHoleNumber: currentHoleNumber, isCD: true)
        }
        
        roundViewModel.betterBallTalliedHoles.insert(currentHoleNumber)
    }
    
    private static func updateTally(roundViewModel: RoundViewModel, teamAScore: Int, teamBScore: Int, currentHoleNumber: Int, isCD: Bool) {
        let prefix = isCD ? "CD_" : ""
        if teamAScore < teamBScore {
            roundViewModel.betterBallHoleTallies["\(prefix)Team A", default: 0] += 1
            if isCD {
                roundViewModel.betterBallHoleWinnersCD[currentHoleNumber] = "Team C"
            } else {
                roundViewModel.betterBallHoleWinners[currentHoleNumber] = "Team A"
            }
        } else if teamBScore < teamAScore {
            roundViewModel.betterBallHoleTallies["\(prefix)Team B", default: 0] += 1
            if isCD {
                roundViewModel.betterBallHoleWinnersCD[currentHoleNumber] = "Team D"
            } else {
                roundViewModel.betterBallHoleWinners[currentHoleNumber] = "Team B"
            }
        } else {
            roundViewModel.betterBallHoleTallies["\(prefix)Halved", default: 0] += 1
            if isCD {
                roundViewModel.betterBallHoleWinnersCD[currentHoleNumber] = "Halved"
            } else {
                roundViewModel.betterBallHoleWinners[currentHoleNumber] = "Halved"
            }
        }
        
        print("\(isCD ? "Team C" : "Team A") score: \(teamAScore) || \(isCD ? "Team D" : "Team B") score: \(teamBScore)")
    }
    
    static func resetBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int) {
        roundViewModel.betterBallNetScores[currentHoleNumber, default: [:]][golferId] = nil
        roundViewModel.betterBallHoleWinners[currentHoleNumber] = nil
        roundViewModel.betterBallHoleWinnersCD[currentHoleNumber] = nil
        resetBetterBallTallyForHole(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
    }
    
    static func updateBetterBallMatchStatus(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        roundViewModel.currentHole = currentHoleNumber
        guard roundViewModel.isBetterBall else { return }
        
        let startingHole = getStartingHole(for: roundViewModel.roundType)
        let lastHole = getLastHole(for: roundViewModel.roundType)
        let totalHoles = getNumberOfHoles(for: roundViewModel.roundType)
        
        // Reset match status arrays if recalculating from the first hole
        if currentHoleNumber == startingHole {
            roundViewModel.betterBallMatchArray = Array(repeating: 0, count: totalHoles)
            roundViewModel.betterBallMatchArrayCD = Array(repeating: 0, count: totalHoles)
            roundViewModel.betterBallMatchWinner = nil
            roundViewModel.betterBallWinningScore = nil
            roundViewModel.betterBallMatchWinningHole = nil
            roundViewModel.betterBallMatchWinnerCD = nil
            roundViewModel.betterBallWinningScoreCD = nil
            roundViewModel.betterBallMatchWinningHoleCD = nil
        }

        let lastHoleToUpdate = min(currentHoleNumber, lastHole)
        
        // Update match status for each hole up to the last hole to update
        for hole in startingHole...lastHoleToUpdate {
            updateMatchArrays(roundViewModel: roundViewModel, hole: hole, startingHole: startingHole)
        }
        
        // Calculate and update match status for A vs B
        updateMatchStatus(roundViewModel: roundViewModel, currentHoleNumber: currentHoleNumber, startingHole: startingHole, lastHole: lastHole, totalHoles: totalHoles, isCD: false)
        
        // Calculate and update match status for C vs D if teams exist
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            updateMatchStatus(roundViewModel: roundViewModel, currentHoleNumber: currentHoleNumber, startingHole: startingHole, lastHole: lastHole, totalHoles: totalHoles, isCD: true)
        }
        
        // Update press statuses
        BetterBallPressModel.updateAllBetterBallPressStatuses(roundViewModel: roundViewModel, for: currentHoleNumber)
        
        print("Debug: BetterBallModel updateBetterBallMatchStatus() - Updated match status for hole \(currentHoleNumber)")
        print("Better Ball Match Status A vs B: \(roundViewModel.betterBallMatchStatus ?? "N/A")")
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            print("Better Ball Match Status C vs D: \(roundViewModel.betterBallMatchStatusCD ?? "N/A")")
        }
        
        roundViewModel.objectWillChange.send()
    }
    
    private static func updateMatchArrays(roundViewModel: RoundViewModel, hole: Int, startingHole: Int) {
        let index = hole - startingHole
        if let winner = roundViewModel.betterBallHoleWinners[hole] {
            roundViewModel.betterBallMatchArray[index] = winner == "Team A" ? 1 : (winner == "Team B" ? -1 : 0)
        }
        if let winnerCD = roundViewModel.betterBallHoleWinnersCD[hole] {
            roundViewModel.betterBallMatchArrayCD[index] = winnerCD == "Team C" ? 1 : (winnerCD == "Team D" ? -1 : 0)
        }
    }
    
    private static func updateMatchStatus(roundViewModel: RoundViewModel, currentHoleNumber: Int, startingHole: Int, lastHole: Int, totalHoles: Int, isCD: Bool) {
        let matchArray = isCD ? roundViewModel.betterBallMatchArrayCD : roundViewModel.betterBallMatchArray
        let matchScore = matchArray[0..<(currentHoleNumber - startingHole + 1)].reduce(0, +)
        let holesPlayed = currentHoleNumber - startingHole + 1
        let remainingHoles = totalHoles - holesPlayed
        
        let (teamA, teamB) = isCD ? ("Team C", "Team D") : ("Team A", "Team B")
        
        // Check for match win conditions
        if abs(matchScore) > remainingHoles {
            setMatchResult(roundViewModel: roundViewModel, winner: matchScore > 0 ? teamA : teamB, score: "\(abs(matchScore))&\(remainingHoles)", winningHole: currentHoleNumber, isCD: isCD)
        } else if currentHoleNumber == lastHole {
            if matchScore != 0 {
                setMatchResult(roundViewModel: roundViewModel, winner: matchScore > 0 ? teamA : teamB, score: "1UP", winningHole: lastHole, isCD: isCD)
            } else {
                setMatchResult(roundViewModel: roundViewModel, winner: "Tie", score: "All Square", winningHole: lastHole, isCD: isCD)
            }
        } else {
            updateOngoingMatchStatus(roundViewModel: roundViewModel, matchScore: matchScore, holesPlayed: holesPlayed, remainingHoles: remainingHoles, teamA: teamA, teamB: teamB, isCD: isCD)
        }
    }
    
    private static func setMatchResult(roundViewModel: RoundViewModel, winner: String, score: String, winningHole: Int, isCD: Bool) {
        if isCD {
            roundViewModel.betterBallMatchWinnerCD = winner
            roundViewModel.betterBallWinningScoreCD = formatBetterBallWinningScore(score)
            roundViewModel.betterBallMatchWinningHoleCD = winningHole
            roundViewModel.betterBallMatchStatusCD = "\(winner) won \(roundViewModel.betterBallWinningScoreCD!)"
        } else {
            roundViewModel.betterBallMatchWinner = winner
            roundViewModel.betterBallWinningScore = formatBetterBallWinningScore(score)
            roundViewModel.betterBallMatchWinningHole = winningHole
            roundViewModel.betterBallMatchStatus = "\(winner) won \(roundViewModel.betterBallWinningScore!)"
        }
    }
    
    private static func updateOngoingMatchStatus(roundViewModel: RoundViewModel, matchScore: Int, holesPlayed: Int, remainingHoles: Int, teamA: String, teamB: String, isCD: Bool) {
        let status: String
        if matchScore == 0 {
            status = "All Square thru \(holesPlayed)"
        } else {
            let leadingTeam = matchScore > 0 ? teamA : teamB
            let absScore = abs(matchScore)
            if absScore == remainingHoles {
                status = "\(leadingTeam) \(absScore)UP with \(remainingHoles) to play (Dormie)"
            } else {
                status = "\(leadingTeam) \(absScore)UP thru \(holesPlayed)"
            }
        }
        
        if isCD {
            roundViewModel.betterBallMatchStatusCD = status
        } else {
            roundViewModel.betterBallMatchStatus = status
        }
    }
    
    static func recalculateBetterBallTallies(roundViewModel: RoundViewModel, upToHole: Int) {
        guard roundViewModel.isBetterBall, getTeams(roundViewModel: roundViewModel) != nil else {
            print("Error: Better Ball not active or teams not set")
            return
        }
        
        roundViewModel.betterBallHoleTallies = [:]
        roundViewModel.betterBallTalliedHoles = []
        let totalHoles = getNumberOfHoles(for: roundViewModel.roundType)
        roundViewModel.betterBallMatchArray = Array(repeating: 0, count: totalHoles)
        roundViewModel.betterBallMatchArrayCD = Array(repeating: 0, count: totalHoles)
        
        for holeNumber in getStartingHole(for: roundViewModel.roundType)...upToHole {
            updateBetterBallTallies(roundViewModel: roundViewModel, for: holeNumber)
            updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: upToHole)
        }
        
        print("Debug: BetterBallModel recalculateBetterBallTallies() - Recalculated tallies up to hole \(upToHole)")
        print("Better Ball Match Array A vs B: \(roundViewModel.betterBallMatchArray)")
        print("Better Ball Match Status A vs B: \(roundViewModel.betterBallMatchStatus ?? "N/A")")
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            print("Better Ball Match Array C vs D: \(roundViewModel.betterBallMatchArrayCD)")
            print("Better Ball Match Status C vs D: \(roundViewModel.betterBallMatchStatusCD ?? "N/A")")
        }
    }
    
    static func updateFinalBetterBallMatchStatus(roundViewModel: RoundViewModel) {
        print("Debug: BetterBallModel updateFinalBetterBallMatchStatus()")
        let lastHole = getLastHole(for: roundViewModel.roundType)
        updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: lastHole)
        
        // Update A vs B match
        updateFinalMatchStatus(roundViewModel: roundViewModel, isCD: false)
        
        // Update C vs D match if it exists
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            updateFinalMatchStatus(roundViewModel: roundViewModel, isCD: true)
        }
        
        // Calculate final team scores for both matches
        calculateFinalScores(roundViewModel: roundViewModel)
        
        roundViewModel.forceUIUpdate()
    }
    
    private static func updateFinalMatchStatus(roundViewModel: RoundViewModel, isCD: Bool) {
        let score = isCD ? roundViewModel.betterBallWinningScoreCD : roundViewModel.betterBallWinningScore
        let winner = isCD ? roundViewModel.betterBallMatchWinnerCD : roundViewModel.betterBallMatchWinner
        
        if let score = score, score.hasSuffix("&0") {
            let updatedScore = formatBetterBallWinningScore(score)
            if isCD {
                roundViewModel.betterBallWinningScoreCD = updatedScore
                roundViewModel.betterBallMatchStatusCD = "\(winner!) won \(updatedScore)"
            } else {
                roundViewModel.betterBallWinningScore = updatedScore
                roundViewModel.betterBallMatchStatus = "\(winner!) won \(updatedScore)"
            }
        }
    }
    
    private static func calculateFinalScores(roundViewModel: RoundViewModel) {
        let teamAScore = roundViewModel.betterBallMatchArray.filter { $0 > 0 }.count
        let teamBScore = roundViewModel.betterBallMatchArray.filter { $0 < 0 }.count
        let halvedHoles = roundViewModel.betterBallMatchArray.filter { $0 == 0 }.count
        
        var finalStats = [
            "Team A Wins": teamAScore,
            "Team B Wins": teamBScore,
            "A vs B Halved Holes": halvedHoles
        ]
        
        print("Debug: Final Better Ball Scores A vs B - Team A: \(teamAScore), Team B: \(teamBScore), Halved: \(halvedHoles)")
        
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            let teamCScore = roundViewModel.betterBallMatchArrayCD.filter { $0 > 0 }.count
            let teamDScore = roundViewModel.betterBallMatchArrayCD.filter { $0 < 0 }.count
            let halvedHolesCD = roundViewModel.betterBallMatchArrayCD.filter { $0 == 0 }.count
            
            finalStats["Team C Wins"] = teamCScore
            finalStats["Team D Wins"] = teamDScore
            finalStats["C vs D Halved Holes"] = halvedHolesCD
            
            print("Debug: Final Better Ball Scores C vs D - Team C: \(teamCScore), Team D: \(teamDScore), Halved: \(halvedHolesCD)")
        }
        
        roundViewModel.betterBallFinalStatistics = finalStats
        
        print("Debug: Final Better Ball Match Status A vs B - \(roundViewModel.betterBallMatchStatus ?? "Unknown")")
        if !roundViewModel.betterBallMatchArrayCD.isEmpty {
            print("Debug: Final Better Ball Match Status C vs D - \(roundViewModel.betterBallMatchStatusCD ?? "Unknown")")
        }
        print("Debug: Final Better Ball Statistics - \(roundViewModel.betterBallFinalStatistics)")
    }
    
    static func formatBetterBallWinningScore(_ score: String) -> String {
        if score.hasSuffix("&0") {
            let leadNumber = score.split(separator: "&")[0]
            return "\(leadNumber)UP"
        }
        return score
    }
    
    static func resetBetterBallTallyForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        let index = holeNumber - getStartingHole(for: roundViewModel.roundType)
        roundViewModel.betterBallMatchArray[index] = 0
        roundViewModel.betterBallMatchArrayCD[index] = 0
        roundViewModel.betterBallHoleWinners[holeNumber] = nil
        roundViewModel.betterBallHoleWinnersCD[holeNumber] = nil
    }
    
    static func calculateBetterBallStrokeHoles(roundViewModel: RoundViewModel) {
        guard let (teamA, teamB, teamC, teamD) = getTeams(roundViewModel: roundViewModel) else {
            print("Error: Better Ball teams not set")
            return
        }
        
        let allPlayers = teamA + teamB + teamC + teamD
        let lowestHandicapPlayer = allPlayers.min { roundViewModel.courseHandicaps[$0.id] ?? 0 < roundViewModel.courseHandicaps[$1.id] ?? 0 }
        let lowestHandicap = roundViewModel.courseHandicaps[lowestHandicapPlayer?.id ?? ""] ?? 0
        
        for player in allPlayers {
            let playerHandicap = roundViewModel.courseHandicaps[player.id] ?? 0
            let betterBallHandicap = max(0, playerHandicap - lowestHandicap)
            
            if let playerStrokeHoles = roundViewModel.strokeHoles[player.id] {
                roundViewModel.betterBallStrokeHoles[player.id] = Array(playerStrokeHoles.prefix(betterBallHandicap))
            }
            
            print("Debug: Better Ball Stroke Holes for \(player.firstName) \(player.lastName): \(roundViewModel.betterBallStrokeHoles[player.id] ?? [])")
        }
    }
    
    private static func calculateTeamScore(roundViewModel: RoundViewModel, team: [Golfer], for holeNumber: Int) -> Int? {
        let scores = team.compactMap { roundViewModel.betterBallNetScores[holeNumber]?[$0.id] }
        return scores.min()  // This already handles teams of any size
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
