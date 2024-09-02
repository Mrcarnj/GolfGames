//
//  MatchPlayModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/21/24.
//

import Foundation

struct MatchPlayModel {
    static func setMatchPlayGolfers(roundViewModel: RoundViewModel, golfer1: Golfer, golfer2: Golfer) {
        roundViewModel.matchPlayGolfers = (golfer1, golfer2)
        initializeMatchPlay(roundViewModel: roundViewModel)
        print("Debug: MatchPlayModel setMatchPlayGolfers()")
    }
    
    static func updateMatchPlayScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        let isMatchPlayStrokeHole = roundViewModel.matchPlayStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        let matchPlayNetScore = isMatchPlayStrokeHole ? scoreInt - 1 : scoreInt
        
        roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = matchPlayNetScore
        
        let logMessage = "MatchPlayModel updateMatchPlayScore() - Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.formattedName(golfers: roundViewModel.golfers) ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Match Play Net Score: \(matchPlayNetScore), Match Play Stroke Hole: \(isMatchPlayStrokeHole)"
        
        print(logMessage)
    }
    
    static func updateTallies(roundViewModel: RoundViewModel, for holeNumber: Int) {
        guard let (player1, player2) = roundViewModel.matchPlayGolfers,
              let player1Score = roundViewModel.matchPlayNetScores[holeNumber]?[player1.id],
              let player2Score = roundViewModel.matchPlayNetScores[holeNumber]?[player2.id] else {
            return
        }
        
        if player1Score < player2Score {
            roundViewModel.holeTallies[player1.formattedName(golfers: roundViewModel.golfers), default: 0] += 1
            roundViewModel.holeWinners[holeNumber] = player1.formattedName(golfers: roundViewModel.golfers)
        } else if player2Score < player1Score {
            roundViewModel.holeTallies[player2.formattedName(golfers: roundViewModel.golfers), default: 0] += 1
            roundViewModel.holeWinners[holeNumber] = player2.formattedName(golfers: roundViewModel.golfers)
        } else {
            roundViewModel.holeTallies["Halved", default: 0] += 1
            roundViewModel.holeWinners[holeNumber] = "Halved"
        }
        
        roundViewModel.talliedHoles.insert(holeNumber)
    }
    
    static func resetMatchPlayScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int) {
        roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = nil
        roundViewModel.holeWinners[currentHoleNumber] = nil
        resetTallyForHole(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
    }
    
    static func updateMatchPlayTallies(roundViewModel: RoundViewModel, currentHoleNumber: Int) {
        updateTallies(roundViewModel: roundViewModel, for: currentHoleNumber)
        roundViewModel.currentPressStartHole = nil  // Reset the current press start hole
    }
    
    static func recalculateTallies(roundViewModel: RoundViewModel, upToHole: Int) {
        guard roundViewModel.isMatchPlay && roundViewModel.golfers.count >= 2 else { return }
        
        roundViewModel.holeTallies = [:]
        roundViewModel.talliedHoles = []
        roundViewModel.matchStatusArray = Array(repeating: 0, count: 18)
        
        for holeNumber in 1...upToHole {
            updateTallies(roundViewModel: roundViewModel, for: holeNumber)
            updateMatchStatus(roundViewModel: roundViewModel, for: holeNumber)
        }
    }
    
    static func updateMatchStatus(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        roundViewModel.currentHole = currentHoleNumber
        guard roundViewModel.isMatchPlay, let (player1, player2) = roundViewModel.matchPlayGolfers else { return }
        
        let startingHole = getStartingHole(for: roundViewModel.roundType)
        let lastHole = getLastHole(for: roundViewModel.roundType)
        
        // Reset match status array if recalculating from the first hole of the round
        if currentHoleNumber == startingHole {
            roundViewModel.matchStatusArray = Array(repeating: 0, count: getNumberOfHoles(for: roundViewModel.roundType))
            roundViewModel.matchWinner = nil
            roundViewModel.winningScore = nil
            roundViewModel.matchWinningHole = nil
            roundViewModel.finalMatchStatusArray = nil
        }
        
        // Only update if the match hasn't been finalized
        if roundViewModel.matchWinner == nil {
            // Determine the range of holes to update
            let holeRange = max(startingHole, min(currentHoleNumber, lastHole))
            
            // Update match status for each hole up to the current hole
            for hole in startingHole...holeRange {
                if let winner = roundViewModel.holeWinners[hole] {
                    let index = hole - startingHole
                    if winner == player1.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.matchStatusArray[index] = 1
                    } else if winner == player2.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.matchStatusArray[index] = -1
                    } else {
                        roundViewModel.matchStatusArray[index] = 0
                    }
                }
                
                // Calculate cumulative status
                roundViewModel.matchScore = roundViewModel.matchStatusArray[0..<(hole - startingHole + 1)].reduce(0, +)
                roundViewModel.holesPlayed = hole - startingHole + 1
                
                let remainingHoles = getNumberOfHoles(for: roundViewModel.roundType) - roundViewModel.holesPlayed
                
                // Check for match win conditions
                if abs(roundViewModel.matchScore) > remainingHoles {
                    roundViewModel.matchWinner = roundViewModel.matchScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                    roundViewModel.winningScore = formatWinningScore("\(abs(roundViewModel.matchScore))&\(remainingHoles)")
                    roundViewModel.matchWinningHole = hole
                    roundViewModel.finalMatchStatusArray = roundViewModel.matchStatusArray
                    roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
                    break
                } else if hole == lastHole {
                    if roundViewModel.matchScore != 0 {
                        roundViewModel.matchWinner = roundViewModel.matchScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                        roundViewModel.winningScore = "1UP"
                        roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
                    } else {
                        roundViewModel.matchWinner = "Tie"
                        roundViewModel.winningScore = "All Square"
                        roundViewModel.matchPlayStatus = "Match ended \(roundViewModel.winningScore!)"
                    }
                    roundViewModel.matchWinningHole = lastHole
                    roundViewModel.finalMatchStatusArray = roundViewModel.matchStatusArray
                    break
                }
                
                // Update matchPlayStatus string
                if roundViewModel.matchScore == 0 {
                    roundViewModel.matchPlayStatus = "All Square thru \(roundViewModel.holesPlayed)"
                } else {
                    let leadingPlayer = roundViewModel.matchScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                    let absScore = abs(roundViewModel.matchScore)
                    
                    if absScore == remainingHoles {
                        roundViewModel.matchPlayStatus = "\(leadingPlayer) \(absScore)UP with \(remainingHoles) to play (Dormie)"
                    } else {
                        roundViewModel.matchPlayStatus = "\(leadingPlayer) \(absScore)UP thru \(roundViewModel.holesPlayed)"
                    }
                }
            }
        }
        
        // Update press statuses
        MatchPlayPressModel.updateAllPressStatuses(roundViewModel: roundViewModel, for: currentHoleNumber)
        
        print("Debug: MatchPlayModel updateMatchStatus() - Updated match status for hole \(currentHoleNumber): \(roundViewModel.matchStatusArray)")
        print("Main match status: \(roundViewModel.matchPlayStatus ?? "N/A")")
        for (index, pressStatus) in roundViewModel.pressStatuses.enumerated() {
            print("Press \(index + 1) status: \(pressStatus)")
        }
        
        roundViewModel.objectWillChange.send()
    }
    
    static func formatWinningScore(_ score: String) -> String {
        if score.hasSuffix("&0") {
            let leadNumber = score.split(separator: "&")[0]
            return "\(leadNumber)UP"
        }
        return score
    }
    
    static func resetTallyForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        guard roundViewModel.talliedHoles.contains(holeNumber), let winner = roundViewModel.holeWinners[holeNumber] else { return }
        
        if winner == "Halved" {
            roundViewModel.holeTallies["Halved", default: 0] -= 1
        } else {
            roundViewModel.holeTallies[winner, default: 0] -= 1
        }
        roundViewModel.talliedHoles.remove(holeNumber)
    }
    
    static func updateFinalMatchStatus(roundViewModel: RoundViewModel) {
        let lastHole = getLastHole(for: roundViewModel.roundType)
        updateMatchStatus(roundViewModel: roundViewModel, for: lastHole)
        
        // If the main match ended with a "&0" score, update it
        if let score = roundViewModel.winningScore, score.hasSuffix("&0") {
            roundViewModel.winningScore = formatWinningScore(score)
            roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
        }
        
        // Update and finalize all presses
        for index in roundViewModel.presses.indices {
            MatchPlayPressModel.updatePressMatchStatus(roundViewModel: roundViewModel, pressIndex: index, for: lastHole)
            
            let press = roundViewModel.presses[index]
            let pressScore = press.matchStatusArray.reduce(0, +)
            
            if pressScore == 0 && press.winner == nil {
                roundViewModel.presses[index].winner = "Tie"
                roundViewModel.presses[index].winningScore = "All Square"
                roundViewModel.pressStatuses[index] = "Press \(index + 1) ended All Square"
            } else if let score = press.winningScore, score.hasSuffix("&0") {
                // Update press status if it ended with a "&0" score
                roundViewModel.presses[index].winningScore = formatWinningScore(score)
                roundViewModel.pressStatuses[index] = "Press \(index + 1): \(press.winner ?? "Unknown") won \(roundViewModel.presses[index].winningScore ?? "Unknown")"
            }
        }
        
        roundViewModel.forceUIUpdate()
    }
    
    static func initializeMatchPlay(roundViewModel: RoundViewModel) {
        guard roundViewModel.isMatchPlay, roundViewModel.golfers.count >= 2 else { return }

        // If matchPlayGolfers is not set, use all golfers in the round
        let matchPlayGolfers = roundViewModel.matchPlayGolfers.map { [$0.0, $0.1] } ?? roundViewModel.golfers

        print("Debug: MatchPlayModel - Initializing Match Play")
        StrokesModel.calculateGameStrokeHoles(roundViewModel: roundViewModel, golfers: matchPlayGolfers)

        // Initialize match status
        roundViewModel.matchStatusArray = Array(repeating: 0, count: getNumberOfHoles(for: roundViewModel.roundType))
        roundViewModel.matchScore = 0
        roundViewModel.holesPlayed = 0
        roundViewModel.matchPlayStatus = "All Square thru 0"

        // Reset other match-related properties
        roundViewModel.matchWinner = nil
        roundViewModel.winningScore = nil
        roundViewModel.matchWinningHole = nil
        roundViewModel.finalMatchStatusArray = nil

        // Clear existing presses and statuses
        roundViewModel.presses = []
        roundViewModel.pressStatuses = []

        print("Debug: MatchPlayModel - Match Play initialized with status: \(roundViewModel.matchPlayStatus ?? "N/A")")
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
