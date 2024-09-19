//
//  StrokePlayModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/21/24.
//

import Foundation

struct StrokePlayModel {
    static func updateStrokePlayScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        roundViewModel.updateStrokePlayNetScores()
        
        let netStrokePlayScore = roundViewModel.netStrokePlayScores[currentHoleNumber]?[golferId] ?? scoreInt
        let isStrokePlayStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        
        let logMessage = "StrokePlayModel updateStrokePlayScore() - Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.formattedName(golfers: roundViewModel.golfers) ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Stroke Play Net Score: \(netStrokePlayScore), Stroke Play Stroke Hole: \(isStrokePlayStrokeHole)"
        
        print(logMessage)
    }

    static func calculateCumulativeScoreToPar(roundViewModel: RoundViewModel, singleRoundViewModel: SingleRoundViewModel, golferId: String, upToHole: Int) -> Int {
        var cumulativeScoreToPar = 0
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        print("Debug: Calculating cumulative score to par - Starting Hole: \(startingHole), Up To Hole: \(upToHole), Total Holes: \(totalHoles)")
        
        var currentHole = startingHole
        var holesProcessed = 0
        
        while holesProcessed < totalHoles {
            if let grossScore = roundViewModel.grossScores[currentHole]?[golferId],
               let hole = singleRoundViewModel.holes.first(where: { $0.holeNumber == currentHole }) {
                let holeScoretoPar = grossScore - hole.par
                cumulativeScoreToPar += holeScoretoPar
                print("Debug: Hole \(currentHole) - Gross Score: \(grossScore), Par: \(hole.par), Score to Par: \(holeScoretoPar), Cumulative: \(cumulativeScoreToPar)")
            } else {
                print("Debug: Hole \(currentHole) - No score or hole data available")
            }
            
            if currentHole == upToHole {
                break
            }
            
            holesProcessed += 1
            
            switch roundViewModel.roundType {
            case .full18:
                currentHole = currentHole % 18 + 1
            case .front9:
                currentHole = (currentHole % 9) + 1
                if currentHole > 9 { currentHole = 1 }
            case .back9:
                currentHole = (currentHole - 9) % 9 + 10
                if currentHole > 18 { currentHole = 10 }
            }
        }
        
        print("Debug: Final Cumulative Score to Par: \(cumulativeScoreToPar)")
        return cumulativeScoreToPar
    }

    static func formatScoreToPar(_ scoreToPar: Int) -> String {
        if scoreToPar == 0 {
            return "E"
        } else if scoreToPar > 0 {
            return "+\(scoreToPar)"
        } else {
            return "\(scoreToPar)"
        }
    }
}
