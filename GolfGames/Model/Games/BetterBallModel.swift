import Foundation

struct BetterBallModel {
    static func initializeBetterBall(roundViewModel: RoundViewModel) {
        guard roundViewModel.isBetterBall else {
            print("Debug: BetterBallModel - Better Ball is not enabled")
            return
        }
        
        print("Debug: BetterBallModel - Initializing Better Ball")
        print("Debug: Better Ball Team Assignments: \(roundViewModel.betterBallTeamAssignments)")
        print("Debug: Golfers in round: \(roundViewModel.golfers.map { "\($0.fullName) (ID: \($0.id))" })")
        
        roundViewModel.betterBallMatchArray = Array(repeating: 0, count: 18)
        roundViewModel.betterBallMatchStatus = "All Square"
        
        // Calculate Better Ball stroke holes
        calculateBetterBallStrokeHoles(roundViewModel: roundViewModel)
        
        // Initialize other necessary properties
        roundViewModel.betterBallHoleTallies = [:]
        roundViewModel.betterBallTalliedHoles = []
        roundViewModel.betterBallHoleWinners = [:]
        roundViewModel.betterBallNetScores = [:]
        
        if let (teamA, teamB) = getTeams(roundViewModel: roundViewModel) {
            print("Team A: \(teamA.map { $0.fullName })")
            print("Team B: \(teamB.map { $0.fullName })")
        } else {
            print("Error: Better Ball teams not properly set")
        }
    }
    
    static func getTeams(roundViewModel: RoundViewModel) -> ([Golfer], [Golfer])? {
        guard !roundViewModel.betterBallTeamAssignments.isEmpty else {
            print("Debug: getTeams - betterBallTeamAssignments is empty")
            return nil
        }
        
        var teamA: [Golfer] = []
        var teamB: [Golfer] = []
        
        for golfer in roundViewModel.golfers {
            print("Debug: getTeams - Processing golfer: \(golfer.fullName), ID: \(golfer.id)")
            if let assignment = roundViewModel.betterBallTeamAssignments[golfer.id] {
                if assignment == "Team A" {
                    teamA.append(golfer)
                    print("Debug: getTeams - Added \(golfer.fullName) to Team A")
                } else if assignment == "Team B" {
                    teamB.append(golfer)
                    print("Debug: getTeams - Added \(golfer.fullName) to Team B")
                }
            } else {
                print("Debug: getTeams - No assignment found for golfer: \(golfer.fullName)")
            }
        }
        
        print("Debug: getTeams - Team A count: \(teamA.count), Team B count: \(teamB.count)")
        return (!teamA.isEmpty && !teamB.isEmpty) ? (teamA, teamB) : nil
    }
    
    
    static func updateBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        let isStrokeHole = roundViewModel.betterBallStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        let betterBallNetScore = isStrokeHole ? scoreInt - 1 : scoreInt
        
        roundViewModel.betterBallNetScores[currentHoleNumber, default: [:]][golferId] = betterBallNetScore
        
        let logMessage = "Better Ball Model updateBetterBallScore() - Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.formattedName(golfers: roundViewModel.golfers) ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Better Ball Net Score: \(betterBallNetScore), Better Ball Stroke Hole: \(isStrokeHole)"
        
