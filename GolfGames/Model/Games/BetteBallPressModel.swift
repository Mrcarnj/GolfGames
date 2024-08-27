//
//  BetteBallPressModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/24/24.
//

import Foundation

struct BetterBallPressModel {
    
    static func initiateBetterBallPress(roundViewModel: RoundViewModel, atHole: Int) {
        if roundViewModel.betterBallPresses.isEmpty && roundViewModel.betterBallMatchWinner != nil {
            print("Cannot initiate new press: main Better Ball match has been won and no existing presses")
            return
        }
        
        let totalHoles = BetterBallModel.getNumberOfHoles(for: roundViewModel.roundType)
        
        print("Initiating Better Ball press at hole \(atHole)")
        print("Current hole: \(roundViewModel.currentHole)")
        print("Number of Better Ball presses before adding: \(roundViewModel.betterBallPresses.count)")
        
        roundViewModel.betterBallPresses.append((startHole: atHole, matchStatusArray: Array(repeating: 0, count: totalHoles), winner: nil, winningScore: nil, winningHole: nil))
        roundViewModel.betterBallPressStatuses.append("Press \(roundViewModel.betterBallPresses.count): All Square thru 0")
        roundViewModel.betterBallCurrentPressStartHole = atHole
        
        print("Number of Better Ball presses after adding: \(roundViewModel.betterBallPresses.count)")
        print("Number of Better Ball press statuses: \(roundViewModel.betterBallPressStatuses.count)")
        print("Current Better Ball presses: \(roundViewModel.betterBallPresses)")
        print("Current Better Ball press statuses: \(roundViewModel.betterBallPressStatuses)")
        
        roundViewModel.objectWillChange.send()
    }
    
    static func getCurrentBetterBallPressStatus(roundViewModel: RoundViewModel) -> (leadingTeam: String?, trailingTeam: String?, score: Int)? {
        let startingHole = BetterBallModel.getStartingHole(for: roundViewModel.roundType)
        let lastHole = BetterBallModel.getLastHole(for: roundViewModel.roundType)
        
        if let lastPress = roundViewModel.betterBallPresses.last {
            let pressStartHole = lastPress.startHole
            let lowerBound = max(pressStartHole, startingHole)
            let upperBound = min(max(roundViewModel.currentHole, lowerBound), lastHole)
            let relevantHoles = lowerBound...upperBound

            print("Better Ball Press start hole: \(pressStartHole)")
            print("Current hole: \(roundViewModel.currentHole)")
            print("Relevant holes: \(relevantHoles)")
            
            let cumulativePressScore = relevantHoles.reduce(0) { total, hole in
                guard hole - pressStartHole < lastPress.matchStatusArray.count else { return total }
                return total + lastPress.matchStatusArray[hole - pressStartHole]
            }
            print("Better Ball Cumulative Press Score: \(cumulativePressScore)")
            
            if cumulativePressScore > 0 {
                return (leadingTeam: "Team A", trailingTeam: "Team B", score: cumulativePressScore)
            } else if cumulativePressScore < 0 {
                return (leadingTeam: "Team B", trailingTeam: "Team A", score: -cumulativePressScore)
            } else {
                return (leadingTeam: nil, trailingTeam: nil, score: 0)  // All square
            }
        } else {
            // If no presses, return main Better Ball match status
            let matchScore = roundViewModel.betterBallMatchArray[..<min(roundViewModel.currentHole - startingHole + 1, lastHole - startingHole + 1)].reduce(0, +)
            if matchScore > 0 {
                return (leadingTeam: "Team A", trailingTeam: "Team B", score: matchScore)
            } else if matchScore < 0 {
                return (leadingTeam: "Team B", trailingTeam: "Team A", score: -matchScore)
            } else {
                return (leadingTeam: nil, trailingTeam: nil, score: 0)  // All square
            }
        }
    }
    
    static func updateBetterBallPressMatchStatus(roundViewModel: RoundViewModel, pressIndex: Int, for currentHoleNumber: Int) {
        let press = roundViewModel.betterBallPresses[pressIndex]
        let pressStartHole = press.startHole
        let startingHole = BetterBallModel.getStartingHole(for: roundViewModel.roundType)
        let lastHole = BetterBallModel.getLastHole(for: roundViewModel.roundType)
        
        let lowerBound = max(pressStartHole, startingHole)
        let upperBound = min(currentHoleNumber, lastHole)
        
        for hole in lowerBound...upperBound {
            if let winner = roundViewModel.betterBallHoleWinners[hole] {
                let index = hole - pressStartHole
                if index >= 0 && index < press.matchStatusArray.count {
                    if winner == "Team A" {
                        roundViewModel.betterBallPresses[pressIndex].matchStatusArray[index] = 1
                    } else if winner == "Team B" {
                        roundViewModel.betterBallPresses[pressIndex].matchStatusArray[index] = -1
                    } else {
                        roundViewModel.betterBallPresses[pressIndex].matchStatusArray[index] = 0
                    }
                }
            }
        }
        
        // Check if the press has been won
        let pressStatus = roundViewModel.betterBallPresses[pressIndex].matchStatusArray[0..<(upperBound - pressStartHole + 1)].reduce(0, +)
        let remainingHoles = BetterBallModel.getNumberOfHoles(for: roundViewModel.roundType) - (upperBound - pressStartHole + 1)
        if abs(pressStatus) > remainingHoles {
            let winner = pressStatus > 0 ? "Team A" : "Team B"
            let leadAmount = abs(pressStatus)
            roundViewModel.betterBallPresses[pressIndex].winner = winner
            roundViewModel.betterBallPresses[pressIndex].winningScore = BetterBallModel.formatBetterBallWinningScore("\(leadAmount)&\(remainingHoles)")
            roundViewModel.betterBallPresses[pressIndex].winningHole = upperBound
        } else if upperBound == lastHole && pressStatus != 0 {
            // Handle the case where the press is won on the last hole
            let winner = pressStatus > 0 ? "Team A" : "Team B"
            roundViewModel.betterBallPresses[pressIndex].winner = winner
            roundViewModel.betterBallPresses[pressIndex].winningScore = "1UP"
            roundViewModel.betterBallPresses[pressIndex].winningHole = lastHole
        }
    }
    
