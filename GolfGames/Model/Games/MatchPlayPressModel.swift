//
//  MatchPlayPressModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/22/24.
//

import Foundation

struct MatchPlayPressModel {
    
    static func initiatePress(roundViewModel: RoundViewModel, atHole: Int) {
        if roundViewModel.presses.isEmpty && roundViewModel.matchWinner != nil {
            print("Cannot initiate new press: main match has been won and no existing presses")
            return
        }
        
        print("Initiating press at hole \(atHole)")
        print("Current hole: \(roundViewModel.currentHole)")
        print("Number of presses before adding: \(roundViewModel.presses.count)")
        
        let numberOfHoles = MatchPlayModel.getNumberOfHoles(for: roundViewModel.roundType)
        roundViewModel.presses.append((startHole: atHole, matchStatusArray: Array(repeating: 0, count: numberOfHoles), winner: nil, winningScore: nil, winningHole: nil))
        roundViewModel.pressStatuses.append("Press \(roundViewModel.presses.count): All Square thru 0")
        roundViewModel.currentPressStartHole = atHole
        
        print("Number of presses after adding: \(roundViewModel.presses.count)")
        print("Number of press statuses: \(roundViewModel.pressStatuses.count)")
        print("Current presses: \(roundViewModel.presses)")
        print("Current press statuses: \(roundViewModel.pressStatuses)")
        
        roundViewModel.objectWillChange.send()
    }
    
    static func getCurrentPressStatus(roundViewModel: RoundViewModel) -> (leadingPlayer: Golfer?, trailingPlayer: Golfer?, score: Int)? {
        guard let (golfer1, golfer2) = roundViewModel.matchPlayGolfers else { return nil }
        
        if let lastPress = roundViewModel.presses.last {
            let pressStartHole = lastPress.startHole
            let lowerBound = max(pressStartHole, 1)
            let upperBound = max(roundViewModel.currentHole, lowerBound)
            let relevantHoles = lowerBound...upperBound
            
            print("Press start hole: \(pressStartHole)")
            print("Current hole: \(roundViewModel.currentHole)")
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
            if roundViewModel.matchScore > 0 {
                return (golfer1, golfer2, roundViewModel.matchScore)
            } else if roundViewModel.matchScore < 0 {
                return (golfer2, golfer1, -roundViewModel.matchScore)
            } else {
                return (nil, nil, 0)  // All square
            }
        }
    }
    
    static func updatePressMatchStatus(roundViewModel: RoundViewModel, pressIndex: Int, for currentHoleNumber: Int) {
        guard let (golfer1, golfer2) = roundViewModel.matchPlayGolfers else { return }
        
        let press = roundViewModel.presses[pressIndex]
        
        // If the press already has a winner, don't update it
        if press.winner != nil {
            return
        }
        
        let startingHole = MatchPlayModel.getStartingHole(for: roundViewModel.roundType)
        let pressStartHole = press.startHole
        let lastHole = MatchPlayModel.getLastHole(for: roundViewModel.roundType)
        
        // Ensure we don't go beyond the last hole or before the press start hole
        let endHole = min(currentHoleNumber, lastHole)
        for hole in pressStartHole...endHole {
            if let winner = roundViewModel.holeWinners[hole] {
                let index = hole - pressStartHole
                if index >= 0 && index < press.matchStatusArray.count {
                    if winner == golfer1.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.presses[pressIndex].matchStatusArray[index] = 1
                    } else if winner == golfer2.formattedName(golfers: roundViewModel.golfers) {
                        roundViewModel.presses[pressIndex].matchStatusArray[index] = -1
                    } else {
                        roundViewModel.presses[pressIndex].matchStatusArray[index] = 0
                    }
                }
            }
        }
        
        let totalHoles = MatchPlayModel.getNumberOfHoles(for: roundViewModel.roundType)
        
        // Check if the press has been won
        let pressStatus = roundViewModel.presses[pressIndex].matchStatusArray.reduce(0, +)
        let holesPlayed = min(currentHoleNumber - pressStartHole + 1, totalHoles)
        let remainingHoles = totalHoles - holesPlayed
        