        print(logMessage)
    }
    
    static func updateBetterBallTallies(roundViewModel: RoundViewModel, for holeNumber: Int) {
    print("Debug: Entering updateBetterBallTallies for hole \(holeNumber)")
    
    guard let (teamA, teamB) = getTeams(roundViewModel: roundViewModel),
          let teamAScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamA, for: holeNumber),
          let teamBScore = calculateTeamScore(roundViewModel: roundViewModel, team: teamB, for: holeNumber) else {
        print("Debug: updateBetterBallTallies - Unable to calculate scores for hole \(holeNumber)")
        return
    }
    
    if teamAScore < teamBScore {
        roundViewModel.betterBallMatchArray[holeNumber - 1] = 1
        roundViewModel.betterBallHoleWinners[holeNumber] = "Team A"
        roundViewModel.betterBallHoleTallies["Team A", default: 0] += 1
    } else if teamBScore < teamAScore {
        roundViewModel.betterBallMatchArray[holeNumber - 1] = -1
        roundViewModel.betterBallHoleWinners[holeNumber] = "Team B"
        roundViewModel.betterBallHoleTallies["Team B", default: 0] += 1
    } else {
        roundViewModel.betterBallMatchArray[holeNumber - 1] = 0
        roundViewModel.betterBallHoleWinners[holeNumber] = "Halved"
        roundViewModel.betterBallHoleTallies["Halved", default: 0] += 1
    }
    
    roundViewModel.betterBallTalliedHoles.insert(holeNumber)
    
    print("Debug: updateBetterBallTallies - Updated for hole \(holeNumber): Team A: \(teamAScore), Team B: \(teamBScore)")
}
    
    static func resetBetterBallScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int) {
        roundViewModel.betterBallNetScores[currentHoleNumber, default: [:]][golferId] = nil
        roundViewModel.betterBallHoleWinners[currentHoleNumber] = nil
        resetBetterBallTallyForHole(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
    }
    
    static func updateBetterBallMatchStatus(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        guard roundViewModel.isBetterBall, getTeams(roundViewModel: roundViewModel) != nil else { return }
        
        // Reset match status if it's the first hole
        if currentHoleNumber == 1 {
            roundViewModel.betterBallMatchWinner = nil
            roundViewModel.betterBallWinningScore = nil
            roundViewModel.betterBallMatchWinningHole = nil
            roundViewModel.betterBallFinalMatchArray = nil
        }
        
        // Only update if the match hasn't been finalized
        if roundViewModel.betterBallMatchWinner == nil {
            roundViewModel.betterBallMatchScore = roundViewModel.betterBallMatchArray[0..<currentHoleNumber].reduce(0, +)
            roundViewModel.holesPlayed = currentHoleNumber
            
            let remainingHoles = 18 - roundViewModel.holesPlayed
            
            // Check for match win conditions
            if abs(roundViewModel.betterBallMatchScore) > remainingHoles {
                roundViewModel.betterBallMatchWinner = roundViewModel.betterBallMatchScore > 0 ? "Team A" : "Team B"
                roundViewModel.betterBallWinningScore = formatBetterBallWinningScore("\(abs(roundViewModel.betterBallMatchScore))&\(remainingHoles)")
                roundViewModel.betterBallMatchWinningHole = currentHoleNumber
                roundViewModel.betterBallFinalMatchArray = roundViewModel.betterBallMatchArray
                roundViewModel.betterBallMatchStatus = "\(roundViewModel.betterBallMatchWinner!) won \(roundViewModel.betterBallWinningScore!)"
            } else if roundViewModel.holesPlayed == 18 {
                if roundViewModel.betterBallMatchScore != 0 {
                    roundViewModel.betterBallMatchWinner = roundViewModel.betterBallMatchScore > 0 ? "Team A" : "Team B"
                    roundViewModel.betterBallWinningScore = "1UP"
                    roundViewModel.betterBallMatchStatus = "\(roundViewModel.betterBallMatchWinner!) won \(roundViewModel.betterBallWinningScore!)"
                } else {
                    roundViewModel.betterBallMatchWinner = "Tie"
                    roundViewModel.betterBallWinningScore = "All Square"
                    roundViewModel.betterBallMatchStatus = "Match ended \(roundViewModel.betterBallWinningScore!)"
                }
                roundViewModel.betterBallMatchWinningHole = 18
                roundViewModel.betterBallFinalMatchArray = roundViewModel.betterBallMatchArray
            } else {
                // Update betterBallMatchStatus string
                if roundViewModel.betterBallMatchScore == 0 {
                    roundViewModel.betterBallMatchStatus = "All Square thru \(roundViewModel.holesPlayed)"
                } else {
                    let leadingTeam = roundViewModel.betterBallMatchScore > 0 ? "Team A" : "Team B"
                    let absScore = abs(roundViewModel.betterBallMatchScore)
                    
                    if absScore == remainingHoles {
                        roundViewModel.betterBallMatchStatus = "\(leadingTeam) \(absScore)UP with \(remainingHoles) to play (Dormie)"
                    } else {
                        roundViewModel.betterBallMatchStatus = "\(leadingTeam) \(absScore)UP thru \(roundViewModel.holesPlayed)"
                    }
                }
            }
        }
        
        print("Debug: BetterBallModel updateBetterBallMatchStatus() - Updated match status for hole \(currentHoleNumber): \(roundViewModel.betterBallMatchArray)")
        print("Better Ball match status: \(roundViewModel.betterBallMatchStatus ?? "N/A")")
        
        roundViewModel.objectWillChange.send()
    }
    
    static func recalculateBetterBallTallies(roundViewModel: RoundViewModel, upToHole: Int) {
    print("Debug: Entering recalculateBetterBallTallies for hole \(upToHole)")
    
    guard roundViewModel.isBetterBall, getTeams(roundViewModel: roundViewModel) != nil else {
        print("Error: Better Ball not active or teams not set")
        return
    }
    
    roundViewModel.betterBallHoleTallies = [:]
    roundViewModel.betterBallTalliedHoles = []
    roundViewModel.betterBallMatchArray = Array(repeating: 0, count: 18)
    
    for holeNumber in 1...upToHole {
        print("Debug: Updating tallies for hole \(holeNumber)")
        updateBetterBallTallies(roundViewModel: roundViewModel, for: holeNumber)
    }
    
    updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: upToHole)
    
    print("Debug: BetterBallModel recalculateBetterBallTallies() - Recalculated tallies up to hole \(upToHole)")
    print("Better Ball Match Array: \(roundViewModel.betterBallMatchArray)")
    print("Better Ball Hole Tallies: \(roundViewModel.betterBallHoleTallies)")
    print("Better Ball Match Status: \(roundViewModel.betterBallMatchStatus ?? "N/A")")
}
    
    static func updateFinalBetterBallMatchStatus(roundViewModel: RoundViewModel) {
        // Update main Better Ball match status
        print("Debug: BetterBallModel updateFinalBetterBallMatchStatus()")
        updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: 18)
        
        // If the main match ended with a "&0" score, update it
        if let score = roundViewModel.betterBallWinningScore, score.hasSuffix("&0") {
            roundViewModel.betterBallWinningScore = formatBetterBallWinningScore(score)
            roundViewModel.betterBallMatchStatus = "\(roundViewModel.betterBallMatchWinner!) won \(roundViewModel.betterBallWinningScore!)"
        }
        
        // Calculate final team scores
        let teamAScore = roundViewModel.betterBallMatchArray.filter { $0 > 0 }.count
        let teamBScore = roundViewModel.betterBallMatchArray.filter { $0 < 0 }.count
        let halvedHoles = roundViewModel.betterBallMatchArray.filter { $0 == 0 }.count
        
        print("Debug: Final Better Ball Scores - Team A: \(teamAScore), Team B: \(teamBScore), Halved: \(halvedHoles)")
        
        // Calculate and store additional statistics
        roundViewModel.betterBallFinalStatistics = [
            "Team A Wins": teamAScore,
            "Team B Wins": teamBScore,
            "Halved Holes": halvedHoles
        ]
        
        print("Debug: Final Better Ball Match Status - \(roundViewModel.betterBallMatchStatus ?? "Unknown")")
        print("Debug: Final Better Ball Statistics - \(roundViewModel.betterBallFinalStatistics)")
        
        roundViewModel.forceUIUpdate()
    }
    
    static func formatBetterBallWinningScore(_ score: String) -> String {
        // This can be identical to formatWinningScore in MatchPlayModel
        if score.hasSuffix("&0") {
            let leadNumber = score.split(separator: "&")[0]
            return "\(leadNumber)UP"
        }
        return score
    }
    static func resetBetterBallTallyForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        roundViewModel.betterBallMatchArray[holeNumber - 1] = 0
        roundViewModel.betterBallHoleWinners[holeNumber] = nil
    }
    
    static func calculateBetterBallStrokeHoles(roundViewModel: RoundViewModel) {
        guard let (teamA, teamB) = getTeams(roundViewModel: roundViewModel) else {
            print("Error: Better Ball teams not set")
            return
        }
        
        let allPlayers = teamA + teamB
        let lowestHandicapPlayer = allPlayers.min { roundViewModel.courseHandicaps[$0.id] ?? 0 < roundViewModel.courseHandicaps[$1.id] ?? 0 }
        let lowestHandicap = roundViewModel.courseHandicaps[lowestHandicapPlayer?.id ?? ""] ?? 0
        
        for player in allPlayers {
            let playerHandicap = roundViewModel.courseHandicaps[player.id] ?? 0
            let betterBallHandicap = max(0, playerHandicap - lowestHandicap)
            
            if let playerStrokeHoles = roundViewModel.strokeHoles[player.id] {
                roundViewModel.betterBallStrokeHoles[player.id] = Array(playerStrokeHoles.prefix(betterBallHandicap))
            }
            
            print("Debug: Better Ball Stroke Holes for \(player.fullName): \(roundViewModel.betterBallStrokeHoles[player.id] ?? [])")
        }
    }
    
    private static func calculateTeamScore(roundViewModel: RoundViewModel, team: [Golfer], for holeNumber: Int) -> Int? {
    let scores = team.compactMap { roundViewModel.betterBallNetScores[holeNumber]?[$0.id] }
    print("Debug: calculateTeamScore for hole \(holeNumber), team scores: \(scores)")
    return scores.min()
}
}
