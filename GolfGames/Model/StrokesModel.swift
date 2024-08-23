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
}