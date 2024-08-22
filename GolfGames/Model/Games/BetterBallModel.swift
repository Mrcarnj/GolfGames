//
//  BetterBallModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/19/24.
//

import Foundation

struct BetterBallModel {
    var teams: [[Golfer]]
    var betterBallHandicaps: [String: Int] // Golfer ID to handicap
    var betterBallStrokeHoles: [String: [Int]] // Golfer ID to stroke holes
    var matchStatusArray: [Int] = Array(repeating: 0, count: 18)
    var currentScore: Int = 0 // Positive for team A leading, negative for team B
    
    init(teams: [[Golfer]]) {
        self.teams = teams
        self.betterBallHandicaps = [:]
        self.betterBallStrokeHoles = [:]
    }
    
    mutating func calculateHandicaps() {
        let lowestHandicap = teams.flatMap { $0 }.compactMap { $0.courseHandicap }.min() ?? 0
        for team in teams {
            for golfer in team {
                betterBallHandicaps[golfer.id] = (golfer.courseHandicap ?? 0) - lowestHandicap
            }
        }
        print("Debug: Better Ball Handicaps - \(betterBallHandicaps)")
    }
    
    mutating func calculateStrokeHoles(holes: [Hole]) {
        for (golferId, handicap) in betterBallHandicaps {
            betterBallStrokeHoles[golferId] = HandicapCalculator.determineMatchPlayStrokeHoles(matchPlayHandicap: handicap, holes: holes)
        }
        print("Debug: Better Ball Stroke Holes - \(betterBallStrokeHoles)")
    }
    
    mutating func updateHoleResult(holeNumber: Int, scores: [String: Int]) {
        print("Debug: BetterBallModel - Updating hole result for hole \(holeNumber)")
        print("Debug: BetterBallModel - Scores received: \(scores)")
        
        let teamAScore = teams[0].compactMap { scores[$0.id] }.min() ?? Int.max
        let teamBScore = teams[1].compactMap { scores[$0.id] }.min() ?? Int.max
        
        print("Debug: BetterBallModel - Team A score: \(teamAScore), Team B score: \(teamBScore)")
        
        if teamAScore < teamBScore {
            matchStatusArray[holeNumber - 1] = 1
            currentScore += 1
        } else if teamBScore < teamAScore {
            matchStatusArray[holeNumber - 1] = -1
            currentScore -= 1
        } else {
            matchStatusArray[holeNumber - 1] = 0
        }
        
        print("Debug: BetterBallModel - Updated match status array: \(matchStatusArray)")
        print("Debug: BetterBallModel - Current score: \(currentScore)")
    }
    
    func getMatchStatus() -> (String, Int) {
        if currentScore == 0 {
            return ("All Square", 0)
        } else if currentScore > 0 {
            return ("Team A", currentScore)
        } else {
            return ("Team B", -currentScore)
        }
    }
}