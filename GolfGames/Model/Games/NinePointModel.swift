//
//  NinePointModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/28/24.
//

import Foundation

struct NinePointModel {
    static func initializeNinePoint(roundViewModel: RoundViewModel) {
        print("Debug: NinePointModel - Initializing Nine Point")
        
        // Ensure there are exactly 3 golfers
        guard roundViewModel.golfers.count == 3 else {
            print("Error: Nine Point requires exactly 3 players")
            return
        }
        
        // Set isNinePoint to true
        roundViewModel.isNinePoint = true
        
        roundViewModel.ninePointScores = [:]
        roundViewModel.ninePointTotalScores = [:]
        
        print("Nine Point initialized for golfers: \(roundViewModel.golfers.map { "\($0.firstName) \($0.lastName)" })")
    }
    
    static func updateNinePointScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
        // Remove this line as we'll recalculate in HoleView
        // recalculateNinePointScores(roundViewModel: roundViewModel, upToHole: holeNumber)
    }
    
    static func recalculateNinePointScores(roundViewModel: RoundViewModel, upToHole: Int) {
        // Reset all scores before recalculating
        roundViewModel.ninePointScores = [:]
        roundViewModel.ninePointTotalScores = [:]
        
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles: Int
        switch roundViewModel.roundType {
        case .full18:
            totalHoles = 18
        case .front9, .back9:
            totalHoles = 9
        }
        
        // Recalculate scores for all holes up to and including the given hole, considering wrap-around
        for offset in 0..<totalHoles {
            let holeNumber = ((startingHole + offset - 1) % 18) + 1
            calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
            if holeNumber == upToHole {
                break
            }
        }
        
        print("Debug: Nine Point scores recalculated up to hole \(upToHole)")
        print("Debug: Nine Point total scores: \(roundViewModel.ninePointTotalScores)")
    }
    
    private static func calculateAndUpdateScoreForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        let golfers = roundViewModel.golfers
        var netScores: [(golferId: String, netScore: Int)] = []
        
        for golfer in golfers {
            if let grossScore = roundViewModel.grossScores[holeNumber]?[golfer.id] {
                let isStrokeHole = roundViewModel.ninePointStrokeHoles[golfer.id]?.contains(holeNumber) ?? false
                let netScore = isStrokeHole ? grossScore - 1 : grossScore
                netScores.append((golfer.id, netScore))
            }
        }
        
        // Only proceed if we have scores for all three players
        guard netScores.count == 3 else {
            print("Debug: Not all scores entered for hole \(holeNumber), skipping Nine Point calculation")
            return
        }
        
        // Calculate points for this hole
        let points = calculatePointsForHole(netScores: netScores)
        
        // Update scores for the hole
        roundViewModel.ninePointScores[holeNumber] = points
        
        // Update total scores
        for (golferId, holePoints) in points {
            roundViewModel.ninePointTotalScores[golferId, default: 0] += holePoints
        }
        
        print("Debug: Nine Point scores updated for hole \(holeNumber): \(points)")
    }
    
    private static func calculatePointsForHole(netScores: [(golferId: String, netScore: Int)]) -> [String: Int] {
        let sortedScores = netScores.sorted { $0.netScore < $1.netScore }
        var points: [String: Int] = [:]
        
        if sortedScores[0].netScore == sortedScores[1].netScore && sortedScores[1].netScore == sortedScores[2].netScore {
            // All scores are the same
            points = [sortedScores[0].golferId: 3, sortedScores[1].golferId: 3, sortedScores[2].golferId: 3]
        } else if sortedScores[0].netScore == sortedScores[1].netScore {
            // Two low scores tie
            points = [sortedScores[0].golferId: 4, sortedScores[1].golferId: 4, sortedScores[2].golferId: 1]
        } else if sortedScores[1].netScore == sortedScores[2].netScore {
            // Two high scores tie
            points = [sortedScores[0].golferId: 5, sortedScores[1].golferId: 2, sortedScores[2].golferId: 2]
        } else {
            // All scores are different
            points = [sortedScores[0].golferId: 5, sortedScores[1].golferId: 3, sortedScores[2].golferId: 1]
        }
        
        return points
    }
    
    static func resetNinePointScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        if let holeScores = roundViewModel.ninePointScores[holeNumber] {
            for (golferId, points) in holeScores {
                roundViewModel.ninePointTotalScores[golferId, default: 0] -= points
            }
        }
        roundViewModel.ninePointScores[holeNumber] = nil
        
        print("Debug: Nine Point scores reset for hole \(holeNumber)")
        print("Debug: Nine Point total scores after reset: \(roundViewModel.ninePointTotalScores)")
    }
    
    static func displayFinalResults(roundViewModel: RoundViewModel) -> String {
        guard roundViewModel.isNinePoint else {
            return "Error: Nine Point is not enabled"
        }
        
        let sortedResults = roundViewModel.ninePointTotalScores.sorted { $0.value > $1.value }
        
        var resultString = "Nine Point Final Results:\n\n"
        
        for (index, result) in sortedResults.enumerated() {
            if let golfer = roundViewModel.golfers.first(where: { $0.id == result.key }) {
                let position = index + 1
                let positionSuffix = getPositionSuffix(position)
                resultString += "\(position)\(positionSuffix): \(golfer.firstName) \(golfer.lastName) - \(result.value) points\n"
            }
        }
        
        if let winner = sortedResults.first {
            if let winningGolfer = roundViewModel.golfers.first(where: { $0.id == winner.key }) {
                resultString += "\nWinner: \(winningGolfer.firstName) \(winningGolfer.lastName) with \(winner.value) points!"
            }
        }
        
        print("Debug: Nine Point final results:\n\(resultString)")
        return resultString
    }
    
    private static func getPositionSuffix(_ position: Int) -> String {
        switch position {
        case 1:
            return "st"
        case 2:
            return "nd"
        case 3:
            return "rd"
        default:
            return "th"
        }
    }
}