        if abs(pressStatus) > remainingHoles {
            let winner = pressStatus > 0 ? golfer1.formattedName(golfers: roundViewModel.golfers) : golfer2.formattedName(golfers: roundViewModel.golfers)
            let leadAmount = abs(pressStatus)
            roundViewModel.presses[pressIndex].winner = winner
            roundViewModel.presses[pressIndex].winningScore = MatchPlayModel.formatWinningScore("\(leadAmount)&\(remainingHoles)")
            roundViewModel.presses[pressIndex].winningHole = currentHoleNumber
        } else if currentHoleNumber == lastHole && pressStatus != 0 {
            // Handle the case where the press is won on the last hole
            let winner = pressStatus > 0 ? golfer1.formattedName(golfers: roundViewModel.golfers) : golfer2.formattedName(golfers: roundViewModel.golfers)
            roundViewModel.presses[pressIndex].winner = winner
            roundViewModel.presses[pressIndex].winningScore = "1UP"
            roundViewModel.presses[pressIndex].winningHole = lastHole
        }
    }
    
    static func updateAllPressStatuses(roundViewModel: RoundViewModel, for currentHoleNumber: Int) {
        for (index, press) in roundViewModel.presses.enumerated() {
            if currentHoleNumber >= press.startHole {
                updatePressMatchStatus(roundViewModel: roundViewModel, pressIndex: index, for: currentHoleNumber)
                roundViewModel.pressStatuses[index] = calculatePressStatus(roundViewModel: roundViewModel, pressIndex: index, currentHole: currentHoleNumber)
            }
        }
    }
    
    static func calculatePressStatus(roundViewModel: RoundViewModel, pressIndex: Int, currentHole: Int) -> String {
        guard pressIndex < roundViewModel.presses.count, let (player1, player2) = roundViewModel.matchPlayGolfers else {
            return "Invalid Press"
        }
        
        let press = roundViewModel.presses[pressIndex]
        
        // If this press has already been won, return its final status
        if let winner = press.winner, let winningScore = press.winningScore {
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        }
        
        let startingHole = MatchPlayModel.getStartingHole(for: roundViewModel.roundType)
        let pressStartHole = press.startHole
        let lastHole = MatchPlayModel.getLastHole(for: roundViewModel.roundType)
        let relevantHoles = pressStartHole...min(currentHole, lastHole)
        
        let cumulativePressScore = relevantHoles.reduce(0) { total, hole in
            let index = hole - pressStartHole
            return total + (index >= 0 && index < press.matchStatusArray.count ? press.matchStatusArray[index] : 0)
        }
        
        let holesPlayed = min(currentHole - pressStartHole + 1, MatchPlayModel.getNumberOfHoles(for: roundViewModel.roundType))
        let remainingHoles = MatchPlayModel.getNumberOfHoles(for: roundViewModel.roundType) - holesPlayed
        
        // Check for press win conditions
        if abs(cumulativePressScore) > remainingHoles {
            let winner = cumulativePressScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
            let winningScore = MatchPlayModel.formatWinningScore("\(abs(cumulativePressScore))&\(remainingHoles)")
            roundViewModel.presses[pressIndex].winner = winner
            roundViewModel.presses[pressIndex].winningScore = winningScore
            return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
        } else if currentHole == lastHole {
            if cumulativePressScore != 0 {
                let winner = cumulativePressScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
                let winningScore = "\(abs(cumulativePressScore))UP"
                roundViewModel.presses[pressIndex].winner = winner
                roundViewModel.presses[pressIndex].winningScore = winningScore
                return "Press \(pressIndex + 1): \(winner) won \(winningScore)"
            } else {
                roundViewModel.presses[pressIndex].winner = "Tie"
                roundViewModel.presses[pressIndex].winningScore = "All Square"
                return "Press \(pressIndex + 1): Tie - All Square"
            }
        }
        
        // Dormie condition
        if abs(cumulativePressScore) == remainingHoles {
            let leadingPlayer = cumulativePressScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
            return "Press \(pressIndex + 1): \(leadingPlayer) \(abs(cumulativePressScore))UP with \(remainingHoles) to play (Dormie)"
        }
        
        // Regular status
        if cumulativePressScore == 0 {
            return "Press \(pressIndex + 1): All Square thru \(holesPlayed)"
        } else {
            let leadingPlayer = cumulativePressScore > 0 ? player1.formattedName(golfers: roundViewModel.golfers) : player2.formattedName(golfers: roundViewModel.golfers)
            return "Press \(pressIndex + 1): \(leadingPlayer) \(abs(cumulativePressScore))UP thru \(holesPlayed)"
        }
    }
    
    static func getLosingPlayer(roundViewModel: RoundViewModel) -> Golfer? {
        guard let (golfer1, golfer2) = roundViewModel.matchPlayGolfers else { return nil }
        
        if let lastPress = roundViewModel.presses.last {
            let startingHole = MatchPlayModel.getStartingHole(for: roundViewModel.roundType)
            let relevantIndex = max(0, min(roundViewModel.currentHole - lastPress.startHole, lastPress.matchStatusArray.count - 1))
            let pressScore = lastPress.matchStatusArray[relevantIndex]
            if pressScore > 0 {
                return golfer2
            } else if pressScore < 0 {
                return golfer1
            }
        } else {
            // If no presses, check the main match
            if roundViewModel.matchScore > 0 {
                return golfer2
            } else if roundViewModel.matchScore < 0 {
                return golfer1
            }
        }
        return nil  // Return nil if it's all square
    }
}
