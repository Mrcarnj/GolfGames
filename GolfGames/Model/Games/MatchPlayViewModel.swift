//
//  MatchPlayModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/4/24.
//

import Foundation
import Combine

class MatchPlayViewModel: ObservableObject {
    @Published private(set) var matchPlayGame: MatchPlayGame
    @Published var matchStatus: String = "All Square"

    init(player1Id: String, player2Id: String, matchPlayHandicap: Int) {
        self.matchPlayGame = MatchPlayGame(player1Id: player1Id, player2Id: player2Id, matchPlayHandicap: matchPlayHandicap)
    }

    func updateScore(for hole: Int, player1Score: Int, player2Score: Int, player1HoleHandicap: Int, player2HoleHandicap: Int) {
        let player1NetScore = player1Score - (isStrokeHole(for: matchPlayGame.player1Id, holeHandicap: player1HoleHandicap) ? 1 : 0)
        let player2NetScore = player2Score - (isStrokeHole(for: matchPlayGame.player2Id, holeHandicap: player2HoleHandicap) ? 1 : 0)
        
        matchPlayGame.updateScore(for: hole, player1Score: player1NetScore, player2Score: player2NetScore, player1HoleHandicap: player1HoleHandicap, player2HoleHandicap: player2HoleHandicap)
        print("Debug: MatchPlayViewModel updateScore() - Hole \(hole) updated with scores \(player1NetScore) and \(player2NetScore)")
    }

    func updateMatchStatus() {
        matchStatus = calculateMatchStatus()
        if matchPlayGame.isComplete {
            matchStatus += " (Match Over)"
            print("Debug: MatchPlayViewModel updateMatchStatus()")
        }
    }

    func calculateMatchStatus() -> String {
        let (status, leadAmount) = matchPlayGame.getMatchStatus()
        print("Debug: MatchPlayViewModel - Calculate Status")
        print("Status: \(status), Lead Amount: \(leadAmount)")
        
        if status == "All Square" {
            return "Match is All Square"
        } else {
            return "\(status) is \(leadAmount) UP"
        }
    }

    func isStrokeHole(for playerId: String, holeHandicap: Int) -> Bool {
        return matchPlayGame.isStrokeHole(for: playerId, holeHandicap: holeHandicap)
    }

    func getMatchStatus() -> String {
        print("Debug: MatchPlayViewModel getMatchStatus()")
        return matchStatus
        
    }

    func isMatchComplete() -> Bool {
        print("Debug: MatchPlayViewModel isMatchComplete()")
        return matchPlayGame.isComplete
        
    }

    func getFinalScore() -> String? {
        print("Debug: MatchPlayViewModel getFinalScore()")
        return matchPlayGame.isComplete ? matchPlayGame.finalScore : nil
        
    }

    var player1Score: Int {
        matchPlayGame.player1Score
    }

    var player2Score: Int {
        matchPlayGame.player2Score
        
    }

    var currentHole: Int {
        matchPlayGame.currentHole
    }
}
