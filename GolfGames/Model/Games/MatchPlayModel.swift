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
        
        // Reset match status array if recalculating from an earlier hole
        if currentHoleNumber == 1 {
            roundViewModel.matchStatusArray = Array(repeating: 0, count: 18)
            roundViewModel.matchWinner = nil
            roundViewModel.winningScore = nil
            roundViewModel.matchWinningHole = nil
            roundViewModel.finalMatchStatusArray = nil
        }
        
        // Only update if the match hasn't been finalized
        if roundViewModel.matchWinner == nil {
            // Update match status for each hole up to the current hole
            for hole in 1...currentHoleNumber {
                if let winner = roundViewModel.holeWinners[hole] {
                    if winner == player1.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.matchStatusArray[hole - 1] = 1
                    } else if winner == player2.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.matchStatusArray[hole - 1] = -1
                    } else {
                        roundViewModel.matchStatusArray[hole - 1] = 0
                    }
                }
                
                // Calculate cumulative status
                roundViewModel.matchScore = roundViewModel.matchStatusArray[0..<hole].reduce(0, +)
                roundViewModel.holesPlayed = hole
                
                let remainingHoles = 18 - roundViewModel.holesPlayed
                
                // Check for match win conditions
                if abs(roundViewModel.matchScore) > remainingHoles {
                    roundViewModel.matchWinner = roundViewModel.matchScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                    roundViewModel.winningScore = formatWinningScore("\(abs(roundViewModel.matchScore))&\(remainingHoles)")
                    roundViewModel.matchWinningHole = hole
                    roundViewModel.finalMatchStatusArray = roundViewModel.matchStatusArray
                    roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
                    break
                } else if roundViewModel.holesPlayed == 18 {
                    if roundViewModel.matchScore != 0 {
                        roundViewModel.matchWinner = roundViewModel.matchScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                        roundViewModel.winningScore = "1UP"
                        roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
                    } else {
                        roundViewModel.matchWinner = "Tie"
                        roundViewModel.winningScore = "All Square"
                        roundViewModel.matchPlayStatus = "Match ended \(roundViewModel.winningScore!)"
                    }
                    roundViewModel.matchWinningHole = 18
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
        // Update main match status
        print("Debug: MatchPlayModel updateFinalMatchStatus()")
        updateMatchStatus(roundViewModel: roundViewModel, for: 18)
        
        // If the main match ended with a "&0" score, update it
        if let score = roundViewModel.winningScore, score.hasSuffix("&0") {
            roundViewModel.winningScore = formatWinningScore(score)
            roundViewModel.matchPlayStatus = "\(roundViewModel.matchWinner!) won \(roundViewModel.winningScore!)"
        }
        
        // Update and finalize all presses
        for index in roundViewModel.presses.indices {
            MatchPlayPressModel.updatePressMatchStatus(roundViewModel: roundViewModel, pressIndex: index, for: 18)
            
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
}
    
}
