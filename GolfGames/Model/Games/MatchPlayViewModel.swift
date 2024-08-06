//
//  MatchPlayModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/4/24.
//

import Foundation
import Combine

class MatchPlayViewModel: ObservableObject {
    @Published var matchPlayGame: MatchPlayGame
    @Published var matchStatus: String = "Match is All Square"
    private var holeResults: [Int: (Int, Int)] = [:]
    private var currentLeadingPlayer: String?
    private var leadAmount: Int = 0

    private var cancellables: Set<AnyCancellable> = []

    private let player1Id: String
    private let player2Id: String

    init(player1Id: String, player2Id: String, matchPlayHandicap: Int) {
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.matchPlayGame = MatchPlayGame(player1Id: player1Id, player2Id: player2Id, matchPlayHandicap: matchPlayHandicap)
    }

    func updateScore(for hole: Int, player1Score: Int, player2Score: Int, player1HoleHandicap: Int, player2HoleHandicap: Int) {
        let player1NetScore = player1Score - (isStrokeHole(for: player1Id, holeHandicap: player1HoleHandicap) ? 1 : 0)
        let player2NetScore = player2Score - (isStrokeHole(for: player2Id, holeHandicap: player2HoleHandicap) ? 1 : 0)
        
        holeResults[hole] = (player1NetScore, player2NetScore)
    }

    func isStrokeHole(for playerId: String, holeHandicap: Int) -> Bool {
        // Assuming player2 is the higher handicap player and gets strokes
        return playerId == player2Id && holeHandicap <= matchPlayGame.matchPlayHandicap
    }

    func updateMatchStatus(for newHole: Int) {
        var player1Wins = 0
        var player2Wins = 0

        for hole in 1..<newHole {
            if let result = holeResults[hole] {
                if result.0 < result.1 {
                    player1Wins += 1
                } else if result.1 < result.0 {
                    player2Wins += 1
                }
            }
        }

        let difference = player1Wins - player2Wins
        if difference > 0 {
            currentLeadingPlayer = "Player 1"
            leadAmount = difference
            matchStatus = "Player 1 is \(difference) Up"
        } else if difference < 0 {
            currentLeadingPlayer = "Player 2"
            leadAmount = -difference
            matchStatus = "Player 2 is \(-difference) Up"
        } else {
            currentLeadingPlayer = nil
            leadAmount = 0
            matchStatus = "Match is All Square"
        }
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
}