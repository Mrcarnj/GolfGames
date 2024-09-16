//
//  StablefordNetModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 9/13/24.
//

import Foundation

struct StablefordNetModel {
    static func initializeStablefordNet(roundViewModel: RoundViewModel, quotas: [String: Int]) {
        print("Debug: StablefordNetModel - Initializing Stableford Net")
        
        roundViewModel.isStablefordNet = true
        roundViewModel.stablefordNetScores = [:]
        roundViewModel.stablefordNetTotalScores = [:]
        roundViewModel.stablefordNetQuotas = quotas
        
        print("Stableford Net initialized for golfers: \(roundViewModel.golfers.map { "\($0.firstName) \($0.lastName) (Quota: \(quotas[$0.id] ?? 0))" })")
    }
    
    static func updateStablefordNetScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
    }
    
    static func recalculateStablefordNetScores(roundViewModel: RoundViewModel, upToHole: Int) {
        // Reset all scores before recalculating
        roundViewModel.stablefordNetScores = [:]
        roundViewModel.stablefordNetTotalScores = [:]
        
        // Recalculate scores for all holes up to the given hole
        for holeNumber in 1...upToHole {
            calculateAndUpdateScoreForHole(roundViewModel: roundViewModel, holeNumber: holeNumber)
        }
        
        print("Debug: Stableford Net scores recalculated up to hole \(upToHole)")
        print("Debug: Stableford Net total scores: \(roundViewModel.stablefordNetTotalScores)")
    }
    
    private static func calculateAndUpdateScoreForHole(roundViewModel: RoundViewModel, holeNumber: Int) {
        guard let hole = roundViewModel.holes[roundViewModel.selectedTee?.id ?? ""]?.first(where: { $0.holeNumber == holeNumber }) else {
            print("Error: Hole data not found for hole \(holeNumber)")
            return
        }
        
        for golfer in roundViewModel.golfers {
            if let netScore = roundViewModel.netStrokePlayScores[holeNumber]?[golfer.id] {
                let scoreToPar = netScore - hole.par
                let points = pointsForScoreToPar(scoreToPar)
                
                roundViewModel.stablefordNetScores[holeNumber, default: [:]][golfer.id] = points
                roundViewModel.stablefordNetTotalScores[golfer.id, default: 0] += points
            }
        }
        
        print("Debug: Stableford Net scores updated for hole \(holeNumber): \(roundViewModel.stablefordNetScores[holeNumber] ?? [:])")
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
    
    static func resetStablefordNetScore(roundViewModel: RoundViewModel, holeNumber: Int) {
        if let holeScores = roundViewModel.stablefordNetScores[holeNumber] {
            for (golferId, points) in holeScores {
                roundViewModel.stablefordNetTotalScores[golferId, default: 0] -= points
            }
        }
        roundViewModel.stablefordNetScores[holeNumber] = nil
        
        print("Debug: Stableford Net scores reset for hole \(holeNumber)")
        print("Debug: Stableford Net total scores after reset: \(roundViewModel.stablefordNetTotalScores)")
    }
    
    static func displayFinalResults(roundViewModel: RoundViewModel) -> String {
        guard roundViewModel.isStablefordNet else {
            return "Error: Stableford Net is not enabled"
        }
        
        let sortedResults = roundViewModel.golfers.sorted { golfer1, golfer2 in
            let overQuota1 = (roundViewModel.stablefordNetTotalScores[golfer1.id] ?? 0) - (roundViewModel.stablefordNetQuotas[golfer1.id] ?? 0)
            let overQuota2 = (roundViewModel.stablefordNetTotalScores[golfer2.id] ?? 0) - (roundViewModel.stablefordNetQuotas[golfer2.id] ?? 0)
            return overQuota1 > overQuota2
        }
        
        var resultString = "Stableford Net Final Results:\n\n"
        
        for (index, golfer) in sortedResults.enumerated() {
            let position = index + 1
            let positionSuffix = getPositionSuffix(position)
            let totalScore = roundViewModel.stablefordNetTotalScores[golfer.id] ?? 0
            let quota = roundViewModel.stablefordNetQuotas[golfer.id] ?? 0
            let pointsOverQuota = totalScore - quota
            resultString += "\(position)\(positionSuffix): \(golfer.firstName) \(golfer.lastName) - \(totalScore) points (\(formatPointsOverQuota(pointsOverQuota)) quota)\n"
        }
        
        if let winner = sortedResults.first {
            let winningScore = roundViewModel.stablefordNetTotalScores[winner.id] ?? 0
            let winningQuota = roundViewModel.stablefordNetQuotas[winner.id] ?? 0
            let pointsOverQuota = winningScore - winningQuota
            resultString += "\nWinner: \(winner.firstName) \(winner.lastName) with \(winningScore) points (\(formatPointsOverQuota(pointsOverQuota)) quota)!"
        }
        
        print("Debug: Stableford Net final results:\n\(resultString)")
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
