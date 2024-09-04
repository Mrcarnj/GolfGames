//
//  StablefordGrossModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 9/3/24.
//

import Foundation

struct StablefordGrossModel {
    static func initializeStablefordGross(roundViewModel: RoundViewModel, quotas: [String: Int]) {
        print("Debug: StablefordGrossModel - Initializing Stableford Gross")
        
        roundViewModel.isStablefordGross = true
        roundViewModel.stablefordGrossScores = [:]
        roundViewModel.stablefordGrossTotalScores = [:]
        roundViewModel.stablefordGrossQuotas = quotas
        
        print("Stableford Gross initialized for golfers: \(roundViewModel.golfers.map { "\($0.firstName) \($0.lastName) (Quota: \(quotas[$0.id] ?? 0))" })")
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
        
        let sortedResults = roundViewModel.golfers.sorted { golfer1, golfer2 in
            let overQuota1 = (roundViewModel.stablefordGrossTotalScores[golfer1.id] ?? 0) - (roundViewModel.stablefordGrossQuotas[golfer1.id] ?? 0)
            let overQuota2 = (roundViewModel.stablefordGrossTotalScores[golfer2.id] ?? 0) - (roundViewModel.stablefordGrossQuotas[golfer2.id] ?? 0)
            return overQuota1 > overQuota2
        }
        
        var resultString = "Stableford Gross Final Results:\n\n"
        
        for (index, golfer) in sortedResults.enumerated() {
            let position = index + 1
            let positionSuffix = getPositionSuffix(position)
            let totalScore = roundViewModel.stablefordGrossTotalScores[golfer.id] ?? 0
            let quota = roundViewModel.stablefordGrossQuotas[golfer.id] ?? 0
            let pointsOverQuota = totalScore - quota
            resultString += "\(position)\(positionSuffix): \(golfer.firstName) \(golfer.lastName) - \(totalScore) points (\(formatPointsOverQuota(pointsOverQuota)) quota)\n"
        }
        
        if let winner = sortedResults.first {
            let winningScore = roundViewModel.stablefordGrossTotalScores[winner.id] ?? 0
            let winningQuota = roundViewModel.stablefordGrossQuotas[winner.id] ?? 0
            let pointsOverQuota = winningScore - winningQuota
            resultString += "\nWinner: \(winner.firstName) \(winner.lastName) with \(winningScore) points (\(formatPointsOverQuota(pointsOverQuota)) quota)!"
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
}
