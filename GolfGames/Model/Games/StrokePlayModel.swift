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
}
