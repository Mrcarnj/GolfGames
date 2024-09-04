//
//  StablefordGrossModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 9/3/24.
//

import Foundation

struct StablefordGrossModel {
    static func initializeStablefordGross(roundViewModel: RoundViewModel) {
        print("Debug: StablefordGrossModel - Initializing Stableford Gross")
        
        roundViewModel.isStablefordGross = true
        roundViewModel.stablefordGrossScores = [:]
        roundViewModel.stablefordGrossTotalScores = [:]
        
        // Calculate quotas for each golfer using the correct course handicaps
        let gameHandicaps = calculateGameHandicaps(for: roundViewModel.golfers)
        for golfer in roundViewModel.golfers {
            let courseHandicap = gameHandicaps[golfer.id] ?? 0
            let quota = 36 - courseHandicap
            roundViewModel.stablefordGrossQuotas[golfer.id] = quota
        }
        
        print("Stableford Gross initialized for golfers: \(roundViewModel.golfers.map { "\($0.firstName) \($0.lastName) (Quota: \(roundViewModel.stablefordGrossQuotas[$0.id] ?? 0))" }) CH: \(gameHandicaps)")
    }
    
    static func updateStablefordGrossScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
    }
    
    static func recalculateStablefordGrossScores(roundViewModel: RoundViewModel, upToHole: Int) {
        // Reset all scores before recalculating
        roundViewModel.stablefordGrossScores = [:]
        roundViewModel.stablefordGrossTotalScores = [:]
        
        // Recalculate scores for all holes up to the given hole
        for holeNumber in 1...upToHole {
            calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
        }
        
        print("Debug: Stableford Gross scores recalculated up to hole \(upToHole)")
        print("Debug: Stableford Gross total scores: \(roundViewModel.stablefordGrossTotalScores)")
    }
    
    private static func calculateAndUpdateScoreForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        guard let hole = roundViewModel.holes[roundViewModel.selectedTee?.id ?? ""]?.first(where: { $0.holeNumber == holeNumber }) else {
            print("Error: Hole data not found for hole \(holeNumber)")
            return
        }
        
        for golfer in roundViewModel.golfers {
            if let grossScore = roundViewModel.grossScores[holeNumber]?[golfer.id] {
                let scoreToPar = grossScore - hole.par
                let points = pointsForScoreToPar(scoreToPar)
                
                roundViewModel.stablefordGrossScores[holeNumber, default: [:]][golfer.id] = points
                roundViewModel.stablefordGrossTotalScores[golfer.id, default: 0] += points
            }
        }
        
        print("Debug: Stableford Gross scores updated for hole \(holeNumber): \(roundViewModel.stablefordGrossScores[holeNumber] ?? [:])")
    }
    
    private static func pointsForScoreToPar(_ scoreToPar: Int) -> Int {
        switch scoreToPar {
        case ...(-3): return 8
        case -2: return 6
        case -1: return 4
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }
    
    static func resetStablefordGrossScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        if let holeScores = roundViewModel.stablefordGrossScores[holeNumber] {
            for (golferId, points) in holeScores {
                roundViewModel.stablefordGrossTotalScores[golferId, default: 0] -= points
            }
        }
        roundViewModel.stablefordGrossScores[holeNumber] = nil
        
        print("Debug: Stableford Gross scores reset for hole \(holeNumber)")
        print("Debug: Stableford Gross total scores after reset: \(roundViewModel.stablefordGrossTotalScores)")
    }
    
    static func displayFinalResults(roundViewModel: RoundViewModel) -> String {
        guard roundViewModel.isStablefordGross else {
            return "Error: Stableford Gross is not enabled"
        }
        
        let sortedResults = roundViewModel.stablefordGrossTotalScores.sorted { $0.value > $1.value }
        
        var resultString = "Stableford Gross Final Results:\n\n"
        
        for (index, result) in sortedResults.enumerated() {
            if let golfer = roundViewModel.golfers.first(where: { $0.id == result.key }) {
                let position = index + 1
                let positionSuffix = getPositionSuffix(position)
                let quota = roundViewModel.stablefordGrossQuotas[golfer.id] ?? 0
                let pointsOverQuota = result.value - quota
                resultString += "\(position)\(positionSuffix): \(golfer.firstName) \(golfer.lastName) - \(result.value) points (\(formatPointsOverQuota(pointsOverQuota)) quota)\n"
            }
        }
        
        if let winner = sortedResults.max(by: { (a, b) in
            let aOverQuota = a.value - (roundViewModel.stablefordGrossQuotas[a.key] ?? 0)
            let bOverQuota = b.value - (roundViewModel.stablefordGrossQuotas[b.key] ?? 0)
            return aOverQuota < bOverQuota
        }) {
            if let winningGolfer = roundViewModel.golfers.first(where: { $0.id == winner.key }) {
                let quota = roundViewModel.stablefordGrossQuotas[winner.key] ?? 0
                let pointsOverQuota = winner.value - quota
                resultString += "\nWinner: \(winningGolfer.firstName) \(winningGolfer.lastName) with \(winner.value) points (\(formatPointsOverQuota(pointsOverQuota)) quota)!"
            }
        }
        
        print("Debug: Stableford Gross final results:\n\(resultString)")
        return resultString
    }
    
    private static func getPositionSuffix(_ position: Int) -> String {
        switch position {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
    
    private static func formatPointsOverQuota(_ points: Int) -> String {
        if points > 0 {
            return "+\(points) over"
        } else if points < 0 {
            return "\(abs(points)) under"
        } else {
            return "met"
        }
    }
    
    private static func calculateGameHandicaps(for golfers: [Golfer]) -> [String: Int] {
        let golfersWithHandicaps = golfers.map { golfer -> (String, Float) in
            let handicap: Float
            if let courseHandicap = golfer.courseHandicap {
                handicap = Float(courseHandicap)
            } else {
                handicap = golfer.handicap
            }
            return (golfer.id, handicap)
        }
        
        var gameHandicaps: [String: Int] = [:]
        
        for (golferId, handicap) in golfersWithHandicaps {
            gameHandicaps[golferId] = Int(round(handicap))
        }
        
        return gameHandicaps
    }
}
