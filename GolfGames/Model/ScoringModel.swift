//
//  ScoringModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Score: Identifiable, Codable {
    @DocumentID var id: String?
    var golferId: String
    var holeNumber: Int
    var score: Int
}

struct ScoringModel {
    
    static func updateHoleScores(roundViewModel: RoundViewModel, for golferId: String, score: String, currentHoleNumber: Int) {
        if let scoreInt = Int(score) {
            // Always update gross scores
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = scoreInt
            
            // Always update stroke play scores
            StrokePlayModel.updateStrokePlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: scoreInt)
            
            // Update match play scores only if match play is enabled
            if roundViewModel.isMatchPlay {
                MatchPlayModel.updateMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: scoreInt)
            }
        } else {
            // Reset scores if the input is invalid
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = nil
            roundViewModel.netStrokePlayScores[currentHoleNumber, default: [:]][golferId] = nil
            
            if roundViewModel.isMatchPlay {
                MatchPlayModel.resetMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber)
            }
        }
        
        // Update match play tallies if all scores are entered and match play is enabled
        if roundViewModel.isMatchPlay && roundViewModel.allScoresEntered(for: currentHoleNumber) {
            MatchPlayModel.updateMatchPlayTallies(roundViewModel: roundViewModel, currentHoleNumber: currentHoleNumber)
        }
    }
    
    static func updateScoresForCurrentHole(roundViewModel: RoundViewModel, currentHoleIndex: Int) -> [String: String] {
        let currentHoleNumber = currentHoleIndex + 1
        var scoreInputs = roundViewModel.grossScores[currentHoleNumber]?.mapValues { String($0) } ?? [:]
        
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""
            }
        }
        
        print("ScoringModel updateScoresForCurrentHole() - Updated scores for Hole \(currentHoleNumber): \(scoreInputs)")
        return scoreInputs
    }
    
    static func checkScores(roundViewModel: RoundViewModel) -> [String: [Int]] {
        var missingScores: [String: [Int]] = [:]
    let holeRange = roundViewModel.roundType == .back9 ? 10...18 : 1...(roundViewModel.roundType == .front9 ? 9 : 18)
    for golfer in roundViewModel.golfers {
        missingScores[golfer.id] = holeRange.filter { hole in
            roundViewModel.grossScores[hole]?[golfer.id] == nil
        }
    }
        
        // If there are no missing scores, update the final match status
        if missingScores.values.allSatisfy({ $0.isEmpty }) {
            MatchPlayModel.updateFinalMatchStatus(roundViewModel: roundViewModel)
        }
        
        return missingScores
    }
    
    static func saveScores(roundViewModel: RoundViewModel, scores: [String: Int], currentHole: Int, isMatchPlay: Bool) {
        for (golferId, score) in scores {
            roundViewModel.updateScore(for: currentHole, golferId: golferId, score: score)
        }
        if isMatchPlay {
            let currentHoleNumber = currentHole  // Assuming currentHole is already 1-based
            // Add any match play specific logic here if needed
        }
    }
    
    static func loadScores(roundViewModel: RoundViewModel, currentHole: Int) -> [String: Int] {
        var scores: [String: Int] = [:]
        for golfer in roundViewModel.golfers {
            scores[golfer.id] = roundViewModel.grossScores[currentHole]?[golfer.id] ?? roundViewModel.pars[currentHole] ?? 0
        }
        return scores
    }
    
    static func resetScoresForCurrentHole(roundViewModel: RoundViewModel) {
        for golfer in roundViewModel.golfers {
            let par = roundViewModel.pars[roundViewModel.currentHole] ?? 0
            if let index = roundViewModel.grossScores[roundViewModel.currentHole]?.firstIndex(where: { $0.key == golfer.id }) {
                roundViewModel.grossScores[roundViewModel.currentHole]?[golfer.id] = par
            } else {
                roundViewModel.grossScores[roundViewModel.currentHole, default: [:]][golfer.id] = par
            }
        }
    }
    
    static func nextHole(roundViewModel: RoundViewModel) {
        saveScores(roundViewModel: roundViewModel)
        if roundViewModel.currentHole < 18 {
            roundViewModel.currentHole += 1
            resetScoresForCurrentHole(roundViewModel: roundViewModel)
        }
    }
    
    static func previousHole(roundViewModel: RoundViewModel) {
        saveScores(roundViewModel: roundViewModel)
        if roundViewModel.currentHole > 1 {
            roundViewModel.currentHole -= 1
            resetScoresForCurrentHole(roundViewModel: roundViewModel)
        }
    }
    
    static func updateStrokePlayNetScores(roundViewModel: RoundViewModel) {
        for (holeNumber, scores) in roundViewModel.grossScores {
            for (golferId, grossScore) in scores {
                guard let courseHandicap = roundViewModel.courseHandicaps[golferId] else {
                    print("Warning: No course handicap found for golfer \(golferId)")
                    continue
                }
                
                let isStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(holeNumber) ?? false
                let netScore: Int
                
                if courseHandicap < 0 {
                    netScore = isStrokeHole ? grossScore + 1 : grossScore
                } else {
                    netScore = isStrokeHole ? grossScore - 1 : grossScore
                }
                
                roundViewModel.netStrokePlayScores[holeNumber, default: [:]][golferId] = netScore
                
                print("Hole \(holeNumber) for golfer \(golferId): Gross \(grossScore), Net \(netScore), Stroke Hole: \(isStrokeHole), Course Handicap: \(courseHandicap)")
            }
        }
    }
    
    static func saveScores(roundViewModel: RoundViewModel) {
        guard let roundId = roundViewModel.roundId else { return }
        
        let db = Firestore.firestore()
        let grossScoresData = roundViewModel.grossScores.mapValues { $0.mapValues { $0 } }
        let netScoresData = roundViewModel.netStrokePlayScores.mapValues { $0.mapValues { $0 } }
        
        db.collection("users").document("user_id").collection("rounds").document(roundId).setData(["gross_scores": grossScoresData, "net_scores": netScoresData], merge: true) { error in
            if let error = error {
                print("Error saving scores: \(error.localizedDescription)")
            } else {
                print("Scores saved successfully: \(roundViewModel.grossScores)")
            }
        }
    }
    
    static func getMissingScores(roundViewModel: RoundViewModel, for golferId: String) -> [Int] {
        return (1...18).filter { holeNumber in
            roundViewModel.grossScores[holeNumber]?[golferId] == nil
        }
    }
    
    static func allScoresEntered(roundViewModel: RoundViewModel, for holeNumber: Int? = nil) -> Bool {
        if let hole = holeNumber {
            // Check for a specific hole
            return roundViewModel.golfers.allSatisfy { golfer in
                roundViewModel.grossScores[hole]?[golfer.id] != nil
            }
        } else {
            // Check all holes
            return (1...18).allSatisfy { hole in
                roundViewModel.golfers.allSatisfy { golfer in
                    roundViewModel.grossScores[hole]?[golfer.id] != nil
                }
            }
        }
    }
    
    static func updateScore(roundViewModel: RoundViewModel, for hole: Int, golferId: String, score: Int) {
        roundViewModel.grossScores[hole, default: [:]][golferId] = score
        roundViewModel.updateStrokePlayNetScores()
        
        if roundViewModel.isMatchPlay {
            MatchPlayModel.updateMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: hole, scoreInt: score)
            // Recalculate match status for all holes from the changed hole onward
            for currentHole in hole...18 {
                MatchPlayModel.updateMatchStatus(roundViewModel: roundViewModel, for: currentHole)
            }
        }
    }
}
