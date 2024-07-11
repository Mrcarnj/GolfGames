//
//  HandicapCalculator.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation

struct HandicapCalculator {
    static func calculateCourseHandicap(handicapIndex: Float, slopeRating: Int, courseRating: Float, par: Int) -> Int {
        print("Calculating Course Handicap...")
        print("Handicap Index: \(handicapIndex)")
        print("Slope Rating: \(slopeRating)")
        print("Course Rating: \(courseRating)")
        print("Par: \(par)")
        
        let courseHandicap = (handicapIndex * Float(slopeRating) / 113) + (courseRating - Float(par))
        let roundedHandicap: Int
        
        if courseHandicap.truncatingRemainder(dividingBy: 1) >= 0.5 {
            roundedHandicap = Int(courseHandicap.rounded(.up))
        } else {
            roundedHandicap = Int(courseHandicap.rounded(.down))
        }

        print("Course Handicap (unrounded): \(courseHandicap)")
        print("Course Handicap (rounded): \(roundedHandicap)")
        
        return roundedHandicap
    }

    static func determineStrokeHoles(courseHandicap: Int, holeHandicaps: [Int]) -> [Int] {
        let sortedHoleHandicaps = holeHandicaps.sorted()
        var strokeHoles: [Int] = []

        for i in 0..<courseHandicap {
            strokeHoles.append(sortedHoleHandicaps[i])
        }

        return strokeHoles
    }
}
