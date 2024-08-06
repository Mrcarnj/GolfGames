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
        matchPlayGame.updateScore(for: hole, player1Score: player1Score, player2Score: player2Score, player1HoleHandicap: player1HoleHandicap, player2HoleHandicap: player2HoleHandicap)
        updateMatchStatus()
    }

    func updateMatchStatus() {
        let (leadingPlayer, leadAmount) = matchPlayGame.getMatchStatus()
        if let leadingPlayer = leadingPlayer {
            matchStatus = "\(leadingPlayer) \(leadAmount) UP"
        } else {
            matchStatus = "All Square"
        }

        if matchPlayGame.isComplete {
            matchStatus += " (Match Over)"
        }
    }

    func isStrokeHole(for playerId: String, holeHandicap: Int) -> Bool {
        return matchPlayGame.isStrokeHole(for: playerId, holeHandicap: holeHandicap)
    }

    func getMatchStatus() -> String {
        return matchStatus
    }

    func isMatchComplete() -> Bool {
        return matchPlayGame.isComplete
    }

    func getFinalScore() -> String? {
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