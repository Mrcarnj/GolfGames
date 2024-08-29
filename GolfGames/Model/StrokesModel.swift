//
//  StrokesModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/22/24.
//

import Foundation

struct StrokesModel {
    static func getHoleHandicap(roundViewModel: RoundViewModel, for hole: Int, teeId: String) -> Int {
        if let holes = roundViewModel.holes[teeId],
           let holeData = holes.first(where: { $0.holeNumber == hole }) {
            return holeData.handicap
        }
        return 0  // Default value if hole data is not found
    }

    static func calculateStrokePlayStrokeHoles(roundViewModel: RoundViewModel, holes: [Hole]) {
        for golfer in roundViewModel.golfers {
            guard let courseHandicap = roundViewModel.courseHandicaps[golfer.id] else {
                print("Warning: No course handicap found for golfer \(golfer.fullName)")
                continue
            }
            
            let strokeHoles = HandicapCalculator.determineStrokePlayStrokeHoles(courseHandicap: courseHandicap, holes: holes)
            roundViewModel.strokeHoles[golfer.id] = strokeHoles
            
            print("Calculated stroke holes for \(golfer.formattedName(golfers: roundViewModel.golfers)): \(strokeHoles)")
            print("Course Handicap: \(courseHandicap)")
        }
    }

    static func calculateGameStrokeHoles(roundViewModel: RoundViewModel, golfers: [Golfer]) {
    // Get handicaps for all golfers
    let golfersWithHandicaps = golfers.map { golfer -> (Golfer, Int) in
        let handicap = roundViewModel.courseHandicaps[golfer.id] ?? 0
        print("Debug StrokesModel: \(golfer.fullName) - Playing Handicap: \(handicap)")
        return (golfer, handicap)
    }

    // Find the lowest handicap
    guard let lowestHandicap = golfersWithHandicaps.min(by: { $0.1 < $1.1 }) else { return }
    let lowestHandicapPlayer = lowestHandicap.0
    let lowestHandicapValue = lowestHandicap.1

    print("Debug StrokesModel: Lowest Handicap Player: \(lowestHandicapPlayer.fullName) with handicap \(lowestHandicapValue)")

    // Set stroke holes for each player
    for (golfer, handicap) in golfersWithHandicaps {
        let gameHandicap = max(0, handicap - lowestHandicapValue)
        
        if roundViewModel.isMatchPlay {
            calculateMatchPlayStrokeHoles(roundViewModel: roundViewModel, golfer: golfer, gameHandicap: gameHandicap, isLowestHandicap: golfer.id == lowestHandicapPlayer.id)
        } else if roundViewModel.isBetterBall {
            calculateBetterBallStrokeHoles(roundViewModel: roundViewModel, golfer: golfer, gameHandicap: gameHandicap)
        }
    }
}

static func calculateMatchPlayStrokeHoles(roundViewModel: RoundViewModel, golfer: Golfer, gameHandicap: Int, isLowestHandicap: Bool) {
    print("Debug StrokesModel: Match Play Handicap for \(golfer.fullName): \(gameHandicap)")
    
    if isLowestHandicap {
        roundViewModel.matchPlayStrokeHoles[golfer.id] = []
    } else {
        roundViewModel.matchPlayStrokeHoles[golfer.id] = roundViewModel.strokeHoles[golfer.id]?.prefix(gameHandicap).map { $0 } ?? []
    }
    
    print("Debug StrokesModel: Match Play Stroke Holes - \(golfer.fullName): \(roundViewModel.matchPlayStrokeHoles[golfer.id] ?? [])")
}

static func calculateBetterBallStrokeHoles(roundViewModel: RoundViewModel, golfer: Golfer, gameHandicap: Int) {
    print("Debug StrokesModel: Better Ball Handicap for \(golfer.fullName): \(gameHandicap)")
    
    if let strokeHoles = roundViewModel.strokeHoles[golfer.id] {
        roundViewModel.betterBallStrokeHoles[golfer.id] = Array(strokeHoles.prefix(gameHandicap))
    } else {
        print("Warning: No stroke holes found for \(golfer.fullName)")
        roundViewModel.betterBallStrokeHoles[golfer.id] = []
    }
    
    print("Debug StrokesModel: Better Ball Stroke Holes - \(golfer.fullName): \(roundViewModel.betterBallStrokeHoles[golfer.id] ?? [])")
}

static func calculateNinePointStrokeHoles(roundViewModel: RoundViewModel) {
    let golfers = roundViewModel.golfers
    let lowestHandicapPlayer = golfers.min { roundViewModel.courseHandicaps[$0.id] ?? 0 < roundViewModel.courseHandicaps[$1.id] ?? 0 }
    let lowestHandicap = roundViewModel.courseHandicaps[lowestHandicapPlayer?.id ?? ""] ?? 0
    
    for player in golfers {
        let playerHandicap = roundViewModel.courseHandicaps[player.id] ?? 0
        let ninePointHandicap = max(0, playerHandicap - lowestHandicap)
        
        if let playerStrokeHoles = roundViewModel.strokeHoles[player.id] {
            roundViewModel.ninePointStrokeHoles[player.id] = Array(playerStrokeHoles.prefix(ninePointHandicap))
        } else {
            roundViewModel.ninePointStrokeHoles[player.id] = []
        }
        
        print("Debug: Nine Point Stroke Holes for \(player.fullName): \(roundViewModel.ninePointStrokeHoles[player.id] ?? [])")
    }
}
}
