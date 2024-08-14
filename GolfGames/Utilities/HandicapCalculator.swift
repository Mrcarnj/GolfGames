//
//  HandicapCalculator.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation

struct HandicapCalculator {
    static func calculateCourseHandicap(handicapIndex: Float, slopeRating: Int, courseRating: Float, par: Int) -> Int {
//        print("Calculating Course Handicap...")
//        print("Handicap Index: \(handicapIndex)")
//        print("Slope Rating: \(slopeRating)")
//        print("Course Rating: \(courseRating)")
//        print("Par: \(par)")
        
        let courseHandicap = (handicapIndex * Float(slopeRating) / 113) + (courseRating - Float(par))
        let roundedHandicap: Int
        
        if courseHandicap.truncatingRemainder(dividingBy: 1) >= 0.5 {
            roundedHandicap = Int(courseHandicap.rounded(.up))
        } else {
            roundedHandicap = Int(courseHandicap.rounded(.down))
        }

//        print("Course Handicap (unrounded): \(courseHandicap)")
//        print("Course Handicap (rounded): \(roundedHandicap)")
        
        return roundedHandicap
    }

    static func determineStrokePlayStrokeHoles(courseHandicap: Int, holes: [Hole]) -> [Int] {
        // Sort holes by their handicap rating
        let sortedHoles = holes.sorted { $0.handicap < $1.handicap }
        
        let absHandicap = abs(courseHandicap)
        let strokeHoles: [Int]
        
        if courseHandicap < 0 {
            // For negative handicaps, take the last 'absHandicap' number of holes (easiest holes)
            strokeHoles = sortedHoles.suffix(absHandicap).map { $0.holeNumber }
        } else {
            // For positive handicaps, take the first 'courseHandicap' number of holes (hardest holes)
            strokeHoles = sortedHoles.prefix(absHandicap).map { $0.holeNumber }
        }
        
        return strokeHoles
    }

    static func determineMatchPlayStrokeHoles(matchPlayHandicap: Int, holes: [Hole]) -> [Int] {
        // Sort holes by their handicap rating
        let sortedHoles = holes.sorted { $0.handicap < $1.handicap }
        
        // Take the first 'matchPlayHandicap' number of holes
        let strokeHoles = sortedHoles.prefix(matchPlayHandicap).map { $0.holeNumber }
        
        return strokeHoles
    }
}