    static func updateAllBetterBallPressStatuses(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        let totalHoles = BetterBallModel.getNumberOfHoles(for: roundViewModel.roundType)
        for (index, press) in roundViewModel.betterBallPresses.enumerated() {
            if currentHoleNumber >= press.startHole {
                // Reset this press if it's already been won
                if press.winner != nil {
                    roundViewModel.betterBallPresses[index].matchStatusArray = Array(repeating: 0, count: totalHoles)
                    roundViewModel.betterBallPresses[index].winner = nil
                    roundViewModel.betterBallPresses[index].winningScore = nil
                    roundViewModel.betterBallPresses[index].winningHole = nil
                }
                
                updateBetterBallPressMatchStatus(roundViewModel: roundViewModel, pressIndex: index, for: currentHoleNumber)
                roundViewModel.betterBallPressStatuses[index] = calculateBetterBallPressStatus(roundViewModel: roundViewModel, pressIndex: index, currentHole: currentHoleNumber)
            }
        }
    }
    
    static func calculateBetterBallPressStatus(roundViewModel: RoundViewModel, pressIndex: Int, currentHole: Int) -> String {
        guard pressIndex < roundViewModel.betterBallPresses.count else {
            return "Invalid Press"
        }
        
        let press = roundViewModel.betterBallPresses[pressIndex]
        let startingHole = BetterBallModel.getStartingHole(for: roundViewModel.roundType)
        let lastHole = BetterBallModel.getLastHole(for: roundViewModel.roundType)
        let totalHoles = BetterBallModel.getNumberOfHoles(for: roundViewModel.roundType)
        
        // If this press has already been won, return its final status
        if let winner = press.winner, let winningScore = press.winningScore {
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        }
        
        let pressStartHole = press.startHole
        let lowerBound = max(pressStartHole, startingHole)
        let upperBound = min(currentHole, lastHole)
        let relevantHoles = lowerBound...upperBound
        
        let cumulativePressScore = relevantHoles.reduce(0) { total, hole in
            let index = hole - pressStartHole
            return total + (index >= 0 && index < press.matchStatusArray.count ? press.matchStatusArray[index] : 0)
        }
        
        let holesPlayed = upperBound - lowerBound + 1
        let remainingHoles = totalHoles - holesPlayed
        
        // Check for press win conditions
        if abs(cumulativePressScore) > remainingHoles {
            let winner = cumulativePressScore > 0 ? "Team A" : "Team B"
            let winningScore = BetterBallModel.formatBetterBallWinningScore("\(abs(cumulativePressScore))&\(remainingHoles)")
            roundViewModel.betterBallPresses[pressIndex].winner = winner
            roundViewModel.betterBallPresses[pressIndex].winningScore = winningScore
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        } else if upperBound == lastHole {
            if cumulativePressScore != 0 {
                let winner = cumulativePressScore > 0 ? "Team A" : "Team B"
                let winningScore = "\(abs(cumulativePressScore))UP"
                roundViewModel.betterBallPresses[pressIndex].winner = winner
                roundViewModel.betterBallPresses[pressIndex].winningScore = winningScore
                return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
            } else {
                roundViewModel.betterBallPresses[pressIndex].winner = "Tie"
                roundViewModel.betterBallPresses[pressIndex].winningScore = "All Square"
                return "Press \(pressIndex + 1): Tie - All Square"
            }
        }
        
        // Dormie condition
        if abs(cumulativePressScore) == remainingHoles {
            let leadingTeam = cumulativePressScore > 0 ? "Team A" : "Team B"
            return "Press \(pressIndex + 1): \(leadingTeam) \(abs(cumulativePressScore))UP with \(remainingHoles) to play (Dormie)"
        }
        
        // Regular status
        if cumulativePressScore == 0 {
            return "Press \(pressIndex + 1): All Square thru \(holesPlayed)"
        } else {
            let leadingTeam = cumulativePressScore > 0 ? "Team A" : "Team B"
            return "Press \(pressIndex + 1): \(leadingTeam) \(abs(cumulativePressScore))UP thru \(holesPlayed)"
        }
    }
    
    static func getLosingTeam(roundViewModel: RoundViewModel) -> String? {
        let startingHole = BetterBallModel.getStartingHole(for: roundViewModel.roundType)
        if let lastPress = roundViewModel.betterBallPresses.last {
            // Ensure we're not accessing an index out of bounds
            let relevantIndex = max(0, min(roundViewModel.currentHole - lastPress.startHole, lastPress.matchStatusArray.count - 1))
            let pressScore = lastPress.matchStatusArray[relevantIndex]
            if pressScore > 0 {
                return "Team B"
            } else if pressScore < 0 {
                return "Team A"
            }
        } else {
            // If no presses, check the main match
            let matchScore = roundViewModel.betterBallMatchArray[roundViewModel.currentHole - startingHole] ?? 0
            if matchScore > 0 {
                return "Team B"
            } else if matchScore < 0 {
                return "Team A"
            }
        }
        return nil  // Return nil if it's all square
    }
}