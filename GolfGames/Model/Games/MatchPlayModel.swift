//
//  MatchPlayModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/21/24.
//

import Foundation

struct MatchPlayModel {
    static func updateMatchPlayScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int, scoreInt: Int) {
        let isMatchPlayStrokeHole = roundViewModel.matchPlayStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        let matchPlayNetScore = isMatchPlayStrokeHole ? scoreInt - 1 : scoreInt
        
        roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = matchPlayNetScore
        
        let logMessage = "MatchPlayModel updateMatchPlayScore() - Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.formattedName(golfers: roundViewModel.golfers) ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Match Play Net Score: \(matchPlayNetScore), Match Play Stroke Hole: \(isMatchPlayStrokeHole)"
        
        print(logMessage)
    }
    
    static func resetMatchPlayScore(roundViewModel: RoundViewModel, golferId: String, currentHoleNumber: Int) {
        roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = nil
        roundViewModel.holeWinners[currentHoleNumber] = nil
        roundViewModel.resetTallyForHole(currentHoleNumber)
    }
    
    static func updateMatchPlayTallies(roundViewModel: RoundViewModel, currentHoleNumber: Int) {
        roundViewModel.updateTallies(for: currentHoleNumber)
        roundViewModel.currentPressStartHole = nil  // Reset the current press start hole
    }
}
