//
//  MatchPlayGame.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/5/24.
//

import Foundation

struct MatchPlayGame: Identifiable, Codable {
    let id: String
    let player1Id: String
    let player2Id: String
    var matchPlayHandicap: Int
    var currentScore: Int // Positive for player1 leading, negative for player2
    var isComplete: Bool
    var finalScore: String?
    var holeResults: [Int: HoleResult] // Store the result of each hole
    var currentHole: Int = 1
    
    struct HoleResult: Codable {
        let winner: String? // "player1", "player2", or nil for halved
        let player1NetScore: Int
        let player2NetScore: Int
    }
    
    init(id: String = UUID().uuidString, player1Id: String, player2Id: String, matchPlayHandicap: Int) {
        self.id = id
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.matchPlayHandicap = matchPlayHandicap
        self.currentScore = 0
        self.isComplete = false
        self.holeResults = [:]
    }
    
    mutating func updateScore(for hole: Int, player1Score: Int, player2Score: Int, player1HoleHandicap: Int, player2HoleHandicap: Int) {
        let player1NetScore = player1Score - (player1HoleHandicap <= matchPlayHandicap ? 1 : 0)
        let player2NetScore = player2Score - (player2HoleHandicap <= -matchPlayHandicap ? 1 : 0)
        
        let winner: String?
        if player1NetScore < player2NetScore {
            winner = "player1"
            currentScore += 1
        } else if player2NetScore < player1NetScore {
            winner = "player2"
            currentScore -= 1
        } else {
            winner = nil // Halved hole
        }
        
        holeResults[hole] = HoleResult(winner: winner, player1NetScore: player1NetScore, player2NetScore: player2NetScore)
        
        currentHole = hole + 1
        checkForWin(hole: hole)
    }
    
    private mutating func checkForWin(hole: Int) {
        let holesRemaining = 18 - hole
        if abs(currentScore) > holesRemaining {
            isComplete = true
            finalScore = "\(abs(currentScore))&\(holesRemaining)"
        }
    }
    
    func isStrokeHole(for playerId: String, holeHandicap: Int) -> Bool {
        if playerId == player1Id {
            return holeHandicap <= matchPlayHandicap
        } else if playerId == player2Id {
            return holeHandicap <= -matchPlayHandicap
        }
        return false
    }
    
    func getMatchStatus() -> (String?, Int) {
        if currentScore > 0 {
            return ("Player 1", currentScore)
        } else if currentScore < 0 {
            return ("Player 2", -currentScore)
        } else {
            return (nil, 0)
        }
    }
    
    var player1Score: Int {
        return max(currentScore, 0)
    }
    
    var player2Score: Int {
        return max(-currentScore, 0)
    }
}