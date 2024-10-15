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
        for holeNumber in 1...max(1, upToHole) {
            if let grossScore = roundViewModel.grossScores[holeNumber]?[golferId],
               let hole = singleRoundViewModel.holes.first(where: { $0.holeNumber == holeNumber }) {
                cumulativeScoreToPar += grossScore - hole.par
            }
        }
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
