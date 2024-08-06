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
        
        // Take the first 'courseHandicap' number of holes
        let strokeHoles = sortedHoles.prefix(courseHandicap).map { $0.holeNumber }
        
//        print("Determined stroke holes: \(strokeHoles) for course handicap: \(courseHandicap)")
//        print("Holes with their handicaps:")
//        for hole in sortedHoles {
//            print("Hole \(hole.holeNumber): Handicap \(hole.handicap)")
//        }
        
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